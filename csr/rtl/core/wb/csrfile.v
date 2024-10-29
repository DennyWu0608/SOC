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
    input wire instret_incr_in

    //to pip_ctrl

    //from pip_ctrl  
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

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mstatus <= `ZERO;
    end else if(((waddr_in == `CSR_MSTATUS_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mstatus <= wdata_in;
    end else begin
        mstatus <= `ZERO;
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
        end
    end
end

/*-------------------mie-------------------*/
// 按照 mcause 的 exception code 編碼 n 對應的 mie[n] 來表示該 interrupt 的 enable
// mie: {WPRI[31:12], MEIE(1), WPRI(1), SEIE(1), UEIE(1), 
// MTIE(1), WPRI(1), STIE(1), UTIE(1), 
// MSIE(1), WPRI(1), SSIE(1), USIE(1)}
reg [`RDATA_WIDTH-1:0] mie;
assign mie = {32'b0};

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mie <= `ZERO;
    end else if(((waddr_in == `CSR_MIE_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mie <= wdata_in;
    end else begin
        mie <= `ZERO;
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

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mtvec <= `ZERO;
    end else if(((waddr_in == `CSR_MTVEC_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mtvec <= wdata_in;
    end else begin
        mtvec <= `ZERO;
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
        mscratch <= `ZERO;
    end
end

/*-------------------mepc-------------------*/
// 由硬體在interrupt/exception發生時的當下將pc寫到該CSR，在mret指令執行時
// 將mepc寫回pc來回到trap發生之前的位置。
// interrupt==> mepc = pc + 4 / exception==> mepc = pc
reg [`RDATA_WIDTH-1:0] mepc;

always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        mepc <= `ZERO;
    end else if(((waddr_in == `CSR_MEPC_ADDR) && (we_in == `WRITE_ENABLE))) begin
        mepc <= wdata_in;
    end else begin
        mepc <= `ZERO;
    end
end

/*-------------------mcause--------------------*/
// mcause's MSB is used to judge whether the situation
// is interrupt(1) or exception(0)
// mcause = {interrupt[31:30], exception code}
reg [`RDATA_WIDTH-1:0] mcause;

 /*--------------------------------------------- mip ----------------------------------------*/
// mip: {WPRI[31:12], MEIP(1), WPRI(1), SEIP(1), UEIP(1), MTIP(1), WPRI(1), STIP(1), UTIP(1), MSIP(1), WPRI(1), SSIP(1), USIP(1)}
// The MTIP, STIP, UTIP bits correspond to timer interrupt-pending bits for machine, supervisor, and user timer interrupts, respectively.
reg[`RDATA_WIDTH-1:0]       mip;

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
    end else begin
        mtval <= `ZERO;
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