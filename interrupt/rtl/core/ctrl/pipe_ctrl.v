module pipe_ctrl(
    input wire clk_in,
    input wire reset_in,

    //input wire  stallreq_from_if_i,  //waiting ROM delay
    input wire  stallreq_from_id_in,  //load hazard 
    input wire exe_jump_enable_in, // jump hazard
    input wire stallreq_from_exe_in, // mul, div stall hazard
    input wire [`ADDR_WIDTH-1:0] exe_jump_address_in,

    //from interrupt
    input wire interrupt_en_in,
    input wire[`ADDR_WIDTH-1:0] isr_pc_in,
    
    //from mem
    input wire [`ADDR_WIDTH-1:0] mem_pc_in,

    //to interrupt
    output reg [`ADDR_WIDTH-1:0] pc_of_epc,

    /* ---signals to other stages of the pipeline  ----*/
    output reg[5:0] stall_out,  // stall request to PC,IF_ID, ID_EX, EX_MEM, MEM_WB， one bit for one stage respectively
    output reg flush_jump_out,
    output reg interrupt_flush_out,
    output reg[`ADDR_WIDTH-1:0] new_pc_out
    );
    
    //pc_reg,if_id, id_exe
    assign flush_jump_out = exe_jump_enable_in;
    assign interrupt_flush_out = interrupt_en_in;
    assign new_pc_out = exe_jump_address_in;

    //judge jump first of interrupt first
    reg [`ADDR_WIDTH-1:0] judge_pc;
    assign pc_of_epc = (|mem_pc_in)? mem_pc_in: judge_pc;

    always @(posedge clk_in) begin
        if (exe_jump_enable_in) begin
            judge_pc <= exe_jump_address_in;
        end else begin
            judge_pc <= judge_pc;
        end
    end

    //to interrupt_ctrl for mepc
    //jump stall one cycle so pc ==> 0 and epc ==> 0

    always @(*) begin
        if(interrupt_en_in) begin
            new_pc_out = isr_pc_in;
        end else if (exe_jump_enable_in) begin //isr
            new_pc_out = exe_jump_address_in;
        end else begin
            new_pc_out = `ZERO;
        end
    end

    
    //to pc_reg
    always @ (*) begin
        if(reset_in == 1'b1) begin
            stall_out = 6'b000000;
        // stall request from exe: stop the PC,IF_ID, ID_EXE, EXE_MEM
        end// stall request from id: stop PC,IF_ID, ID_EXE
        else if(stallreq_from_id_in == `STOP) begin
            stall_out = 6'b000111;
		// stall request from if: stop the PC,IF_ID, ID_EXE
        //end else if(stallreq_from_if_i == `STOP) begin
        //    stall_o = 6'b000111;
        end else if (stallreq_from_exe_in == `STOP) begin
            stall_out = 6'b001111; // stall the stage fo  pc, if_id, id_exe, exe_mem
        end else begin
            stall_out = 6'b000000;
        end // if
    end // always

endmodule
