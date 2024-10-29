`include "defines.v"
module core_top(
    input wire clk_in,
    input wire reset_in,
    // output reg halt_out,

    //to bus for pc_rom
    output reg  rom_ce_out,
    output reg[`ADDR_WIDTH-1:0] rom_addr_out,
    input  wire[`DATA_WIDTH-1:0] rom_data_in,


    //to bus for mem_ram 
    output reg ram_ce_out,
    output reg[`ADDR_WIDTH-1:0] ram_addr_out,
    output reg[`DATA_WIDTH-1:0] ram_wdata_out,
    input wire[`DATA_WIDTH-1:0] ram_rdata_in,
    output reg ram_we_out
);

assign rom_ce_out = chip_enable_wire;
assign rom_addr_out = pc_wire;
assign if_inst_out = rom_data_in;//if_inst_out => go to if_id

assign ram_ce_out = mem_to_bus_ce_out;
assign ram_addr_out = mem_to_bus_addr_out;
assign ram_wdata_out = mem_to_bus_wdata_out;
assign ram_we_out = mem_to_bus_we_out;
assign bus_to_mem_rdata_out = ram_rdata_in;


//pip_ctrl
wire [5:0] ctrl_stall_out;
wire id_stallreq_out;
wire [`ADDR_WIDTH-1:0] exe_jump_address_out;
wire exe_jump_enable_out;
wire [`ADDR_WIDTH-1:0] ctrl_new_pc_out;
wire ctrl_flush_jump_out;

//for load-use hazard
wire id_exe_inst_is_load_out;
wire[`RADDR_WIDTH-1:0] id_exe_rd_out;


pipe_ctrl ctrl0(
    .reset_in(reset_in),
    //.stallreq_from_if_i(if_stallreq_o), 
    .stallreq_from_id_in(id_stallreq_out),
    .stallreq_from_exe_in(exe_stallreq_out), 
    //jump hazard form exe
    .exe_jump_address_in(exe_jump_address_out),
    .exe_jump_enable_in(exe_jump_enable_out),
    //for jump to flush if_id , id_exe and renew pc
    .flush_jump_out(ctrl_flush_jump_out),
    .new_pc_out(ctrl_new_pc_out),
    .stall_out(ctrl_stall_out)
);
//pc to rom
wire [`ADDR_WIDTH-1:0] pc_wire;
wire chip_enable_wire;

pc_reg pc_reg0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //from pipe_ctrl
    .stall_in(ctrl_stall_out),
    .jump_flush_in(ctrl_flush_jump_out),
    .jump_address_in(ctrl_new_pc_out),
    //to if_id
    .pc_out(pc_wire),
    //to rom
    .chip_enable_out(chip_enable_wire)
);

//instruction port
wire [`DATA_WIDTH-1:0] if_inst_out;
wire [`ADDR_WIDTH-1:0] if_addr_out;


assign if_addr_out = pc_wire;

//if_id to id
wire [`DATA_WIDTH-1:0] if_id_inst_out;
wire [`ADDR_WIDTH-1:0] if_id_addr_out;

if_id if_id0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //from if
    .inst_in(if_inst_out),
    .address_in(if_addr_out),
    //from ctrl
    .stall_in(ctrl_stall_out),
    .jump_flush_in(ctrl_flush_jump_out),
    //to id
    .inst_out(if_id_inst_out),
    .address_out(if_id_addr_out)
);

//regfile to id
wire [`RDATA_WIDTH-1:0] id_rdata1_out;
wire [`RDATA_WIDTH-1:0] id_rdata2_out;
//id to regfile
wire [`RADDR_WIDTH-1:0] id_reg1_addr_out;
wire [`RADDR_WIDTH-1:0] id_reg2_addr_out;
wire id_reg1_re_out;
wire id_reg2_re_out;
//id to id_exe
wire [`DATA_WIDTH-1:0] id_inst_out;
wire [`RDATA_WIDTH-1:0] id_op1_out;
wire [`RDATA_WIDTH-1:0] id_op2_out;
wire [`RADDR_WIDTH-1:0] id_reg_waddr_out;
wire [`ADDR_WIDTH-1:0] id_inst_addr_out;
wire id_reg_we_out;
wire [`CSR_ADDR_WIDTH-1:0] id_csr_addr_out;
wire id_csr_we_out;

id id0(
    .reset_in(reset_in),
    
    //form if_id
    .inst_in(if_id_inst_out),
    .inst_addr_in(if_id_addr_out),
    
    //form regfile
    .rdata1_in(id_rdata1_out),
    .rdata2_in(id_rdata2_out),
    
    //from exe to solve DH
    .exe_reg_waddr_in(exe_reg_waddr_out),
    .exe_reg_wdata_in(exe_reg_wdata_out),
    .exe_reg_we_in(exe_reg_we_out),
    
    //from mem to solve DH
    .mem_reg_waddr_in(mem_reg_waddr_out),
    .mem_reg_wdata_in(mem_reg_wdata_out),
    .mem_reg_we_in(mem_reg_we_out),
    
    //from id_exe for stall
    .pre_inst_is_load_in(id_exe_inst_is_load_out),
    .exe_rd_in(id_exe_rd_out),
    
    //to regfile
    .reg1_raddr_out(id_reg1_addr_out),
    .reg2_raddr_out(id_reg2_addr_out),
    .reg1_renable_out(id_reg1_re_out),
    .reg2_renable_out(id_reg2_re_out),
    
    //to id_exe
    .inst_out(id_inst_out),
    .op1_out(id_op1_out),
    .op2_out(id_op2_out),
    .reg_we_out(id_reg_we_out),
    .reg_waddr_out(id_reg_waddr_out),
    .inst_address_out(id_inst_addr_out),

    //to ctrl
    .stallreq_out(id_stallreq_out),
    
    //csr inst
    .csr_we_out(id_csr_we_out),
    .csr_addr_out(id_csr_addr_out)
);

regfile regfile0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //form WB
    .we_in(mem_wb_reg_we_out),
    .waddr_in(mem_wb_reg_waddr_out),
    .wdata_in(mem_wb_reg_wdata_out),
    //from id read
    .reg1_raddr_in(id_reg1_addr_out),
    .reg2_raddr_in(id_reg2_addr_out),
    .reg1_renable_in(id_reg1_re_out),
    .reg2_renable_in(id_reg2_re_out),
    //to id
    .rdata1_out(id_rdata1_out),
    .rdata2_out(id_rdata2_out)
);

//id_exe to exe
wire [`DATA_WIDTH-1:0] id_exe_inst_out;
wire [`ADDR_WIDTH-1:0] id_exe_inst_addr_out;
wire [`RDATA_WIDTH-1:0] id_exe_op1_out;
wire [`RDATA_WIDTH-1:0] id_exe_op2_out;
wire [`RADDR_WIDTH-1:0] id_exe_reg_waddr_out;
wire id_exe_reg_we_out;
wire [`CSR_ADDR_WIDTH-1:0] id_exe_csr_addr_out;
wire id_exe_csr_we_out;

id_exe id_exe0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //form id
    .inst_in(id_inst_out),
    .inst_address_in(id_inst_addr_out),
    .op1_in(id_op1_out),
    .op2_in(id_op2_out),
    .reg_waddr_in(id_reg_waddr_out),
    .reg_we_in(id_reg_we_out),
    .csr_we_in(id_csr_we_out),
    .csr_addr_in(id_csr_addr_out),

    //from ctrl
    .stall_in(ctrl_stall_out),
    .jump_flush_in(ctrl_flush_jump_out),

    //to ID
    .inst_is_load_out(id_exe_inst_is_load_out),
    .rd_out(id_exe_rd_out),

    //to exe
    .inst_out(id_exe_inst_out),
    .inst_address_out(id_exe_inst_addr_out),
    .op1_out(id_exe_op1_out),
    .op2_out(id_exe_op2_out),
    .reg_waddr_out(id_exe_reg_waddr_out),
    .reg_we_out(id_exe_reg_we_out),
    .csr_we_out(id_exe_csr_we_out),
    .csr_addr_out(id_exe_csr_addr_out)
);

wire [`RDATA_WIDTH-1:0] exe_reg_wdata_out;
wire [`RADDR_WIDTH-1:0] exe_reg_waddr_out;
wire exe_reg_we_out;
wire [`ADDR_WIDTH-1:0] exe_mem_addr_out;
wire [`DATA_WIDTH-1:0] exe_mem_data_out;
wire [3:0] exe_mem_op_out;
wire exe_mem_we_out;
wire exe_stallreq_out;
wire [`CSR_ADDR_WIDTH-1:0] exe_csr_waddr_out;
wire [`RDATA_WIDTH-1:0] exe_csr_wdata_out;
wire exe_csr_we_out;

wire [`RDATA_WIDTH-1:0] exe_csr_addr_out;

//exe
exe exe0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    
    //from exe_id
    .inst_in(id_exe_inst_out),
    .inst_address_in(id_exe_inst_addr_out),
    .op1_in(id_exe_op1_out),
    .op2_in(id_exe_op2_out),
    .reg_waddr_in(id_exe_reg_waddr_out),
    .reg_we_in(id_exe_reg_we_out),
    .csr_we_in(id_exe_csr_we_out),
    .csr_addr_in(id_exe_csr_addr_out),
    
    //from csr_file
    .csr_rdata_in(csr_rdata_out),
    
    //for csr data hazard
    .mem_csr_waddr_in(mem_csr_waddr_out),
    .mem_csr_wdata_in(mem_csr_wdata_out),
    .mem_csr_we_in(mem_csr_we_out),

    //to exe_mem for register
    .reg_wdata_out(exe_reg_wdata_out),
    .reg_waddr_out(exe_reg_waddr_out),
    .reg_we_out(exe_reg_we_out),
    
    //to exe_mem for csr
    .csr_we_out(exe_csr_we_out),
    .csr_wdata_out(exe_csr_wdata_out),
    .csr_waddr_out(exe_csr_waddr_out),
    
    //to exe_mem for mem(ram)
    .mem_addr_out(exe_mem_addr_out),
    .mem_data_out(exe_mem_data_out),
    .mem_we_out(exe_mem_we_out),
    .mem_op_out(exe_mem_op_out),
    
    //to pipe_ctrl for j/b type
    .jump_address_out(exe_jump_address_out),
    .jump_enable_out(exe_jump_enable_out),
    .stall_req_out(exe_stallreq_out),
    
    //to csr_file
    .csr_addr_out(exe_csr_addr_out)
);

//exe_mem wire
wire [`RDATA_WIDTH-1:0] exe_mem_reg_wdata_out;
wire [`RADDR_WIDTH-1:0] exe_mem_reg_waddr_out;
wire exe_mem_reg_we_out;
wire [`ADDR_WIDTH-1:0] exe_mem_mem_addr_out;
wire [`DATA_WIDTH-1:0] exe_mem_mem_data_out;
wire [3:0] exe_mem_mem_op_out;
wire exe_mem_mem_we_out;
wire exe_mem_csr_we_out;
wire [`CSR_ADDR_WIDTH-1:0] exe_mem_csr_waddr_out;
wire [`RDATA_WIDTH-1:0] exe_mem_csr_wdata_out;


exe_mem exe_mem0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //from exe
    .reg_wdata_in(exe_reg_wdata_out),
    .reg_waddr_in(exe_reg_waddr_out),
    .reg_we_in(exe_reg_we_out),
    .mem_addr_in(exe_mem_addr_out),
    .mem_data_in(exe_mem_data_out),
    .mem_we_in(exe_mem_we_out),
    .mem_op_in(exe_mem_op_out),
    .csr_we_in(exe_csr_we_out),
    .csr_wdata_in(exe_csr_wdata_out),
    .csr_waddr_in(exe_csr_waddr_out),

    //from ctrl
    .stall_in(ctrl_stall_out),

    //to mem
    //1.reg
    .reg_wdata_out(exe_mem_reg_wdata_out),
    .reg_waddr_out(exe_mem_reg_waddr_out),
    .reg_we_out(exe_mem_reg_we_out),
    //2.mem
    .mem_addr_out(exe_mem_mem_addr_out),
    .mem_data_out(exe_mem_mem_data_out),
    .mem_we_out(exe_mem_mem_we_out),
    .mem_op_out(exe_mem_mem_op_out),
    //3.csr_rdata_out
    .csr_we_out(exe_mem_csr_we_out),
    .csr_wdata_out(exe_mem_csr_wdata_out),
    .csr_waddr_out(exe_mem_csr_waddr_out)
);

//mem wire
wire [`RDATA_WIDTH-1:0] mem_reg_wdata_out;
wire [`RADDR_WIDTH-1:0] mem_reg_waddr_out;
wire mem_reg_we_out;
//bus to mem
wire [`DATA_WIDTH-1:0] bus_to_mem_rdata_out;
//mem to bus
wire [`ADDR_WIDTH-1:0] mem_to_bus_addr_out;
wire [`DATA_WIDTH-1:0] mem_to_bus_wdata_out;
wire mem_to_bus_we_out;
wire mem_to_bus_ce_out;
//csr by pass
wire mem_csr_we_out;
wire [`CSR_ADDR_WIDTH-1:0] mem_csr_waddr_out;
wire [`RDATA_WIDTH-1:0] mem_csr_wdata_out;


//for isa test
// wire    mem_halt_out;
// assign halt_out = mem_halt_out;

mem mem0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //from exe_mem
    .reg_wdata_in(exe_mem_reg_wdata_out),
    .reg_waddr_in(exe_mem_reg_waddr_out),
    .reg_we_in(exe_mem_reg_we_out),
    .mem_data_in(exe_mem_mem_data_out),
    .mem_addr_in(exe_mem_mem_addr_out),
    .mem_we_in(exe_mem_mem_we_out),
    .mem_op_in(exe_mem_mem_op_out),
    .csr_we_in(exe_mem_csr_we_out),
    .csr_wdata_in(exe_mem_csr_wdata_out),
    .csr_waddr_in(exe_mem_csr_waddr_out),

    //the ram's data form bus
    .ram_data_in(bus_to_mem_rdata_out),
    
    //to bus giving ram
    .ram_addr_out(mem_to_bus_addr_out),
    .ram_data_out(mem_to_bus_wdata_out),
    .ram_write_request_out(mem_to_bus_we_out),
    .ram_ce_out(mem_to_bus_ce_out),

    //to mem_wb
    .reg_wdata_out(mem_reg_wdata_out),
    .reg_waddr_out(mem_reg_waddr_out),
    .reg_we_out(mem_reg_we_out),
    .csr_we_out(mem_csr_we_out),
    .csr_wdata_out(mem_csr_wdata_out),
    .csr_waddr_out(mem_csr_waddr_out)

    //for test halt signal
    // .halt_out(mem_halt_out)
);

//mem_wb wire
wire [`RDATA_WIDTH-1:0] mem_wb_reg_wdata_out;
wire [`RADDR_WIDTH-1:0] mem_wb_reg_waddr_out;
wire mem_wb_reg_we_out;
wire mem_wb_csr_we_out;
wire [`CSR_ADDR_WIDTH-1:0] mem_wb_csr_waddr_out;
wire [`RDATA_WIDTH-1:0] mem_wb_csr_wdata_out;
wire mem_wb_csr_instret_incr_out;

mem_wb mem_wb0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //from mem
    .reg_wdata_in(mem_reg_wdata_out),
    .reg_waddr_in(mem_reg_waddr_out),
    .reg_we_in(mem_reg_we_out),
    .csr_we_in(mem_csr_we_out),
    .csr_wdata_in(mem_csr_wdata_out),
    .csr_waddr_in(mem_csr_waddr_out),


    //from ctrl
    //.stall_in(ctrl_stall_out),

    //to wb which is in regfile
    .reg_wdata_out(mem_wb_reg_wdata_out),
    .reg_waddr_out(mem_wb_reg_waddr_out),
    .reg_we_out(mem_wb_reg_we_out),
    .csr_we_out(mem_wb_csr_we_out),
    .csr_wdata_out(mem_wb_csr_wdata_out),
    .csr_waddr_out(mem_wb_csr_waddr_out),
    .instret_incr_out(mem_wb_csr_instret_incr_out)

);

//csrfile
wire [`RDATA_WIDTH-1:0] csr_rdata_out;

csrfile csrfile0(
    .clk_in(clk_in),
    .reset_in(reset_in),
    //exe read
    .raddr_in(exe_csr_addr_out),
    .rdata_out(csr_rdata_out),
    //wb update the csr register file
    .waddr_in(mem_wb_csr_waddr_out),
    .wdata_in(mem_wb_csr_wdata_out),
    .we_in(mem_wb_csr_we_out),
    .instret_incr_in(mem_wb_csr_instret_incr_out)
);
endmodule