`include "defines.v"
module exe_b_j_type(
    input wire reset_in,
    input wire [`DATA_WIDTH-1:0] inst_in,
    input wire [`ADDR_WIDTH-1:0] inst_address_in,
    input wire [`DATA_WIDTH-1:0] op1_in,
    input wire [`DATA_WIDTH-1:0] op2_in,
    
    output reg [`ADDR_WIDTH-1:0] jump_address_out,
    output reg jump_enable_out
    );

    //judge b
    wire [2:0]funct3;
    wire [6:0] opcode;
    assign opcode = inst_in[6:0];
    assign funct3 = inst_in[14:12];
    //main job is dealing with imm + pc
    wire [`DATA_WIDTH-1:0] pc;
    assign pc = inst_address_in;
    wire [`ADDR_WIDTH-1:0] j_imm;
    assign j_imm = {{12{inst_in[31]}}, inst_in[19:12],inst_in[20],inst_in[30:21],1'b0};
    wire [`ADDR_WIDTH-1:0] jalr_imm;
    assign jalr_imm = {{20{inst_in[31]}}, inst_in[31:20]};
    wire [`ADDR_WIDTH-1:0] b_imm;
    assign b_imm = {{{20{inst_in[31]}}, inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0}};

    always @(*) begin
        if (reset_in == 1) begin
            jump_address_out = `ZERO;
            jump_enable_out = 1'b0;
        end else begin
            case (opcode)
            `INST_TYPE_JAL: begin
                jump_address_out = pc + j_imm; //get the pc_address
                jump_enable_out = 1'b1;
            end
            `INST_TYPE_JALR: begin
                jump_address_out = jalr_imm; //doesn't plus the pc_address
                jump_enable_out = 1'b1;
            end
            `INST_TYPE_B: begin
            case (funct3)
                `INST_BEQ:begin
                        jump_address_out = pc + b_imm; //pc + address
                    if (op1_in == op2_in) begin
                        jump_enable_out = 1'b1;
                    end else begin
                        jump_enable_out = 1'b0;
                    end
                end
                `INST_BNE:begin
                    jump_address_out = pc + b_imm;
                    if (op1_in != op2_in) begin
                        jump_enable_out = 1'b1;
                    end else begin
                        jump_enable_out = 1'b0;
                    end
                end
                `INST_BLT:begin
                    jump_address_out = pc + b_imm;
                    if ($signed(op1_in) < $signed(op2_in)) begin
                        jump_enable_out = 1'b1;
                    end else begin
                        jump_enable_out = 1'b0;
                    end
                end
                `INST_BGE:begin
                    jump_address_out = pc + b_imm;
                    if ($signed(op1_in) >= $signed(op2_in)) begin
                        jump_enable_out = 1'b1;
                    end else begin
                        jump_enable_out = 1'b0;
                    end
                end
                `INST_BLTU:begin
                    jump_address_out = pc + b_imm;
                    if (op1_in < op2_in) begin
                        jump_enable_out = 1'b1;
                    end else begin
                        jump_enable_out = 1'b0;
                    end 
                end
                `INST_BGEU:begin
                    jump_address_out = pc + b_imm;
                    if (op1_in >= op2_in) begin
                        jump_enable_out = 1'b1;
                    end else begin
                        jump_enable_out = 1'b0;
                    end
                end
                default: begin
                    jump_address_out = `ZERO;
                    jump_enable_out = 1'b0;
                end
            endcase
            end
            default: begin
                jump_address_out = `ZERO;
                jump_enable_out = 1'b0;
            end
            endcase
        end //if
    end //always
endmodule