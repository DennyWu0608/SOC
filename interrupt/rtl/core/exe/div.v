module div#(parameter XLEN = 32)
(
    input wire              clk_in,
    input wire              reset_in,
    input wire[XLEN-1 : 0]  dividend, //被除數
    input wire[XLEN-1 : 0]  divitor, //除數
    input wire              req_in,
    input wire              is_q_in,
    output reg             ready_out,
    output reg[XLEN-1 : 0]  result_out
    // output reg DBZ??
);

//先處理dividend 和 divitor 是零的一些問題
//有三種情況：
//1. 0 / 0 ＝ 無定義 2. 1 / 0 ＝ 無定義 3. 0 / 1 ＝ 0 由此可知我們的divitor出現0時 我們會有exception(就是中斷吧?) ＝＝> DBZ（Divison-by-Zero）
wire is_dividend_zero, is_divitor_zero;

assign is_dividend_zero = (dividend == 32'b0); 
assign is_divitor_zero = (divitor == 32'b0);

wire [XLEN-1 : 0] op_dividend, op_divitor;

assign op_dividend = dividend;
assign op_divitor = divitor;

wire              is_calc_done;
reg  [XLEN-1 : 0] reg32;
reg  [XLEN*2 : 0] result;       // 65-bit, 1 extra bit
reg  [ 5 : 0]     cnt;          // counter

// For the slow shift-add binary multiplier.
assign is_calc_done = (cnt == 0); 

// ================================================================================
// Finite State Machine
//
localparam           S_IDLE        = 3'b000;
localparam           S_CALC        = 3'b001;
localparam           S_DONE        = 3'b011;
reg [2 : 0] S, S_nxt;

always @(posedge clk_in)
begin
    if (reset_in|~req_in)
        S <= S_IDLE;
    else
        S <= S_nxt;
end

always @(*)
begin
    case (S)
        S_IDLE:
            S_nxt = (req_in)? (is_dividend_zero | is_divitor_zero)? S_DONE : S_CALC : S_IDLE;
        S_CALC:
            S_nxt = (is_calc_done)? S_DONE : S_CALC;
        S_DONE:
            S_nxt = S_IDLE;
        default:
            S_nxt = S_IDLE;
    endcase
end

// ================================================================================
// Computation
//
// wire div_sub = result[0];
wire [XLEN-1 : 0] sub_divitor, sub_dividend;
assign sub_divitor = reg32;
assign sub_dividend = result[XLEN*2-1: XLEN];

wire  dividend_big_than_divitor = (sub_dividend >= sub_divitor);

wire [XLEN : 0] sub_tmp;
assign sub_tmp = sub_dividend - sub_divitor;

wire [XLEN*2 : 0] result_tmp = {sub_tmp, result[31: 0]}; //answer +1  65bits


// reg [XLEN-1 : 0] quotient = result[XLEN-1 : 0];
// reg [XLEN-1 : 0] remainder = result [XLEN*2 : XLEN + 1];
always @(posedge clk_in)
begin
    if ((S == S_IDLE) && (req_in==1'b1))
    begin
      if (is_divitor_zero)
      begin
            result[64: 33] <= dividend;
            result[32]  <= 1'b0;
            result[31: 0] <= {32{1'b1}};
      end
      else
      begin
            cnt <= 'd32;
            reg32 <= op_divitor;
            result <= {1'b0 , 32'b0 , op_dividend};
          //reg32 <= op_a;
          //result <= {1'b0, 32'b0, op_b}; 
      end
    end
    else if (S == S_CALC)
    begin
        cnt <= cnt - 'd1;
        // slow multiplier: shift right
        result <= (dividend_big_than_divitor)? {result_tmp[XLEN*2 - 1: 0], 1'b1} : {result[XLEN*2 - 1: 0], 1'b0};
    end
end

// ================================================================================
// Output signals
//
always @(posedge clk_in)
begin
    if(S == S_DONE)begin
        if (is_q_in == 1'b1) begin
            result_out <= result[XLEN-1:0]; //q
            ready_out <= 1'b1;
        end else begin
            result_out <= result[64:33]; // remainder
            ready_out <= 1'b1;
        end
        
    end else begin
        result_out <= result_out;
        ready_out <= 1'b0;
    end
end

endmodule