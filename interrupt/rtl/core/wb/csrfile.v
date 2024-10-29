`include "defines.v"
module csrfile(
    input wire clk_in,
    input wire reset_in,
    //input irq_,
    
    //exe read register
    input wire [`CSR_ADDR_WIDTH-1:0] raddr_in,
    output reg [`RDATA_WIDTH-1:0] rdata_out,
    
    //wb update the csr register file
    input wire [`CSR_ADDR_WIDTH-1:0] waddr_in,
    input wire [`RDATA_WIDTH-1:0] wdata_in,
    input wire we_in,
    input wire instret_incr_in,
    
    //interrupt signal from clint or plic
    input wire interrupt_require_timer_in,
    input wire interrupt_require_software_in,
    input wire interrupt_require_external_in,

    //from interrupt_ctrl  
    input wire interrupt_type_in,
    input wire cause_we_in,
    input wire [3:0] trap_cause_in,
    input wire epc_we_in,
    input wire [`ADDR_WIDTH-1:0]epc_in,
    input wire mstatus_ie_clear_in,
    input wire mstatus_ie_set_in,

    //to interrupt_ctrl
    output reg mstatus_mie_out,
    output reg mip_mtip_out,
    output reg mip_msip_out,
    output reg mip_meip_out,
    output reg mie_mtie_out,
    output reg mie_msie_out,
    output reg mie_meie_out,
    output reg [`DATA_WIDTH-1:0] mtvec_out,
    output reg [`ADDR_WIDTH-1:0] epc_out


);
// `define：作用 常用於定義常數變量，好處是可以跨module，跨文件
// parameter：常用於module間的參數傳遞，example==> 可以跨module 像是dpram在寫的時候
//            範圍：本mdoule之間
// localparam：指的是local parameter用於FSM的參數傳遞定義
//            範圍：本moduled，不可以傳遞參數

// mvendorid
localparam CSR_MVENDORID_VALUE = 32'b0;
// marchid  {1'b0, 31'd22}
localparam CSR_MARCHID_VALUE = 32'b0;
// mimpid
localparam CSR_MIMPID_VALUE = 32'b0;
// mhartid
localparam CSR_MHARTID_VALUE = 32'b0;

/*----------------mstatus----------------*/
//{SD(1), WPRI(8), TSR(1), TW(1), TVM(1), MXR(1), SUM(1), MPRV(1), XS(2),
//  FS(2), MPP(2), WPRI(2), SPP(1), MPIE(1), WPRI(1), SPIE(1), UPIE(1),MIE(1), WPRI(1), SIE(1), UIE(1)}
reg [`RDATA_WIDTH-1:0] mstatus;

reg mstatus_mpie;//privious interrupt enable
reg mstatus_mie; //interrupt enable
reg [1:0] mstatus_mpp; //privious privlige mode (u:00,s:01,m:11)

assign mstatus_mpp = 2'b11;
assign mstatus_mie_out = mstatus_mie;
assign mstatus = {19'b0 , mstatus_mpp, 3'b0 , mstatus_mpie, 3'b0, mstatus_mie, 3'b0};

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mstatus_mie <= 1'b0;
        mstatus_mpie <= 1'b1;
    end else if(((waddr_in == `CSR_MSTATUS_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mstatus_mie <= wdata_in[3];
        mstatus_mpie <= wdata_in[7];
    end else if (mstatus_ie_clear_in) begin
        mstatus_mpie <= mstatus_mie;
        mstatus_mie <= 1'b0;
    end else if (mstatus_ie_set_in) begin
        mstatus_mie <= mstatus_mpie;
        mstatus_mpie <= 1'b1;
    end else begin
        mstatus_mie <= mstatus_mie;
        mstatus_mpie <= mstatus_mpie;
    end
end

/*----------------misa----------------*/
// The misa CSR is a 寫任何值 and 讀取合法值 read-write register reporting the ISA supported by the hart. This
// register must be readable in any implementation, but a value of zero can be returned to indicate
// the misa register has not been implemented
// 告訴此機器透過machine XLEN去決定是32/64/128 bit
wire [1:0] mxl; // machine XLEN
wire [25:0] mextensions; // ISA extensions
wire [`RDATA_WIDTH-1:0] misa;
assign mxl = 2'b01; // 32bit
assign mextensions = 26'b00000000000001000100000000;  // i and m 每個bit控制不同的字母也就是我們需要的功能
assign misa = {mxl,4'b0,mextensions};

/*----------------mcycle----------------*/ //64bit
// counts the number of clock cycles executed by the processor core on which the hart is running. 
// 64-bit precision on all RV32 and RV64 systems.
reg[`RDATA_WIDTH*2-1:0] mcycle;

/*----------------minstret----------------*/ //64bit
// machine instruction retire counter
reg[`RDATA_WIDTH*2-1:0] minstret;

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mcycle <= {32'b0 , 32'b0};
        minstret <= {32'b0 , 32'b0};
    end else begin
        mcycle <= mcycle + 64'b1; // c = c + 1
        if(instret_incr_in) begin
            minstret <= minstret + 64'b1;
        end else begin
            minstret <= minstret;
        end
    end
end

/*-------------------mie-------------------*/
// 按照 mcause 的 exception code 編碼 n 對應的 mie[n] 來表示該 interrupt 的 enable
// mie: {WPRI[31:12], MEIE(1), WPRI(1), SEIE(1), UEIE(1), 
// MTIE(1), WPRI(1), STIE(1), UTIE(1), 
// MSIE(1), WPRI(1), SSIE(1), USIE(1)}
reg [`RDATA_WIDTH-1:0] mie;
reg mie_meie;
reg mie_mtie;
reg mie_msie;

assign mie_meie_out = mie_meie;
assign mie_mtie_out = mie_mtie;
assign mie_msie_out = mie_msie;

assign mie = {20'b0, mie_meie, 3'b0, mie_mtie, 3'b0, mie_msie, 3'b0};

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mie_meie <= 1'b0;
        mie_mtie <= 1'b0;
        mie_msie <= 1'b0;
    end else if(((waddr_in == `CSR_MIE_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mie_meie <= wdata_in[11];
        mie_mtie <= wdata_in[7];
        mie_msie <= wdata_in[3];
    end else begin
        mie_meie <= mie_meie;
        mie_mtie <= mie_mtie;
        mie_msie <= mie_msie;
    end
end

/*-----------------mtvec------------------*/
// 用於保存中斷向量的位址
// 當發生 interrupt 或是 exception 時，PC 會根據該 CSR 所指向的地址(中斷例外處理程序的entry)繼續執行
// Base Addr:trap發生時指定跳轉PC Addr,對齊 4-byte 記憶體位址。
// 兩種模式的區別在於決定入口地址的方式不同vector mode中。選擇使用哪種模式取決於具體的應用。
// Mode:
// 0 表示 direct mode,入口地址固定, 當 trap 發生時將 pc 設為 BASE
// 1 表示 vectored mode,入口地址根據中斷原因動態決定:
// exception 發生時將 pc 設為 BASE
// Asynchronous interrupts 發生時將 pc 設為 BASE + 4 * cause
// 例如計時器 interrupt 的 cause 編號為 7, 所以 pc 會設為 BASE + 0x1c 的位址
// {MXLEN-1:2 (base) 2:1(mode)}
reg [`RDATA_WIDTH-1:0] mtvec;

assign mtvec_out = mtvec;

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mtvec <= `ZERO;
    end else if(((waddr_in == `CSR_MTVEC_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mtvec <= wdata_in;
    end else begin
        mtvec <= mtvec;
    end
end

/*-----------------mscratch-----------------*/
// 通常用於保存context的指針，並在進入 m mode trap handler時
// 與user 暫存器交換
reg [`RDATA_WIDTH-1:0] mscratch;

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mscratch <= `ZERO;
    end else if(((waddr_in == `CSR_MSCRATCH_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mscratch <= wdata_in;
    end else begin
        mscratch <= mscratch;
    end
end

/*-------------------mepc-------------------*/
// 由硬體在interrupt/exception發生時的當下將pc寫到該CSR，在mret指令執行時
// 將mepc寫回pc來回到trap發生之前的位置。
// interrupt==> mepc = pc + 4 / exception==> mepc = pc
reg [`RDATA_WIDTH-1:0] mepc;

assign epc_out = mepc;

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mepc <= `ZERO;
    end else if (epc_we_in) begin
        mepc <= {epc_in[31:2] , 2'b00};
    end else if(((waddr_in == `CSR_MEPC_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mepc <= wdata_in;
    end else begin
        mepc <= mepc;
    end
end

/*-------------------mcause--------------------*/
// mcause's MSB is used to judge whether the situation
// is interrupt(1) or exception(0)
// mcause = {interrupt[31], exception code} 32bit 31 ==> type 30~4 ==> no-use    3~0 ==> cause
reg [`RDATA_WIDTH-1:0] mcause;
reg [3:0] cause;
reg [26:0] no_use_cause;
reg interrupt_or_exception;

assign mcause = {interrupt_or_exception, no_use_cause, cause};

always @(posedge clk_in) begin
    if(reset_in == 1'b1) begin
        cause <= 4'b0000;
        no_use_cause <= 27'b0;
        interrupt_or_exception <= 1'b0;
    end else if (cause_we_in) begin
        cause <= trap_cause_in;
        no_use_cause <= 27'b0;
        interrupt_or_exception <= interrupt_type_in;
    end else if (((waddr_in == `CSR_MCAUSE_ADDR) && (we_in == `WRITE_ENABLE))) begin
        cause <= wdata_in[3:0];
        no_use_cause <= wdata_in[30:4];
        interrupt_or_exception <= wdata_in[31];
    end else begin
        cause <= cause;
        no_use_cause <= no_use_cause;
        interrupt_or_exception <= interrupt_or_exception;
    end
end

 /*--------------------------------------------- mip ----------------------------------------*/
// mip: {WPRI[31:12], MEIP(1), WPRI(1), SEIP(1), UEIP(1), MTIP(1), WPRI(1), STIP(1), UTIP(1), MSIP(1), WPRI(1), SSIP(1), USIP(1)}
// The MTIP, STIP, UTIP bits correspond to timer interrupt-pending bits for machine, supervisor, and user timer interrupts, respectively.
// mip is read only for software
reg[`RDATA_WIDTH-1:0] mip;
reg mip_meip;
reg mip_msip;
reg mip_mtip;

assign mip_meip_out = mip_meip;
assign mip_msip_out = mip_msip;
assign mip_mtip_out = mip_mtip;
assign mip = {20'b0, mip_meip, 3'b0, mip_mtip, 3'b0, mip_msip, 3'b0};

always @(posedge clk_in) begin
    if(reset_in == 1'b1) begin
        mip_meip <= 1'b0;
        mip_msip <= 1'b0;
        mip_mtip <= 1'b0;
    end else begin
        mip_meip <= interrupt_require_external_in;
        mip_mtip <= interrupt_require_timer_in;
        mip_msip <= interrupt_require_software_in;
    end
end

/*--------------------------------------------- mtval ----------------------------------------*/
// When a trap is taken into M-mode, mtval is either set to zero or written with exception-specific information
// to assist software in handling the trap.
// When a hardware breakpoint is triggered, or an instruction-fetch, load, or store address-misaligned,
// access, or page-fault exception occurs, mtval is written with the faulting virtual address.
// On an illegal instruction trap, mtval may be written with the first XLEN or ILEN bits of the faulting instruction
// WARL
// mtval 會紀錄被存取的虛擬記憶體的位址，如果 mcause 是：
// 載入/保存位址非對齊異常 (load/store address misaligned)
// 載入/保存存取異常 (load/store access fault)
// 載入/保存分頁異常 (load/store page fault)
// mtval 會紀錄觸發 exception 的指令之虛擬記憶體位址
// 如果 mcause 是：
// 指令存取異常 (instruction access fault)
// 指令分頁異常 (instruction page fault)
// 未使用的話設為0
reg[`RDATA_WIDTH-1:0]       mtval;

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mtval <= `ZERO;
    end else if(((waddr_in == `CSR_MTVAL_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mtval <= wdata_in;
    end
end


/*********************** read csr ***********************/

always @(*) begin
    //如果剛好讀的位址等同於寫的位址(類似forwarding)就bypass
    if((waddr_in == raddr_in) && we_in == `WRITE_ENABLE)begin
        rdata_out = wdata_in;
    end else begin
        case (raddr_in)
            `CSR_MVENDORID_ADDR: begin
               rdata_out = CSR_MVENDORID_VALUE; 
            end
            `CSR_MARCHID_ADDR: begin
                rdata_out = CSR_MARCHID_VALUE;
            end
            `CSR_MIMPID_ADDR: begin
                rdata_out = CSR_MIMPID_VALUE;
            end
            `CSR_MHARTID_ADDR: begin
                rdata_out = CSR_MHARTID_VALUE;
            end
            `CSR_MSTATUS_ADDR: begin
                rdata_out = mstatus;
            end
            `CSR_MISA_ADDR: begin
                rdata_out = misa;
            end
            `CSR_MIE_ADDR: begin
                rdata_out = mie;
            end
            `CSR_MTVEC_ADDR: begin
                rdata_out = mtvec;
            end
            `CSR_MSCRATCH_ADDR: begin
                rdata_out = mscratch;
            end
            `CSR_MEPC_ADDR: begin
                rdata_out = mepc;
            end
            `CSR_MCAUSE_ADDR: begin
                rdata_out = mcause;
            end
            `CSR_MTVAL_ADDR: begin
                rdata_out = mtval;
            end
            `CSR_MIP_ADDR: begin
                rdata_out = mip;
            end
            `CSR_CYCLE_ADDR, `CSR_MCYCLE_ADDR: begin
                rdata_out = mcycle[31:0];
            end
            `CSR_CYCLEH_ADDR, `CSR_MCYCLEH_ADDR: begin
                rdata_out = mcycle[63:32];
            end
            `CSR_MINSTRET_ADDR: begin
                rdata_out = minstret[31:0];
            end
            `CSR_MINSTRETH_ADDR: begin
                rdata_out = minstret[63:32];
            end 
            default: begin
                rdata_out = `ZERO;
            end
        endcase
    end
end
endmodule