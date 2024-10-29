`include "defines.v"
module exe_m_type (
    input wire clk_in,input wire reset_in,
    input wire [`DATA_WIDTH-1 : 0] inst_in,
    input wire [`DATA_WIDTH-1 : 0] op1_in,
    input wire [`DATA_WIDTH-1 : 0] op2_in,

    output reg stall_out,
    output reg [`RDATA_WIDTH-1 : 0] reg_wdata_out,
    output reg reg_we_out
);
    wire [6:0] opcode = inst_in [6:0];
    wire [2:0] funct3 = inst_in [14:12];
    wire [6:0] funct7 = inst_in [31:25];

    wire is_m_type;// 因為是邏輯電路會同時運作R 和 M 會同時判斷
    assign is_m_type = (opcode == `INST_TYPE_R_M && funct7 == 7'b0000001);


    reg [`DATA_WIDTH-1 : 0] exe_to_a; //for op1_in to mul.a_in
    reg [`DATA_WIDTH-1 : 0] exe_to_b;
    reg mul_req_out, div_req_out; 
    reg mul_ready_in, div_ready_in;
    reg [`DATA_WIDTH*2 - 1 : 0] mul_answer; // 32bit
    reg [`DATA_WIDTH - 1 : 0] div_answer;

    mul#(.XLEN(`DATA_WIDTH)) mul0(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .a_in(exe_to_a),
        .b_in(exe_to_b),
        .req_in(mul_req_out),
        .ready_out(mul_ready_in),//check that the operation finish or not
        .result_out(mul_answer) // 64bit
    );

    div#(.XLEN(`DATA_WIDTH)) div0(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .dividend(exe_to_a),
        .divitor(exe_to_b),
        .req_in(div_req_out),
        .is_q_in(is_q),
        .ready_out(div_ready_in),//check that the operation finish or not
        .result_out(div_answer) // 64bit
    );

    assign stall_out = (mul_req_out & ~mul_ready_in)|(div_req_out & ~div_ready_in); //|(div_req_o & ~div_ready_i);    
    reg[`DATA_WIDTH-1:0] result;//the last answer which will store in reg

    //judge the value that the answer is positive or is negative 
    wire a_neg = op1_in[`DATA_WIDTH-1];
    wire b_neg = op2_in[`DATA_WIDTH-1];
    wire adjust = a_neg ^ b_neg; // 1 xor 1 => 0 / 1 xor 0 => 1 

    reg[`DATA_WIDTH*2-1:0] invert_result;
    reg[`DATA_WIDTH-1:0] div_invert_result;
    //if a is the value we output form mul and then invert_result will be the value that -a
    assign invert_result = (mul_req_out)? ~mul_answer + 1 : 64'b0;
    assign div_invert_result = (div_req_out)? ~div_answer + 1 : 32'b0;
    
    //lock the wrong ans
    assign reg_wdata_out = {32{mul_ready_in | div_ready_in}} & result;

    //for 餘數
    reg is_q;
    
    always @(*) begin
        if(reset_in | ~is_m_type)begin
            reg_wdata_out = `ZERO;
            reg_we_out = `WRITE_DISABLE;
            mul_req_out = 1'b0;
            div_req_out = 1'b0;
            result = 32'h0;
        end else begin
            exe_to_a = `ZERO;
            exe_to_b = `ZERO;
            mul_req_out = 1'b0;
            div_req_out = 1'b0;
            result = 32'h0;
            reg_we_out = `WRITE_ENABLE;
            case (funct3)
                `INST_MUL: begin
                    exe_to_a = op1_in;
                    exe_to_b = op2_in;
                    mul_req_out = 1'b1;
                    div_req_out = 1'b0;
                    result = mul_answer[31:0];
                end 
                `INST_MULH: begin //  全部都轉成正數最後去看是不是一正一負
                    exe_to_a = (a_neg)? ~op1_in+1 : op1_in; // 如果是複數的話直接反邏輯然後加1變成正數
                    exe_to_b = (b_neg)? ~op2_in+1 : op2_in;
                    mul_req_out = 1'b1;
                    div_req_out = 1'b0;
                    result = (adjust)? invert_result[`DATA_WIDTH*2-1 : `DATA_WIDTH] : mul_answer[`DATA_WIDTH*2-1 : `DATA_WIDTH]; 
                end
                `INST_MULHU: begin
                    exe_to_a = op1_in;
                    exe_to_b = op2_in;
                    mul_req_out = 1'b1;
                    div_req_out = 1'b0;
                    result = mul_answer[`DATA_WIDTH*2-1 : `DATA_WIDTH];
                end
                `INST_MULHSU: begin
                    exe_to_a = (a_neg)? ~op1_in+1 : op1_in;
                    exe_to_b = op2_in;
                    mul_req_out = 1'b1;
                    div_req_out = 1'b0;
                    result = (a_neg)? invert_result[`DATA_WIDTH*2-1 : `DATA_WIDTH] : mul_answer[`DATA_WIDTH*2-1 : `DATA_WIDTH];
                end
                `INST_DIV: begin
                    exe_to_a = (a_neg)? ~op1_in+1 : op1_in;
                    exe_to_b = (b_neg)? ~op2_in+1 : op2_in;
                    div_req_out = 1'b1;
                    mul_req_out = 1'b0;
                    if(exe_to_b == 1'b0)begin
                        result = div_answer;
                    end else begin
                        result = (adjust)? div_invert_result: div_answer; 
                    end
                end
                `INST_DIVU: begin
                    exe_to_a = op1_in;
                    exe_to_b = op2_in;
                    div_req_out = 1'b1;
                    mul_req_out = 1'b0;
                    result = div_answer;
                end
                `INST_REM: begin
                    exe_to_a = (a_neg)? ~op1_in+1 : op1_in;
                    exe_to_b = (b_neg)? ~op2_in+1 : op2_in;
                    div_req_out = 1'b1;
                    mul_req_out = 1'b0;
                    is_q = 1'b1;
                    // result = (adjust)? div_invert_result: div_answer;
                    if ((~a_neg && ~b_neg) || (~a_neg && b_neg)) begin//+%+ && +%- ==> +
                        result = div_answer;
                    end else if ((a_neg && ~b_neg)||(a_neg && b_neg)) begin//-%+ && -%- ==> -
                        result = div_invert_result;
                    end
                end
                `INST_REMU: begin
                    exe_to_a = op1_in;
                    exe_to_b = op2_in;
                    div_req_out = 1'b1;
                    mul_req_out = 1'b0;
                    is_q = 1'b1;
                    result = div_answer;
                end
                default: begin
                    exe_to_a = `ZERO;
                    exe_to_b = `ZERO;
                    mul_req_out = 1'b0;
                    div_req_out = 1'b0;
                    result = 32'h0;
                    reg_we_out = `WRITE_DISABLE;
                end
            endcase
        end
    end
endmodule