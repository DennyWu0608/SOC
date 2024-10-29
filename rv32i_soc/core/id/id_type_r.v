`include "defines.v"
module id_type_r(
    input wire[`DATA_WIDTH-1:0] inst_in,

    //從reg同時已經讀進來的資料
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
    //wire[2:0] funct3 = inst_in[14:12];
    wire[6:0] funct7 = inst_in[31:25];
    //wire[4:0] shamt = inst_in[24:20];
    wire[4:0] rd = inst_in[11:7]; // store answer place
    wire[4:0] rs1 = inst_in[19:15];//op1
    wire[4:0] rs2 = inst_in[24:20];//op2
    

    wire istyper;
    assign istyper = (opcode == `INST_TYPE_R)&& ((funct7 == 7'b0000000)||(funct7==7'b0100000));

    always @(*) begin
            if (istyper == 1) begin
                reg1_raddr_out = rs1; // rs1的位址 同一時間 會將位址丟到reg去判斷其值？然後在透過reg1_data_in帶回來op1_out?
                reg2_raddr_out = rs2;
                reg1_renable_out = `READ_ENABLE;
                reg2_renable_out = `READ_ENABLE;
                reg_wenable_out = `WRITE_ENABLE;
                reg_waddr_out = rd;
                op1_out = reg1_rdata_in;
                op2_out = reg2_rdata_in;
            end else begin
                reg1_raddr_out = `ZERO_REG;
                reg2_raddr_out = `ZERO_REG;
                reg1_renable_out = `READ_DISABLE;
                reg2_renable_out = `READ_DISABLE;
                reg_wenable_out = `WRITE_DISABLE;
                reg_waddr_out = `ZERO_REG;
                op1_out = `ZERO;
                op2_out = `ZERO;
            end//if
    end
endmodule