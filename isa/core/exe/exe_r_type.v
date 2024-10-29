`include "defines.v"
module exe_r_type (
    input wire reset_in,

    input wire [`RDATA_WIDTH-1:0]inst_in,
    input wire [`DATA_WIDTH-1:0]op1_in,
    input wire [`DATA_WIDTH-1:0]op2_in,
    
    output reg [`RDATA_WIDTH-1:0]reg_wdata_out,
    output reg reg_we_out
);

//wire [6:0] opcode  = inst_in[6:0];
wire [2:0] funct3 = inst_in[14:12];
wire [6:0] funct7 = inst_in[31:25];

wire[31:0] sr_shift;
wire[31:0] sr_shift_mask;
assign sr_shift = op1_in >> op2_in[4:0];//向右移動位數
assign sr_shift_mask = 32'hffffffff >> op2_in[4:0];//遮罩 知道移動多少位數？

always @(*) begin
    if (reset_in == 1) begin
        reg_wdata_out = `ZERO;
        reg_we_out = `WRITE_DISABLE;
    end else begin
        case (funct3)
            `INST_ADD_SUB:begin
                if (funct7 == 7'b0000000) begin
                    reg_wdata_out = $signed(op1_in) + $signed(op2_in);
                    reg_we_out = `WRITE_ENABLE;
                end else if (funct7 == 7'b0100000)begin
                    reg_wdata_out = $signed(op1_in) - $signed(op2_in);
                    reg_we_out = `WRITE_ENABLE;
                end else begin
                    reg_wdata_out = `ZERO;
                    reg_we_out = `WRITE_DISABLE;
                end
            end //ADD&SUB
            `INST_OR:begin
                reg_wdata_out = op1_in | op2_in;
                reg_we_out = `WRITE_ENABLE;
            end//OR
            `INST_AND:begin
                reg_wdata_out = op1_in & op2_in;
                reg_we_out = `WRITE_ENABLE;
            end//AND
            `INST_XOR:begin
                reg_wdata_out = op1_in ^ op2_in;
                reg_we_out = `WRITE_ENABLE;
            end//XOR
            `INST_SLT:begin
                reg_we_out = `WRITE_ENABLE;
                if ($signed (op1_in) >= $signed (op2_in)) begin
                    reg_wdata_out = 32'h0;
                end else begin
                    reg_wdata_out = 32'h1;
                end
            end//SLT
            `INST_SLTU:begin
                reg_we_out = `WRITE_ENABLE;
                if (op1_in >= op2_in) begin
                    reg_wdata_out = 32'h0;
                end else begin
                    reg_wdata_out = 32'h1;
                end
            end//SLTU
            `INST_SLL:begin
                reg_wdata_out = op1_in << op2_in[4:0]; //將 rs1 做 shift 運算，再將結果寫入 rd 暫存器，rs2 的最低 5 位為代表位移量。
                reg_we_out = `WRITE_ENABLE;
            end//SLL
            `INST_SRL:begin //srl == sra == 3'b101
                if(funct7 == 7'b0000000)begin //SRL
                    reg_wdata_out = op1_in >> op2_in[4:0]; //將 rs1 做 shift 運算，再將結果寫入 rd 暫存器，rs2 的最低 5 位為代表位移量。
                    reg_we_out = `WRITE_ENABLE;
                end else if(funct7 == 7'b0100000)begin //SRA
                    //reg_wdata_out = op1_in >>> op2_in[4:0];
                    reg_wdata_out = (sr_shift & sr_shift_mask) | ({32{op1_in[31]}} & (~sr_shift_mask)); 
                    reg_we_out = `WRITE_ENABLE;
                end else begin
                    reg_wdata_out = `ZERO;
                    reg_we_out = `WRITE_DISABLE;
                end
            end//SRL&SRA
            default:begin
                reg_wdata_out = `ZERO;
                reg_we_out = `WRITE_DISABLE;
            end 
        endcase 
    end
end
endmodule