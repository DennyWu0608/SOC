`include "defines.v"
module mem_wb (
    input wire clk_in,
    input wire reset_in,
    //from mem
    input wire [`RDATA_WIDTH-1:0] reg_wdata_in,
    input wire [`RADDR_WIDTH-1:0] reg_waddr_in,
    input wire reg_we_in,

    //from ctrl
    //input wire [5:0] stall_in,
    
    //to wb which is in regfile
    output reg [`RDATA_WIDTH-1:0] reg_wdata_out,
    output reg [`RADDR_WIDTH-1:0] reg_waddr_out,
    output reg reg_we_out
);
    always @(posedge clk_in) begin
        if (reset_in == 1) begin
            reg_wdata_out <= `ZERO;
            reg_waddr_out <= `ZERO_REG;
            reg_we_out <= `WRITE_DISABLE;
        end else begin
            reg_wdata_out <= reg_wdata_in;
            reg_waddr_out <= reg_waddr_in;
            reg_we_out <= reg_we_in;
        end
    end
endmodule