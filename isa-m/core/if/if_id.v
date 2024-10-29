`include "defines.v"

module if_id (
    input wire clk_in,
    input wire reset_in,

    input wire [`DATA_WIDTH-1:0] inst_in,
    input wire [`ADDR_WIDTH-1:0] address_in, // from pc<=pc+4
    
    //from ctrl
    input wire [5:0] stall_in,
    input wire jump_flush_in,

    output reg [`DATA_WIDTH-1:0] inst_out,
    output reg [`ADDR_WIDTH-1:0] address_out
);

    always @(posedge clk_in) begin
        if (reset_in == 1) begin
            address_out <= 32'h0;
            inst_out <= `NOP;
        end else if (stall_in[1]==`STOP && stall_in[2]==`STOP) begin
            address_out <= address_out;
            inst_out <= inst_out;
        end else if (stall_in[1]==`STOP && stall_in[2]==`NOSTOP) begin
            address_out <= 32'h0;
            inst_out <= `NOP;
        end else if (jump_flush_in == 1'b1) begin //如果jump 需要把先前所作的指令中的內容沖掉
            address_out <= 32'h0;
            inst_out <= `NOP;
        end else begin
            address_out <= address_in;
            inst_out <= inst_in;
        end//if
    end//always

endmodule