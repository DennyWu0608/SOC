`include "defines.v"
module interrupt_ctrl(
    input wire reset_in,
    input wire clk_in,

    input wire [`DATA_WIDTH-1 : 0] exception_in,//form mem (ecall, mret)
    input wire [`ADDR_WIDTH-1 : 0] pc_in,//form mem.pc_in

    //from csr
    // mstatus.mie ==> check 0/1
    input wire mstatus_mie_in,
    
    //mip ==> all of pending(t:timer,s:software,e:external)
    input wire mip_mtip_in,
    input wire mip_msip_in, 
    input wire mip_meip_in,

    //mie os
    input wire mie_mtie_in,
    input wire mie_msie_in,
    input wire mie_meie_in,

    //mtvec
    input wire[`DATA_WIDTH-1:0] mtvec_in,

    //epc(Exception program counter)
    input wire[`DATA_WIDTH-1:0] epc_in,

    //to csr
    //check it is interrupt or exception
    output reg interrupt_type_out,
    output reg cause_we_out,
    //16 in total
    output reg [3:0] trap_cause_out,

    output reg epc_we_out,
    output reg [`DATA_WIDTH-1:0] epc_out,

    output reg mstatus_ie_clear_out,
    output reg mstatus_ie_set_out,

    //to the all stages of pipline
    output reg interrupt_en_out,
    output reg flush_out,
    output reg [`DATA_WIDTH-1:0] new_pc_out //pc_reg = new_pc_out
);
    
/******************************FSM*****************************/

//machine states
parameter RESET = 4'b0001;
parameter OPERATING = 4'b0010;
parameter TRAP_TAKEN = 4'b0100;
parameter TRAP_RETURN = 4'b1000;

//exception
wire   mret, ecall;
assign {ecall, mret}=exception_in[1:0];

//state reisters
reg [3:0] NOW_S;
reg [3:0] NEXT_S;

//check there is  a interrupt on pending
wire eip,tip,sip,ip;
assign eip = (mie_meie_in & mip_meip_in); //可以中斷且待處理
assign tip = (mie_mtie_in & mip_mtip_in);
assign sip = (mie_msie_in & mip_msip_in);
assign ip = (eip | tip | sip);

wire trap_happen; 
assign trap_happen = (mstatus_mie_in & ip) | ecall;// mstatus.MIE & MIP & MIE

//every clk we will check if the reset == 1 get RESET
always @(posedge clk_in) begin
    if(reset_in == 1'b1) begin
        NOW_S <= RESET;
    end else begin
        NOW_S <= NEXT_S;
    end
end

//state transfer
always @(*) begin
    case (NOW_S)
        RESET: begin
            NEXT_S = OPERATING;
        end
        OPERATING: begin
            if(trap_happen)begin
                NEXT_S = TRAP_TAKEN;
            end else if (mret) begin
                NEXT_S = TRAP_RETURN;
            end else begin
                NEXT_S = OPERATING;
            end
        end
        TRAP_TAKEN: begin
            NEXT_S = OPERATING;
        end
        TRAP_RETURN: begin
            NEXT_S = OPERATING;
        end
        default: begin
            NEXT_S = OPERATING;
        end
    endcase
end

reg [1:0] mtvec_mode = mtvec_in[1:0];
reg [29:0] mtvec_base = mtvec_in[31:2];

reg [`DATA_WIDTH-1:0] trap_handler;
wire [`DATA_WIDTH-1:0] base_offset;
wire [`DATA_WIDTH-1:0] vec_mux_out;
// mtvec = { base[maxlen-1:2], mode[1:0]}
// The value in the BASE field must always be aligned on a 4-byte boundary, and the MODE setting may impose
// additional alignment constraints on the value in the BASE field.
// when mode =2'b00, direct mode, When MODE=Direct, all traps into machine mode cause the pc to be set to the address in the BASE field.
// when mode =2'b01, Vectored mode, all synchronous exceptions into machine mode cause the pc to be set to the address in the BASE
// field, whereas interrupts cause the pc to be set to the address in the BASE field plus four times the interrupt cause number.
assign base_offset = {26'b0, trap_cause_out, 2'b0};  // trap_casue_o * 4 左移兩bit
assign vec_mux_out = mtvec_in[0] ? {mtvec_base, 2'b00} + base_offset : {mtvec_base, 2'b00}; //mode ==> direct / or not direct
assign trap_handler = interrupt_type_out ? vec_mux_out : {mtvec_base, 2'b00};


// interrupt 與 exception 不一樣的 return address，i.e., mpec <= pc or pc+4
// 而 FSM 在trap 發生後的下一個 clk 才會存 epc
// 所以必須記錄 上一個 clk 是否是 exception

// reg exception_or_interrupt;
//     always @(*) 
//         exception_or_interrupt = (|exception_in);

  always @(*) begin
        if (|exception_in)
            epc_out = pc_in - 32'h4;
        else
            epc_out = pc_in;    
    end

/*                 FSM DOING SOMETHING           */

always @(*) begin
    case (NOW_S)
        RESET: begin
            flush_out = 1'b0;
            interrupt_en_out = 1'b0; //要不要中斷
            new_pc_out = `ZERO; // 給予pc_reg一個新的pc
            epc_we_out = 1'b0; // 是否要set mepc <= pc
            cause_we_out = 1'b0; // 是否要set mcause
            mstatus_ie_clear_out = 1'b0;// 是否要使csr中的mie變成0 不可中斷
            mstatus_ie_set_out = 1'b0;// 是否要使csr中的mie變成1 可中斷
        end 

        OPERATING: begin // core doing other instruction
            flush_out = 1'b0;
            interrupt_en_out = 1'b0; //要不要中斷
            new_pc_out = `ZERO; // 給予pc_reg一個新的pc
            epc_we_out = 1'b0; // 是否要set mepc <= pc
            cause_we_out = 1'b0; // 是否要set mcause
            mstatus_ie_clear_out = 1'b0;// 是否要使csr中的mie變成0 不可中斷
            mstatus_ie_set_out = 1'b0;// 是否要使csr中的mie變成1 可中斷
        end

        TRAP_TAKEN: begin
            flush_out = 1'b1;
            interrupt_en_out = 1'b1; //要不要中斷
            new_pc_out =  trap_handler; // jump to trap_handler (mtvec decide)
            epc_we_out = 1'b1; // 是否要set mepc <= pc
            cause_we_out = 1'b1; // 是否要set mcause
            mstatus_ie_clear_out = 1'b1;// 是否要使csr中的mie變成0 不可中斷
            mstatus_ie_set_out = 1'b0;// 是否要使csr中的mie變成1 可中斷
            // epc_out = (exception_or_interrupt) ? pc_in - 4 : pc_in;
        end

        TRAP_RETURN: begin
            flush_out = 1'b1;
            interrupt_en_out = 1'b1; //要不要中斷
            new_pc_out = epc_in; // mepc == original pc
            epc_we_out = 1'b0; // 是否要set mepc <= pc
            cause_we_out = 1'b0; // 是否要set mcause
            mstatus_ie_clear_out = 1'b0;// 是否要使csr中的mie變成0 不可中斷
            mstatus_ie_set_out = 1'b1;// 是否要使csr中的mie變成1 可中斷    
        end

        default: begin
            flush_out = 1'b0;
            interrupt_en_out = 1'b0;
            new_pc_out = `ZERO;
            epc_we_out = 1'b0;
            cause_we_out = 1'b0;
            mstatus_ie_clear_out = 1'b0;
            mstatus_ie_set_out = 1'b0;
        end
    endcase
end

/*cause & type of trap in operation stage ==> update the mcause csr*/
always @(posedge clk_in) begin
    if(reset_in == 1'b1)begin
        trap_cause_out <= 4'b0000; //高電阻 使其代表無效值
        interrupt_type_out <= 1'b0; //高電阻 使其代表無效值
    end else if(NOW_S == OPERATING)begin
        if (mstatus_mie_in & eip) begin
            trap_cause_out <= 4'b1011; //11 machine external interrupt
            interrupt_type_out <= 1'b1;
        end else if (mstatus_mie_in & tip) begin
            trap_cause_out <= 4'b0111; //7 machine timer interrupt
            interrupt_type_out <= 1'b1;
        end else if (mstatus_mie_in & sip) begin
            trap_cause_out <= 4'b0011; //3 machine software interrupt
            interrupt_type_out <= 1'b1;
        end else if (ecall)begin
            trap_cause_out <= 4'b1011; //11 Enviroment call form M-mode
            interrupt_type_out <= 1'b0;
        end
    end
end


endmodule