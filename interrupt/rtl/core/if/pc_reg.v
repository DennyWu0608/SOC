`include "defines.v"
module pc_reg(
    input wire clk_in,
    input wire reset_in,

    //from pipe ctrl
    input wire [5:0] stall_in,
    //for jump
    input wire jump_flush_in,
    input wire [`ADDR_WIDTH-1:0] jump_address_in,
    //from pipe ctrl for interrupt
    input wire interrupt_flush_in,
    

    output reg [`ADDR_WIDTH-1:0] pc_out,
    output reg chip_enable_out
);


always @(posedge clk_in) begin
    if (reset_in == 1'b1) begin
        chip_enable_out <= 1'b0;
    end else begin
        chip_enable_out <= 1'b1;
    end
end


always @(posedge clk_in)  begin
        if (chip_enable_out == 1'b0) begin
            pc_out <= 32'h0;
        end else if (jump_flush_in|interrupt_flush_in)begin
            pc_out <= jump_address_in;// jump or branch
        end else if (stall_in[0]==`STOP) begin
            pc_out <= pc_out;  //loop
        end else begin
            pc_out <= pc_out + 4;
        end
end

endmodule