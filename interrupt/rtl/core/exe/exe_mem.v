`include "defines.v"
module exe_mem(
    input wire clk_in,
    input wire reset_in,
    //from exe
    input wire [`ADDR_WIDTH-1:0] inst_address_in,
    input wire [`RDATA_WIDTH-1:0] reg_wdata_in,
    input wire [`RADDR_WIDTH-1:0] reg_waddr_in,
    input wire reg_we_in,
    input wire [`DATA_WIDTH-1:0] mem_data_in,
    input wire [`ADDR_WIDTH-1:0] mem_addr_in,
    input wire mem_we_in,
    input wire [3:0] mem_op_in,
    input wire csr_we_in,
    input wire [`RDATA_WIDTH-1:0] csr_wdata_in,
    input wire [`CSR_ADDR_WIDTH-1:0] csr_waddr_in,
    input wire [`DATA_WIDTH-1:0] exception_pass_in,

    //from pipe_ctrl
    input wire[5:0] stall_in,

    //from pipe ctrl for interrupt
    input wire interrupt_flush_in,

    //to mem
    //1. reg by pass
    output reg [`RDATA_WIDTH-1:0] reg_wdata_out,
    output reg [`RADDR_WIDTH-1:0] reg_waddr_out,
    output reg reg_we_out,
    output reg [`ADDR_WIDTH-1:0] inst_address_out,
    //2. for store of load
    output reg [`DATA_WIDTH-1:0] mem_data_out,
    output reg [`ADDR_WIDTH-1:0] mem_addr_out,
    output reg mem_we_out,
    output reg [3:0] mem_op_out,
    //3. csr by pass
    output reg csr_we_out,
    output reg [`RDATA_WIDTH-1:0] csr_wdata_out,
    output reg [`CSR_ADDR_WIDTH-1:0] csr_waddr_out,
    output reg [`DATA_WIDTH-1:0] exception_pass_out
);
    //for interrupt ctrl
    always @(posedge clk_in) begin
        if(reset_in == 1'b1) begin
            inst_address_out <= `ZERO;
            exception_pass_out <= `ZERO;
        end else if (interrupt_flush_in) begin
            inst_address_out <= `ZERO;
            exception_pass_out <= `ZERO;
        end else begin
            exception_pass_out <= exception_pass_in;
            inst_address_out <= inst_address_in;
        end
    end

    //for csr
    always @(posedge clk_in) begin
        if(reset_in == 1'b1) begin
            csr_waddr_out <= `CSR_ZERO_ADDR;
            csr_wdata_out <= `ZERO;
            csr_we_out <= `WRITE_DISABLE;
        end else if (interrupt_flush_in) begin
            csr_waddr_out <= `CSR_ZERO_ADDR;
            csr_wdata_out <= `ZERO;
            csr_we_out <= `WRITE_DISABLE;
        end else begin
            csr_waddr_out <= csr_waddr_in;
            csr_wdata_out <= csr_wdata_in;
            csr_we_out <= csr_we_in;
        end
    end

    //for store and load
    always @(posedge clk_in) begin
        if (reset_in == 1) begin
            mem_addr_out <= `ZERO_REG;
            mem_data_out <= `ZERO;
            mem_we_out <= `WRITE_DISABLE;
            mem_op_out <= 4'b0000;
        end else if (interrupt_flush_in) begin
            mem_addr_out <= `ZERO_REG;
            mem_data_out <= `ZERO;
            mem_we_out <= `WRITE_DISABLE;
            mem_op_out <= 4'b0000;
        end else begin
            mem_addr_out <= mem_addr_in;
            mem_data_out <= mem_data_in;
            mem_we_out <= mem_we_in;
            mem_op_out <= mem_op_in;
        end
    end

    //for wb regfile
    always @(posedge clk_in) begin
        if (reset_in == 1) begin
            reg_wdata_out <= `ZERO;
            reg_waddr_out <= `ZERO_REG;
            reg_we_out <= `WRITE_DISABLE;
        end else if (interrupt_flush_in) begin
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