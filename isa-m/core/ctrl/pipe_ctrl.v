module pipe_ctrl(

    input wire reset_in,
    //input wire  stallreq_from_if_i,  //waiting ROM delay
    input wire  stallreq_from_id_in,  //load hazard 
    input wire [`ADDR_WIDTH-1:0] exe_jump_address_in,
    input wire exe_jump_enable_in, // jump hazard
    input wire stallreq_from_exe_in, // mul, div stall hazard
    
    /* ---signals to other stages of the pipeline  ----*/
    output reg[5:0] stall_out,  // stall request to PC,IF_ID, ID_EX, EX_MEM, MEM_WB， one bit for one stage respectively
    output reg flush_jump_out,
    output reg[`ADDR_WIDTH-1:0] new_pc_out
    );

    assign flush_jump_out = exe_jump_enable_in;
    //pc_reg,if_id, id_exe
    assign new_pc_out = exe_jump_address_in;
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
