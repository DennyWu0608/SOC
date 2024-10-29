`include "defines.v"
module exe_i_type (
    input wire reset_in,

    input wire [`RDATA_WIDTH-1:0]inst_in,
    input wire [`DATA_WIDTH-1:0]op1_in,
    input wire [`DATA_WIDTH-1:0]op2_in,
    
    output reg [`RDATA_WIDTH-1:0]reg_wdata_out,
    output reg reg_we_out
);

wire [6:0] opcode  = inst_in[6:0];
wire [2:0] funct3 = inst_in[14:12];
wire [6:0] funct7 = inst_in[31:25];

wire[31:0] sr_shift;
wire[31:0] sr_shift_mask;
assign sr_shift = op1_in >> op2_in[4:0];
assign sr_shift_mask = 32'hffffffff >> op2_in[4:0];

wire isType_i;
assign isType_i = (opcode == `INST_TYPE_I);

always @(*) begin
    if (reset_in == 1 || isType_i == 0) begin
        reg_wdata_out = `ZERO;
        reg_we_out = `WRITE_DISABLE;
    end else begin
        if(opcode == `INST_TYPE_I)begin
           case (funct3)
            `INST_ADDI:begin
                reg_wdata_out = $signed(op1_in) + $signed(op2_in);
                reg_we_out = `WRITE_ENABLE;
            end //ADDI
            `INST_ORI:begin
                reg_wdata_out = op1_in | op2_in;
                reg_we_out = `WRITE_ENABLE;
            end//ORI
            `INST_ANDI:begin
                reg_wdata_out = op1_in & op2_in;
                reg_we_out = `WRITE_ENABLE;
            end//ANDI
            `INST_XORI:begin
                reg_wdata_out = op1_in ^ op2_in;
                reg_we_out = `WRITE_ENABLE;
            end//XORI
            `INST_SLTI:begin
                reg_we_out = `WRITE_ENABLE;
                if ($signed (op1_in) >= $signed (op2_in)) begin
                    reg_wdata_out = 32'h0;
                end else begin
                    reg_wdata_out = 32'h1;
                end
            end//SLTI
            `INST_SLTIU:begin
                reg_we_out = `WRITE_ENABLE;
                if (op1_in >= op2_in) begin
                    reg_wdata_out = 32'h0;
                end else begin
                    reg_wdata_out = 32'h1;
                end
            end//SLTIU
            `INST_SLLI:begin
                if(funct7 == 7'b0000000) begin
                    reg_wdata_out = op1_in << op2_in;
                    reg_we_out = `WRITE_ENABLE;
                end else begin
                    reg_wdata_out = 0;
                    reg_we_out = `WRITE_DISABLE;
                end
            end//SLLI
            `INST_SRAI:begin
                if(funct7 == 7'b0100000)begin
                   reg_wdata_out = sr_shift | ({32{op1_in[31]}} & (~sr_shift_mask)); // why need to and ??
                   reg_we_out = `WRITE_ENABLE;
                end else if (funct7 == 7'b0000000)begin
                    reg_wdata_out = op1_in >> op2_in;
                    reg_we_out = `WRITE_ENABLE;
                end else begin
                    reg_wdata_out = `ZERO;
                    reg_we_out = `WRITE_DISABLE;
                end
            end//SRLI SRAI
            default:begin
                reg_wdata_out = `ZERO;
                reg_we_out = `WRITE_DISABLE;
            end 
           endcase 
        end else begin
            reg_wdata_out = `ZERO;
            reg_we_out = `WRITE_DISABLE;
        end
    end
end
endmodule