`include "defines.v"
module id_type_i(
    input wire[`DATA_WIDTH-1:0] inst_in,

    input wire[`RDATA_WIDTH-1:0] reg1_rdata_in,
    input wire[`RDATA_WIDTH-1:0] reg2_rdata_in,

    output reg[`RADDR_WIDTH-1:0] reg1_raddr_out,
    output reg[`RADDR_WIDTH-1:0] reg2_raddr_out,
    output reg reg1_renable_out,
    output reg reg2_renable_out,
    output reg[`RDATA_WIDTH-1:0] op1_out,
    output reg[`RDATA_WIDTH-1:0] op2_out,
    output reg reg_wenable_out,
    output reg[`RADDR_WIDTH-1:0] reg_waddr_out
);
    wire[6:0] opcode = inst_in[6:0];
    wire[2:0] funct3 = inst_in[14:12]; // judge the function is ori or addi
    wire[6:0] funct7 = inst_in[31:25];
    wire[4:0] shamt = inst_in[24:20];
    wire[4:0] rd = inst_in[11:7]; // store answer place
    wire[4:0] rs1 = inst_in[19:15];//op1
    //wire[4:0] rs2 = inst_in[24:20];//op2
    

    wire istypei;
    assign istypei = (opcode == `INST_TYPE_I);

    always @(*) begin
        if (istypei == 1) begin
            reg_wenable_out = `WRITE_ENABLE;
            reg_waddr_out = rd;//write place
            reg1_raddr_out = rs1;//read 1
            reg2_raddr_out = `ZERO_REG;//0 because the place go to the imm
            reg1_renable_out = `READ_ENABLE;
            reg2_renable_out = `READ_DISABLE;
            op1_out = reg1_rdata_in;
            case (funct3) 
                `INST_ADDI, `INST_SLTI,`INST_SLTIU,`INST_XORI,`INST_ORI,`INST_ANDI: begin
                    //for immediate signed extandedinst[31] 複製到 op2[31:11], inst[30:20] 複製到 op2[10:0]
                    op2_out = {{20{inst_in[31]}}, inst_in[31:20]};
                end
                `INST_SLLI: begin
                    if(funct7 == 7'b0000000)begin
                        op2_out = {{27{1'b0}},shamt[4:0]};;
                    end else begin
                        reg1_raddr_out = `ZERO_REG;
                        reg2_raddr_out = `ZERO_REG;
                        reg1_renable_out = `READ_DISABLE;
                        reg2_renable_out = `READ_DISABLE;
                        reg_wenable_out = `WRITE_DISABLE;
                        reg_waddr_out = `ZERO_REG;
                        op1_out = `ZERO;
                        op2_out = `ZERO;
                    end
                end
                `INST_SRLI: begin //INST_SRAI
                    if(funct7 == 7'b0000000 || funct7 == 7'b0100000)begin
                        op2_out = {{27{1'b0}},shamt[4:0]};
                    end else begin
                        reg1_raddr_out = `ZERO_REG;
                        reg2_raddr_out = `ZERO_REG;
                        reg1_renable_out = `READ_DISABLE;
                        reg2_renable_out = `READ_DISABLE;
                        reg_wenable_out = `WRITE_DISABLE;
                        reg_waddr_out = `ZERO_REG;
                        op1_out = `ZERO;
                        op2_out = `ZERO;
                    end
                end
                default:begin
                    reg1_raddr_out = `ZERO_REG;
                    reg2_raddr_out = `ZERO_REG;
                    reg1_renable_out = `READ_DISABLE;
                    reg2_renable_out = `READ_DISABLE;
                    reg_wenable_out = `WRITE_DISABLE;
                    reg_waddr_out = `ZERO_REG;
                    op1_out = `ZERO;
                    op2_out = `ZERO;
                end//default
            endcase //case
        end else begin
            reg1_raddr_out = `ZERO_REG;
            reg2_raddr_out = `ZERO_REG;
            reg1_renable_out = `READ_DISABLE;
            reg2_renable_out = `READ_DISABLE;
            reg_wenable_out = `WRITE_DISABLE;
            reg_waddr_out = `ZERO_REG;
            op1_out = `ZERO;
            op2_out = `ZERO;
        end
    end
endmodule