`include "defines.v"
module exe (
    input wire clk_in,
    input wire reset_in,

    //form exe_id
    input wire [`DATA_WIDTH-1:0] inst_in,
    input wire [`ADDR_WIDTH-1:0] inst_address_in,
    input wire [`DATA_WIDTH-1:0] op1_in,
    input wire [`DATA_WIDTH-1:0] op2_in,
    input wire [`RADDR_WIDTH-1:0] reg_waddr_in,
    input wire reg_we_in, //可以不用？
    
    //to exe_mem for register
    output reg [`RDATA_WIDTH-1:0] reg_wdata_out,
    output reg [`RADDR_WIDTH-1:0] reg_waddr_out,
    output reg reg_we_out,

    //to exe_mem for mem(ram)
    output reg mem_we_out,
    output reg [`DATA_WIDTH-1:0] mem_data_out,
    output reg [`ADDR_WIDTH-1:0] mem_addr_out,
    output reg [3:0] mem_op_out, //LB,LH,LW,LBU, LHU, SB, SH, SW

    //to pipe_ctrl
    output reg [`ADDR_WIDTH-1:0] jump_address_out,
    output reg jump_enable_out,
    output reg stall_req_out // for m type
);

wire [6:0] opcode = inst_in [6:0];
wire [6:0] funct7 = inst_in [31:25];

wire i_reg_we_out;
wire [`RDATA_WIDTH-1 : 0] i_reg_wdata_out;


exe_i_type exe_i_type0(
    .reset_in(reset_in),
    .inst_in(inst_in),
    .op1_in(op1_in),
    .op2_in(op2_in),
    .reg_wdata_out(i_reg_wdata_out),
    .reg_we_out(i_reg_we_out)
);

wire r_reg_we_out;
wire [`RDATA_WIDTH-1 : 0] r_reg_wdata_out;

exe_r_type exe_r_type0(
    .reset_in(reset_in),
    .inst_in(inst_in),
    .op1_in(op1_in),
    .op2_in(op2_in),
    .reg_wdata_out(r_reg_wdata_out),
    .reg_we_out(r_reg_we_out)
);

wire l_s_reg_we_out;
wire [`RDATA_WIDTH-1 : 0] l_s_reg_wdata_out;
wire [`ADDR_WIDTH-1 : 0] l_s_mem_addr_out;
wire [`DATA_WIDTH-1 : 0] l_s_mem_data_out;
wire l_s_mem_we_out;
wire [3:0] l_s_mem_op_out;

exe_s_l_type exe_s_l_type0(
    .reset_in(reset_in),
    .inst_in(inst_in),
    .op1_in(op1_in),
    .op2_in(op2_in),
    .reg_wdata_out(l_s_reg_wdata_out),
    .reg_we_out(l_s_reg_we_out),
    .mem_addr_out(l_s_mem_addr_out),
    .mem_data_out(l_s_mem_data_out),
    .mem_we_out(l_s_mem_we_out),
    .mem_op_out(l_s_mem_op_out)
);

wire [`ADDR_WIDTH-1:0] b_j_jump_address_out;
wire b_j_jump_enable_out;

exe_b_j_type exe_b_j_type0(
    .reset_in(reset_in),
    .inst_in(inst_in),
    .inst_address_in(inst_address_in),
    .op1_in(op1_in),
    .op2_in(op2_in),
    .jump_address_out(b_j_jump_address_out),
    .jump_enable_out(b_j_jump_enable_out)
);

wire [`DATA_WIDTH-1:0] m_reg_wdata_out;
wire m_stall_out;
wire m_reg_we_out;

exe_m_type exe_m_type0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    .inst_in(inst_in),
    .op1_in(op1_in),
    .op2_in(op2_in),
    .stall_out(m_stall_out),
    .reg_wdata_out(m_reg_wdata_out),
    .reg_we_out(m_reg_we_out)
);

assign stall_req_out = m_stall_out;

    always @(*) begin
        //unuse
        if (reset_in == 1) begin
            reg_waddr_out = `ZERO_REG;
            reg_wdata_out = `ZERO;
            reg_we_out = `WRITE_DISABLE;
            mem_we_out = `WRITE_DISABLE;
            mem_addr_out = `ZERO;
            mem_data_out = `ZERO;
            mem_op_out = `MEM_NOP;
            jump_address_out = `ZERO;
            jump_enable_out = 1'b0;
        end else begin
            case (opcode)
                `INST_TYPE_I:begin
                    reg_waddr_out = reg_waddr_in;
                    reg_wdata_out = i_reg_wdata_out;
                    reg_we_out = i_reg_we_out;
                    mem_we_out = `WRITE_DISABLE;
                    mem_addr_out = `ZERO;
                    mem_data_out = `ZERO;
                    mem_op_out = `MEM_NOP;
                    jump_address_out = `ZERO;
                    jump_enable_out = 1'b0;
                end
                `INST_TYPE_R_M:begin
                    reg_waddr_out = reg_waddr_in;
                    //reg_wdata_out = r_reg_wdata_out;
                    //reg_we_out = r_reg_we_out;
                    mem_we_out = `WRITE_DISABLE;
                    mem_addr_out = `ZERO;
                    mem_data_out = `ZERO;
                    mem_op_out = `MEM_NOP;
                    jump_address_out = `ZERO;
                    jump_enable_out = 1'b0;
                    if (funct7 == 7'b0000001) begin
                        reg_wdata_out = m_reg_wdata_out;
                        reg_we_out = m_reg_we_out;
                    end else begin
                        reg_wdata_out = r_reg_wdata_out;
                        reg_we_out = r_reg_we_out;
                    end
                end
                `INST_TYPE_U_LUI, `INST_TYPE_U_AUIPC:begin
                    reg_waddr_out = reg_waddr_in;
                    reg_wdata_out = op1_in + op2_in;
                    reg_we_out = reg_we_in;
                    mem_we_out = `WRITE_DISABLE;
                    mem_addr_out = `ZERO;
                    mem_data_out = `ZERO;
                    mem_op_out = `MEM_NOP;
                    jump_address_out = `ZERO;
                    jump_enable_out = 1'b0;
                end
                `INST_TYPE_S:begin
                    reg_waddr_out = reg_waddr_in;
                    reg_wdata_out = l_s_reg_wdata_out;
                    reg_we_out = l_s_reg_we_out;
                    mem_we_out = l_s_mem_we_out;
                    mem_addr_out = l_s_mem_addr_out;
                    mem_data_out = l_s_mem_data_out;
                    mem_op_out = l_s_mem_op_out;
                    jump_address_out = `ZERO;
                    jump_enable_out = 1'b0;
                end
                `INST_TYPE_L:begin
                    reg_waddr_out = reg_waddr_in;
                    reg_wdata_out = l_s_reg_wdata_out;
                    reg_we_out = l_s_reg_we_out;
                    mem_we_out = l_s_mem_we_out;
                    mem_addr_out = l_s_mem_addr_out;
                    mem_data_out = l_s_mem_data_out;
                    mem_op_out = l_s_mem_op_out;
                    jump_address_out = `ZERO;
                    jump_enable_out = 1'b0;
                end
                `INST_TYPE_JAL:begin
                    reg_waddr_out = reg_waddr_in; // rd address
                    reg_wdata_out = inst_address_in + 4; // rd <= pc + 4
                    reg_we_out = `WRITE_ENABLE;
                    mem_we_out = `WRITE_DISABLE;
                    mem_addr_out = `ZERO;
                    mem_data_out = `ZERO;
                    mem_op_out = `MEM_NOP;
                    jump_address_out = b_j_jump_address_out; //imm
                    jump_enable_out = b_j_jump_enable_out;
                end
                `INST_TYPE_JALR:begin
                    reg_waddr_out = reg_waddr_in;
                    reg_wdata_out = inst_address_in + 4; // rd <= pc + 4
                    reg_we_out = `WRITE_ENABLE;
                    mem_we_out = `WRITE_DISABLE;
                    mem_addr_out = `ZERO;
                    mem_data_out = `ZERO;
                    mem_op_out = `MEM_NOP;
                    jump_address_out = b_j_jump_address_out + op1_in; // rs1 + imm
                    //(b_jump_addr_o + op1_i) & {{31{1'b1}},1'b0}; 
                    jump_enable_out = b_j_jump_enable_out;
                end
                `INST_TYPE_B:begin
                    reg_waddr_out = `ZERO_REG;
                    reg_wdata_out = `ZERO;
                    reg_we_out = `WRITE_DISABLE;
                    mem_addr_out = `ZERO;
                    mem_data_out = `ZERO;
                    mem_op_out = `MEM_NOP;
                    mem_we_out = `WRITE_DISABLE;
                    jump_address_out = b_j_jump_address_out;
                    jump_enable_out = b_j_jump_enable_out;
                end
                default: begin
                    reg_waddr_out = `ZERO_REG;
                    reg_wdata_out = `ZERO;
                    reg_we_out = `WRITE_DISABLE;
                    mem_we_out = `WRITE_DISABLE;
                    mem_addr_out = `ZERO;
                    mem_data_out = `ZERO;
                    mem_op_out = `MEM_NOP;
                    jump_address_out = `ZERO;
                    jump_enable_out = 1'b0;
                end
            endcase
        end//if
    end//always
endmodule