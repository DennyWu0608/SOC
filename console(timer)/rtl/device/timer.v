module timer (
    input wire clk_in,
    input wire reset_in,

    input wire req_in,
    input wire we_in,
    // input wire [31:0] raddr_in,
    input wire [31:0] wdata_in,

    output reg [31:0] time_clk_out
    //output reg time_interrupt_signal_out
);

reg [31:0] timemcp;
reg [31:0] clk_count;

localparam reg [7:0] TIME_VIEW = 8'h4;



always @(posedge clk_in) begin
    if(reset_in == 1'b1) begin
        time_clk_out <= 31'b0;
        //time_interrupt_signal_out <= 0'b0;
    end else if(we_in)begin
        timemcp <= wdata_in;
    end else if(clk_count == 1000)begin
        time_clk_out <= time_clk_out + 32'b1;
        //time_interrupt_signal_out <= 1'b1;
        clk_count <= 4'b0;
    end else begin
        clk_count <= clk_count + 1'b1;
        //time_interrupt_signal_out <= 1'b0;
    end
end

endmodule