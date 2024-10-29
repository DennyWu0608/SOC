`include "defines.v"
module exe_s_l_type (
    input wire reset_in,

    input wire [`RDATA_WIDTH-1:0]inst_in,
    input wire [`DATA_WIDTH-1:0]op1_in,
    input wire [`DATA_WIDTH-1:0]op2_in,
    
    output reg [`RDATA_WIDTH-1:0]reg_wdata_out,
    output reg reg_we_out,
    output reg [`ADDR_WIDTH-1:0] mem_addr_out,
    output reg [`DATA_WIDTH-1:0] mem_data_out,
    output reg mem_we_out,
    output reg [3:0] mem_op_out
);

wire [6:0] opcode  = inst_in[6:0];
wire [2:0] funct3 = inst_in[14:12];
//wire [6:0] funct7 = inst_in[31:25];

wire[`ADDR_WIDTH-1:0] load_addr;
wire[`ADDR_WIDTH-1:0] store_addr;
assign store_addr = {{20{inst_in[31]}}, inst_in[31:25], inst_in[11:7]};
assign load_addr = {{20{inst_in[31]}}, inst_in[31:20]};

always @(*) begin
    if (reset_in == 1) begin
        reg_wdata_out = `ZERO;
        reg_we_out = `WRITE_DISABLE;
        mem_addr_out = `ZERO;
        mem_data_out = `ZERO;
        mem_op_out = `MEM_NOP;
        mem_we_out = `WRITE_DISABLE;
    end else begin
        case(opcode)
        `INST_TYPE_S:begin
            reg_wdata_out = `ZERO;
            reg_we_out = `WRITE_DISABLE;
            mem_addr_out = $signed(op1_in)+$signed(store_addr);
            mem_data_out = op2_in;
            mem_we_out = `WRITE_ENABLE;
            case (funct3)
            `INST_SB:begin
                mem_op_out = `SB;
            end
            `INST_SW:begin
                mem_op_out = `SW;
            end
            `INST_SH:begin
                mem_op_out = `SH;
            end 
            default:
                mem_op_out = `MEM_NOP;
            endcase
        end
        `INST_TYPE_L:begin
            reg_wdata_out = `ZERO;
            reg_we_out = `WRITE_ENABLE;
            mem_addr_out = $signed(op1_in) + $signed(load_addr);
            mem_data_out = `ZERO;
            mem_we_out = `WRITE_DISABLE;
            case (funct3)
                `INST_LB:begin
                    mem_op_out = `LB;
                end
                `INST_LBU:begin
                    mem_op_out = `LBU;
                end
                `INST_LH:begin
                    mem_op_out = `LH;
                end
                `INST_LHU:begin
                    mem_op_out = `LHU;
                end
                `INST_LW:begin
                    mem_op_out = `LW;
                end
                default:
                    mem_op_out = `MEM_NOP; 
            endcase
        end
        default:begin
            reg_wdata_out = `ZERO;
            reg_we_out = `WRITE_DISABLE;
            mem_addr_out = `ZERO;
            mem_data_out = `ZERO;
            mem_op_out = `MEM_NOP;
            mem_we_out = `WRITE_DISABLE;
        end
        endcase
    end
end
endmodule