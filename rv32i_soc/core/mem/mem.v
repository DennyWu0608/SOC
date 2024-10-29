`include "defines.v"
module mem(
    input wire clk_in,
    input wire reset_in,
    //from exe_mem
    input wire [`RDATA_WIDTH-1:0] reg_wdata_in,
    input wire [`RADDR_WIDTH-1:0] reg_waddr_in,
    input wire reg_we_in,
    input wire [`DATA_WIDTH-1:0] mem_data_in, //for store will store in mem
    input wire [`ADDR_WIDTH-1:0] mem_addr_in,
    input wire mem_we_in,
    input wire [3:0] mem_op_in,

    //from ram
    input wire [`DATA_WIDTH-1:0] ram_data_in,
    
    //to ram
    output reg [`ADDR_WIDTH-1:0] ram_addr_out,
    output reg [`DATA_WIDTH-1:0] ram_data_out,
    output reg ram_write_request_out,
    output reg ram_ce_out,

    //to mem_wb
    output reg [`RDATA_WIDTH-1:0] reg_wdata_out,
    output reg [`RADDR_WIDTH-1:0] reg_waddr_out,
    output reg reg_we_out,

    //for isa test
    output reg halt_out
);

    always @(posedge clk_in) begin
        //for isa test
        if (mem_op_in==`SW && mem_addr_in == `HALT_ADDR)
            halt_out <= 1'b1;
        else
            halt_out <= halt_out;
    end

    reg[`DATA_WIDTH-1:0] reg_wdata;
    assign reg_wdata_out = reg_wdata;

    //for wb regfile
    always @(*) begin
        if (reset_in == 1'b1) begin
            reg_waddr_out = `ZERO_REG;
            reg_we_out = `WRITE_DISABLE;
            reg_wdata = `ZERO;
        end else begin
            reg_waddr_out = reg_waddr_in;
            reg_we_out = reg_we_in;
            reg_wdata = reg_wdata_in;
        end
    end


    wire [1:0] ram_addr_offset;
    assign ram_addr_offset = mem_addr_in[1:0] & 2'b11; // 0,1,2,3 //why it can use the address to determine the data that we need

    always @(*) begin
        if (reset_in == 1) begin
            ram_ce_out = `CHIP_DISABLE;
            ram_addr_out = `ZERO;
            ram_data_out = `ZERO;
            ram_write_request_out = `WRITE_DISABLE;
        end else begin
            ram_data_out = `ZERO;
            ram_write_request_out = mem_we_in;
            ram_addr_out = mem_addr_in; // bug is there
            ram_ce_out = `CHIP_ENABLE;
            case (mem_op_in)
                `LB: begin
                    case (ram_addr_offset)
                        2'b00:begin
                            reg_wdata_out = {{24{ram_data_in[7]}},ram_data_in[7:0]};
                        end 
                        2'b01:begin
                            reg_wdata_out = {{24{ram_data_in[15]}},ram_data_in[15:8]};
                        end
                        2'b10:begin
                            reg_wdata_out = {{24{ram_data_in[23]}},ram_data_in[23:16]}; 
                        end
                        default:begin
                            reg_wdata_out = {{24{ram_data_in[31]}},ram_data_in[31:24]};
                        end
                    endcase
                end
                `LBU:begin
                    case (ram_addr_offset)
                        2'b00:begin
                            reg_wdata_out = {24'h0,ram_data_in[7:0]};
                        end
                        2'b01:begin
                            reg_wdata_out = {24'h0,ram_data_in[15:8]};
                        end
                        2'b10:begin
                            reg_wdata_out = {24'h0,ram_data_in[23:16]};
                        end
                        default:begin
                            reg_wdata_out = {24'h0,ram_data_in[31:24]};
                        end 
                    endcase
                end
                `LH:begin
                    if(ram_addr_offset == 2'b00)begin
                        reg_wdata_out = {{16{ram_data_in[15]}},ram_data_in[15:0]};
                    end else begin
                        reg_wdata_out = {{16{ram_data_in[31]}},ram_data_in[31:16]};
                    end
                end
                `LHU:begin
                    if(ram_addr_offset == 2'b00)begin
                        reg_wdata_out = {16'h0,ram_data_in[15:0]};
                    end else begin
                        reg_wdata_out = {16'h0,ram_data_in[31:16]};
                    end
                end
                `LW:begin
                    reg_wdata_out = ram_data_in;
                end
                `SB: begin //mem_data lowest [7:0]
                    case (ram_addr_offset)
                        2'b00:begin //ram讀出來的data會和在exe中計算好的op2也就是mem_data做結合然後在存回去
                            ram_data_out = {ram_data_in[31:8],mem_data_in[7:0]};
                        end 
                        2'b01:begin
                            ram_data_out = {ram_data_in[31:16],mem_data_in[7:0],ram_data_in[7:0]};
                        end
                        2'b10:begin
                            ram_data_out = {ram_data_in[31:24],mem_data_in[7:0],ram_data_in[15:0]}; 
                        end
                        default:begin
                            ram_data_out = {mem_data_in[7:0],ram_data_in[23:0]};
                        end
                    endcase
                end
                `SH:begin
                    if (ram_addr_offset == 2'b00) begin
                        ram_data_out = {ram_data_in[31:16],mem_data_in[15:0]};
                    end else begin
                        ram_data_out = {mem_data_in[15:0],ram_data_in[15:0]};
                    end
                end
                `SW:begin
                    ram_data_out = mem_data_in;
                end
                default: begin
                    ram_addr_out = `ZERO;
                    ram_data_out = `ZERO;
                    ram_write_request_out = `WRITE_DISABLE;
                    ram_ce_out = `CHIP_DISABLE;
                end
            endcase
        end//if
    end
endmodule