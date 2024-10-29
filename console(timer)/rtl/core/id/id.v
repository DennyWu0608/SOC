`include "defines.v"
module id (
    input wire reset_in,

    //form if_id
    input wire [`DATA_WIDTH-1 : 0] inst_in,
    input wire [`ADDR_WIDTH-1 : 0] inst_addr_in,

    //from id_exe
    input wire[`RADDR_WIDTH-1:0] exe_rd_in,
    input wire pre_inst_is_load_in,

    //form regfile
    input wire [`RDATA_WIDTH-1 : 0] rdata1_in,
    input wire [`RDATA_WIDTH-1 : 0] rdata2_in,

    //form exe to solve data hazard
    input wire [`RADDR_WIDTH-1 : 0] exe_reg_waddr_in,
    input wire [`RDATA_WIDTH-1 : 0] exe_reg_wdata_in,
    input wire exe_reg_we_in,

    //form mem to solve data hazard
    input wire [`RADDR_WIDTH-1 : 0] mem_reg_waddr_in,
    input wire [`RDATA_WIDTH-1 : 0] mem_reg_wdata_in,
    input wire mem_reg_we_in,

    //to regfile
    output reg [`RADDR_WIDTH-1 : 0] reg1_raddr_out,
    output reg [`RADDR_WIDTH-1 : 0] reg2_raddr_out,
    output reg reg1_renable_out,
    output reg reg2_renable_out,

    //to id_exe
    output reg[`DATA_WIDTH-1:0] inst_out,
    output reg[`ADDR_WIDTH-1:0] inst_address_out,
    output reg[`RDATA_WIDTH-1:0] op1_out,
    output reg[`RDATA_WIDTH-1:0] op2_out,
    output reg reg_we_out,
    output reg[`RADDR_WIDTH-1:0] reg_waddr_out,
    
    //to ctrl
    output reg stallreq_out
);

assign inst_address_out = inst_addr_in;

reg [`RDATA_WIDTH-1:0] op1_out_final;
reg [`RDATA_WIDTH-1:0] op2_out_final;
wire [6:0] opcode = inst_in[6:0];
wire [4:0] rd = inst_in[11:7];
//for type s & type l
wire [4:0] rs1 = inst_in[19:15];
wire [4:0] rs2 = inst_in[24:20];

wire [`RADDR_WIDTH-1:0] i_reg1_raddr_out;
wire [`RADDR_WIDTH-1:0] i_reg2_raddr_out;
wire i_reg1_renable_out;
wire i_reg2_renable_out;
wire [`RDATA_WIDTH-1:0] i_op1_out;
wire [`RDATA_WIDTH-1:0] i_op2_out;
wire [`RADDR_WIDTH-1:0] i_reg_waddr_out;
wire i_reg_we_out;

    id_type_i id_type_i0(
        .inst_in(inst_in),
        .reg1_rdata_in(rdata1_in),
        .reg2_rdata_in(rdata2_in),
        .reg1_raddr_out(i_reg1_raddr_out),
        .reg2_raddr_out(i_reg2_raddr_out),
        .reg1_renable_out(i_reg1_renable_out),
        .reg2_renable_out(i_reg2_renable_out),
        .op1_out(i_op1_out),
        .op2_out(i_op2_out),
        .reg_waddr_out(i_reg_waddr_out),
        .reg_wenable_out(i_reg_we_out)
    );

wire [`RADDR_WIDTH-1:0] r_reg1_raddr_out;
wire [`RADDR_WIDTH-1:0] r_reg2_raddr_out;
wire r_reg1_renable_out;
wire r_reg2_renable_out;
wire [`RDATA_WIDTH-1:0] r_op1_out;
wire [`RDATA_WIDTH-1:0] r_op2_out;
wire [`RADDR_WIDTH-1:0] r_reg_waddr_out;
wire r_reg_we_out;

    id_type_r id_type_r0(
        .inst_in(inst_in),
        .reg1_rdata_in(rdata1_in),
        .reg2_rdata_in(rdata2_in),
        .reg1_raddr_out(r_reg1_raddr_out),
        .reg2_raddr_out(r_reg2_raddr_out),
        .reg1_renable_out(r_reg1_renable_out),
        .reg2_renable_out(r_reg2_renable_out),
        .op1_out(r_op1_out),
        .op2_out(r_op2_out),
        .reg_waddr_out(r_reg_waddr_out),
        .reg_wenable_out(r_reg_we_out)
    );

wire is_load_hazard;
assign is_load_hazard = (pre_inst_is_load_in==1'b1 && (rs1 == exe_rd_in || rs2 == exe_rd_in)); // 如果現在指令的rd圍下一個指令的rs1 or rs2以及現在指令是l就需要做stall
    
    always@(*)begin
        if (is_load_hazard)
            stallreq_out = 1'b1;
        else
            stallreq_out = 1'b0;
    end

    always @(*) begin
        if(reset_in == 1)begin
            inst_out = `NOP;
            reg1_raddr_out = `ZERO_REG;
            reg2_raddr_out = `ZERO_REG;
            reg1_renable_out = `READ_DISABLE;
            reg2_renable_out = `READ_DISABLE;
            op1_out = `ZERO;
            op2_out = `ZERO;
            reg_waddr_out = `ZERO_REG;
            reg_we_out = `WRITE_DISABLE;
        end else begin
            case (opcode)
                `INST_TYPE_I:begin
                    inst_out = inst_in;
                    reg1_raddr_out = i_reg1_raddr_out;
                    reg2_raddr_out = i_reg2_raddr_out;
                    reg1_renable_out = i_reg1_renable_out;
                    reg2_renable_out = i_reg2_renable_out;
                    op1_out_final = i_op1_out;
                    op2_out_final = i_op2_out;
                    reg_waddr_out = i_reg_waddr_out;
                    reg_we_out = i_reg_we_out;
                end
                `INST_TYPE_R_M:begin
                    inst_out = inst_in;
                    reg1_raddr_out = r_reg1_raddr_out;
                    reg2_raddr_out = r_reg2_raddr_out;
                    reg1_renable_out = r_reg1_renable_out;
                    reg2_renable_out = r_reg2_renable_out;
                    op1_out_final = r_op1_out;
                    op2_out_final = r_op2_out;
                    reg_waddr_out = r_reg_waddr_out;
                    reg_we_out = r_reg_we_out;
                end
                `INST_TYPE_U_LUI:begin
                    inst_out = inst_in;
                    reg1_raddr_out = `ZERO_REG;
                    reg1_renable_out = `READ_DISABLE;
                    reg2_raddr_out = `ZERO_REG;
                    reg2_renable_out = `READ_DISABLE;
                    op1_out_final = {inst_in[31:12],{12{1'b0}}};
                    op2_out_final = {32{1'b0}};
                    reg_waddr_out = rd;
                    reg_we_out = `WRITE_ENABLE;
                end
                `INST_TYPE_U_AUIPC:begin
                    inst_out = inst_in;
                    reg1_raddr_out = `ZERO_REG;
                    reg1_renable_out = `READ_DISABLE;
                    reg2_raddr_out = `ZERO_REG;
                    reg2_renable_out = `READ_DISABLE;
                    op1_out_final = inst_addr_in;
                    op2_out_final = {inst_in[31:12],{12{1'b0}}};
                    reg_waddr_out = rd;
                    reg_we_out = `WRITE_ENABLE;
                end
                `INST_TYPE_S:begin
                    inst_out = inst_in;
                    reg1_raddr_out = rs1;
                    reg1_renable_out = `READ_ENABLE;
                    reg2_raddr_out = rs2;
                    reg2_renable_out = `READ_ENABLE;
                    op1_out_final = rdata1_in;//透過inst中的rs1位址讀出其位址的值
                    op2_out_final = rdata2_in;
                    reg_waddr_out = `ZERO_REG;
                    reg_we_out = `WRITE_DISABLE;
                end
                `INST_TYPE_L:begin
                    inst_out = inst_in;
                    reg1_raddr_out = rs1;
                    reg1_renable_out = `READ_ENABLE;
                    reg2_raddr_out = rs2;
                    reg2_renable_out = `READ_DISABLE;
                    op1_out_final = rdata1_in;//透過inst中的rs1位址讀出其位址的值
                    op2_out_final = `ZERO;
                    reg_waddr_out = rd;
                    reg_we_out = `WRITE_ENABLE;
                end
                `INST_TYPE_JAL:begin
                    inst_out = inst_in;
                    reg1_raddr_out = `ZERO_REG;
                    reg1_renable_out = `READ_DISABLE;
                    reg2_raddr_out = rs2;
                    reg2_renable_out = `READ_DISABLE;
                    op1_out_final = `ZERO;
                    op2_out_final = `ZERO;
                    reg_waddr_out = rd;
                    reg_we_out = `WRITE_ENABLE;
                end
                `INST_TYPE_JALR:begin //"jump = rs1+imm" so we need the rs1 value
                    inst_out = inst_in;
                    reg1_raddr_out = rs1;
                    reg1_renable_out = `READ_ENABLE;
                    reg2_raddr_out = rs2;
                    reg2_renable_out = `READ_DISABLE;
                    op1_out_final = rdata1_in;
                    op2_out_final = `ZERO;
                    reg_waddr_out = rd;
                    reg_we_out = `WRITE_ENABLE;
                end
                `INST_TYPE_B: begin
                    inst_out = inst_in;
                    reg1_raddr_out = rs1;
                    reg1_renable_out = `READ_ENABLE;
                    reg2_raddr_out = rs2;
                    reg2_renable_out = `READ_ENABLE;
                    op1_out_final = rdata1_in;
                    op2_out_final = rdata2_in;
                    reg_waddr_out = `ZERO_REG; // rd 不用寫？ 在b type指令中的確不用管rd 因為會拿來被擴充
                    reg_we_out = `WRITE_DISABLE;
                end
                default:begin
                    inst_out = `NOP;
                    reg1_raddr_out = `ZERO_REG;
                    reg2_raddr_out = `ZERO_REG;
                    reg1_renable_out = `READ_DISABLE;
                    reg2_renable_out = `READ_DISABLE;
                    op1_out = `ZERO;
                    op2_out = `ZERO;
                    reg_waddr_out = `ZERO_REG;
                    reg_we_out = `WRITE_DISABLE;
                end
            endcase
        end
    end

    //determine op1_out
    always @(*) begin
        if (reg1_renable_out == `READ_ENABLE && exe_reg_we_in == `WRITE_ENABLE && exe_reg_waddr_in == reg1_raddr_out )begin
            op1_out = (|reg1_raddr_out)? exe_reg_wdata_in:`ZERO;        
        end else if (mem_reg_waddr_in == reg1_raddr_out && reg1_renable_out == `READ_ENABLE && mem_reg_we_in == `WRITE_ENABLE)begin
            op1_out = (|reg1_raddr_out)? mem_reg_wdata_in:`ZERO; 
        end else begin
            op1_out = op1_out_final;
        end
    end

    //determine op2_out
    always @(*) begin
        if (reg2_renable_out == `READ_ENABLE && exe_reg_we_in == `WRITE_ENABLE && exe_reg_waddr_in == reg2_raddr_out)begin
            op2_out = (|reg2_raddr_out)? exe_reg_wdata_in:`ZERO;         
        end else if (mem_reg_waddr_in == reg2_raddr_out && reg2_renable_out == `READ_ENABLE && mem_reg_we_in == `WRITE_ENABLE)begin
            op2_out = (|reg2_raddr_out)? mem_reg_wdata_in:`ZERO;  
        end else begin
            op2_out = op2_out_final;
        end
    end
endmodule