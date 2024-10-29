`include "defines.v"
module  dpram  #(
  parameter RAM_SIZE        = 1, //?????
  parameter RAM_ADDR_WIDTH  = 1  //?????
  )(
    input wire clk_in,
    
    //data port
    input wire ce_in,
    //from memory
    input wire [`ADDR_WIDTH-1:0] mem_addr_in,
    input wire [`DATA_WIDTH-1:0] mem_data_in,
    input wire mem_we_in,
    
    //instrution port
    input wire chip_enable_in,
    input wire [`ADDR_WIDTH-1:0] pc_in,

    //to memory (data port)
    output reg [`DATA_WIDTH-1:0] mem_data_out,

    //to pc_reg(instrution port)
    output reg [`DATA_WIDTH-1:0] inst_out
);
    reg [7:0] mem[0 : RAM_SIZE-1];//???? 
    wire [RAM_ADDR_WIDTH-1:0] addr4 ;
    assign addr4 = {mem_addr_in[RAM_ADDR_WIDTH-1:2],2'b0};//??

    wire [RAM_ADDR_WIDTH-1:0] rom_addr4;
    assign rom_addr4 = {pc_in[RAM_ADDR_WIDTH-1:2],2'b0};//??

    // data port (mem)
    //write // 寫入mem store
    always @(posedge clk_in) begin
        if(ce_in == `CHIP_ENABLE && mem_we_in == `WRITE_ENABLE)begin
            mem[addr4] <= mem_data_in[31:24];
            mem[addr4+1] <= mem_data_in[23:16];
            mem[addr4+2] <= mem_data_in[15:8];
            mem[addr4+3] <= mem_data_in[7:0]; 
        end
    end
    //read  // ld 將mem的資料讀取至 reg當中
    always @ (*) begin
		if (ce_in == `CHIP_ENABLE) begin
		    mem_data_out =  {mem[addr4],mem[addr4+1],mem[addr4+2],mem[addr4+3]};
		end else begin
			mem_data_out = `ZERO;
		end
	end		

    //instruction port(pc_reg)
    always @(*) begin
        if (chip_enable_in == 1'b0) begin
            inst_out = `ZERO;
        end else begin
            inst_out = {mem[rom_addr4],mem[rom_addr4+1],mem[rom_addr4+2],mem[rom_addr4+3]};
        end
    end

    task readByte;
        /*verilator public*/
        input integer byte_addr;
        output integer val;
        begin
            val = {24'b0,mem[byte_addr[RAM_ADDR_WIDTH-1:0]]};
        end
    endtask    


    task writeByte;
        /*verilator public*/
        input integer byte_addr;
        input [7:0] val;
        begin
            mem[byte_addr[RAM_ADDR_WIDTH-1:0]] = val;
        end
    endtask    
endmodule