`include "defines.v"
module regfile (
    input wire clk_in,
    input wire reset_in,
    //from WB
    input wire we_in,
    input wire [`RADDR_WIDTH-1:0] waddr_in,
    input wire [`RDATA_WIDTH-1:0] wdata_in,
    //from id read
    input wire [`RADDR_WIDTH-1:0] reg1_raddr_in,
    input wire [`RADDR_WIDTH-1:0] reg2_raddr_in,
    input wire reg1_renable_in,
    input wire reg2_renable_in,

    //to id
    output reg [`RDATA_WIDTH-1:0] rdata1_out,
    output reg [`RDATA_WIDTH-1:0] rdata2_out
);
    reg [`RDATA_WIDTH-1:0] regs[0:`RNUM-1]; //32 the size of 32bits register
    integer i;
    initial begin
        for(i = 0;i < `RNUM;i=i+1)
        begin
            regs[i] = 0;
        end
    end

    //write
    always @(posedge clk_in) begin
        if (reset_in == 0) begin
             if ((we_in == `WRITE_ENABLE) && (waddr_in != `ZERO_REG)) begin
                    //write the data to the rd[address] <= data
                    regs[waddr_in] <= wdata_in;
                end
        end
    end
    //read 1
    always @(*) begin
        if (reg1_raddr_in == `ZERO_REG) begin
            rdata1_out = `ZERO;
        end else if (reg1_raddr_in == waddr_in && reg1_renable_in == `READ_ENABLE && we_in == `WRITE_ENABLE)begin
            rdata1_out = wdata_in; //wb=>id forwarding
        end else if (reg1_renable_in == `READ_ENABLE) begin
            rdata1_out = regs[reg1_raddr_in];
        end else begin
            rdata1_out = `ZERO;
        end
    end

    //read 2
    always @(*) begin
        if (reg2_raddr_in == `ZERO_REG) begin
            rdata2_out = `ZERO;
        end else if (reg2_raddr_in == waddr_in && reg2_renable_in == `READ_ENABLE && we_in == `WRITE_ENABLE)begin
            rdata2_out = wdata_in; //wb=>id forwarding
        end else if (reg2_renable_in == `READ_ENABLE) begin
            rdata2_out = regs[reg2_raddr_in];
        end else begin
            rdata2_out = `ZERO;
        end
    end

    task readRegister;
        /*verilator public*/
        input integer raddr;
        output integer val;
        begin
            val = regs[raddr[4:0]];
        end
    endtask

endmodule
