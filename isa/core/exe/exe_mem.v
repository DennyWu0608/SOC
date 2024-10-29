`include "defines.v"
module exe_mem(
    input wire clk_in,
    input wire reset_in,
    //from exe
    input wire [`RDATA_WIDTH-1:0] reg_wdata_in,
    input wire [`RADDR_WIDTH-1:0] reg_waddr_in,
    input wire reg_we_in,
    input wire [`DATA_WIDTH-1:0] mem_data_in,
    input wire [`ADDR_WIDTH-1:0] mem_addr_in,
    input wire mem_we_in,
    input wire [3:0] mem_op_in,

    //from ctrl
    //input wire[5:0] stall_in,

    //to mem
    output reg [`RDATA_WIDTH-1:0] reg_wdata_out,
    output reg [`RADDR_WIDTH-1:0] reg_waddr_out,
    output reg reg_we_out,
    output reg [`DATA_WIDTH-1:0] mem_data_out,
    output reg [`ADDR_WIDTH-1:0] mem_addr_out,
    output reg mem_we_out,
    output reg [3:0] mem_op_out
);

    always @(posedge clk_in) begin
        if (reset_in == 1) begin
            reg_wdata_out <= `ZERO;
            reg_waddr_out <= `ZERO_REG;
            reg_we_out <= `WRITE_DISABLE;
            mem_addr_out <= `ZERO_REG;
            mem_data_out <= `ZERO;
            mem_we_out <= `WRITE_DISABLE;
            mem_op_out <= 4'b0000;
        end else begin
            reg_wdata_out <= reg_wdata_in;
            reg_waddr_out <= reg_waddr_in;
            reg_we_out <= reg_we_in;
            mem_addr_out <= mem_addr_in;
            mem_data_out <= mem_data_in;
            mem_we_out <= mem_we_in;
            mem_op_out <= mem_op_in;
        end
    end
endmodule 