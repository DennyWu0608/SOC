`include "defines.v"
module exe_system_type(
    input wire reset_in, 
    input wire [`DATA_WIDTH-1:0] inst_in,
    input wire [`DATA_WIDTH-1:0] op1_in, //rs1
    input wire [`RDATA_WIDTH-1:0] csr_rdata_in,//read data form csrfile
    output reg [`RDATA_WIDTH-1:0] csr_wdata_out,// value for csr which is rs1
    output reg [`RDATA_WIDTH-1:0] reg_wdata_out// value for rd which is csr_rdata
);

wire [2:0] funct3 = inst_in[14:12];
wire [6:0] opcode = inst_in[6:0];

//wire [`RDATA_WIDTH-1:0] t = csr_rdata_in;

wire is_system;
assign is_system = (opcode == `INST_TYPE_SYSTEM);


always @(*) begin
    if (reset_in == 1'b1 || ~is_system)begin
        csr_wdata_out = `ZERO;
        reg_wdata_out = `ZERO;
    end else begin
        case (funct3)
            `INST_CSRRW:begin
                csr_wdata_out = op1_in;
                reg_wdata_out = csr_rdata_in;
            end 
            `INST_CSRRS:begin
                csr_wdata_out = csr_rdata_in | op1_in;
                reg_wdata_out = csr_rdata_in;
            end
            `INST_CSRRC:begin
                csr_wdata_out = csr_rdata_in & (~op1_in);
                reg_wdata_out = csr_rdata_in;
            end
            `INST_CSRRWI:begin
                csr_wdata_out = op1_in;
                reg_wdata_out = csr_rdata_in;
            end
            `INST_CSRRSI:begin
               csr_wdata_out = csr_rdata_in | op1_in; 
               reg_wdata_out = csr_rdata_in;
            end
            `INST_CSRRCI:begin
                csr_wdata_out = csr_rdata_in & (~op1_in);
                reg_wdata_out = csr_rdata_in;
            end
            default:begin
                csr_wdata_out = `ZERO;
                reg_wdata_out = `ZERO;
            end 
        endcase
    end
end

endmodule