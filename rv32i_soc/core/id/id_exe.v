`include "defines.v"
module id_exe (
    input wire reset_in,
    input wire clk_in,

    //from ID
    input wire [`DATA_WIDTH-1:0] inst_in,
    input wire [`ADDR_WIDTH-1:0] inst_address_in,
    input wire [`RDATA_WIDTH-1:0] op1_in,
    input wire [`RDATA_WIDTH-1:0] op2_in,
    input wire [`RADDR_WIDTH-1:0] reg_waddr_in,
    input wire reg_we_in,
    
    //from ctrl
    input wire [5:0] stall_in,
    input wire jump_flush_in,

    //to ID
    output reg inst_is_load_out,
    output reg [`RADDR_WIDTH-1:0] rd_out,

    //to EXE
    output reg [`DATA_WIDTH-1:0] inst_out,
    output reg [`ADDR_WIDTH-1:0] inst_address_out,
    output reg [`RDATA_WIDTH-1:0] op1_out,
    output reg [`RDATA_WIDTH-1:0] op2_out,
    output reg [`RADDR_WIDTH-1:0] reg_waddr_out,
    output reg reg_we_out
);

    wire[6:0] opcode = inst_in[6:0];

    always @(posedge clk_in) begin
        if(reset_in == 1) begin
            inst_out <= `NOP;
            inst_address_out <= `ZERO;
            op1_out <= `ZERO;
            op2_out <= `ZERO;
            reg_we_out <= `WRITE_DISABLE;
            reg_waddr_out <= `ZERO_REG;
            inst_is_load_out <= 1'b0;
            rd_out <= `ZERO_REG;
        end else if(stall_in[2] == `STOP && stall_in[3] == `STOP) begin
            inst_out <= inst_out;
            inst_address_out <= inst_address_in;
            op1_out <= op1_out;
            op2_out <= op2_out;
            reg_we_out <= reg_we_out;
            reg_waddr_out <= reg_waddr_out;
        end else if(stall_in[2] == `STOP && stall_in[3] == `NOSTOP)begin
            //如果id要停但是exe不停直接讓id_exe流掉
            inst_out <= `NOP;
            inst_address_out <= inst_address_out;
            op1_out <= `ZERO;
            op2_out <= `ZERO;
            reg_we_out  <= `WRITE_DISABLE;
            reg_waddr_out <= `ZERO_REG;
        end else if(jump_flush_in)begin
            //if jump flush is 1 that flush all the wire
            inst_out <= `NOP;
            inst_address_out <= inst_address_out; //????
            op1_out <= `ZERO;
            op2_out <= `ZERO;
            reg_we_out  <= `WRITE_DISABLE;
            reg_waddr_out <= `ZERO_REG;
        end else begin
            inst_out <= inst_in;
            inst_address_out <= inst_address_in;
            op1_out <= op1_in;
            op2_out <= op2_in;
            reg_we_out <= reg_we_in;
            reg_waddr_out <= reg_waddr_in;
        end
    end


    always @(posedge clk_in) begin
        if (reset_in == 1) begin
            inst_is_load_out <= 1'b0;
            rd_out <= `ZERO_REG;
        end else if(jump_flush_in) begin
            inst_is_load_out <= 1'b0;
            rd_out <= `ZERO_REG;
        end else if(stall_in[2] == `STOP && stall_in[3] == `STOP) begin
            inst_is_load_out <= inst_is_load_out;
            rd_out <= rd_out;
        end else if(stall_in[2] == `STOP && stall_in[3] == `NOSTOP) begin
            inst_is_load_out <= 1'b0;
            rd_out <= `ZERO_REG;
        end else begin
            inst_is_load_out <= (opcode == `INST_TYPE_L);
            rd_out <= inst_in[11:7];
        end//if
    end 


endmodule