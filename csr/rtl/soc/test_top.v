`include "defines.v"
module test_top(
    input wire clk_in,
    input wire reset_in,

    output reg halt_out
);

localparam int Devices = 2;
localparam int Hosts = 1;


`define     HOST_CORE_PORT 0
`define     DEV_RAM        0
`define     DEV_CONSOLE    1

//host
wire h_req[Hosts];
wire [`ADDR_WIDTH-1:0] h_addr[Hosts];
wire h_we[Hosts];
wire [`DATA_WIDTH-1:0] h_wdata[Hosts];
wire h_gnt[Hosts];
wire [`DATA_WIDTH-1:0] h_rdata[Hosts];

//device
wire d_req[Devices];
wire [`ADDR_WIDTH-1:0] d_addr[Devices];
wire d_we[Devices];
wire [`DATA_WIDTH-1:0] d_wdata[Devices];
wire d_gnt[Devices];
wire [`DATA_WIDTH-1:0] d_rdata[Devices];

wire [`ADDR_WIDTH-1:0] cfg_device_addr_base [Devices];
wire [`ADDR_WIDTH-1:0] cfg_device_addr_mask [Devices];

assign cfg_device_addr_base[`DEV_RAM] = 32'h000000;
assign cfg_device_addr_mask[`DEV_RAM] = ~32'h1FFFFF; // 2 MB
assign cfg_device_addr_base[`DEV_CONSOLE] = 32'h200000;
assign cfg_device_addr_mask[`DEV_CONSOLE] = ~32'hFFFFF; // 1 MB


wire halt_from_console;
assign halt_out = halt_from_console;


bus #(
    .Devices(Devices),
    .Hosts(Hosts),
    .DataWidth(`DATA_WIDTH),
    .AddressWidth(`ADDR_WIDTH)
    )bus0(
    .clk_in(clk_in), .reset_in(reset_in),
    
    //Hosts
    .h_req_in(h_req),
    .h_addr_in(h_addr),
    .h_we_in(h_we),
    .h_wdata_in(h_wdata),

    .h_gnt_out(h_gnt),
    .h_rdata_out(h_rdata),
    
    //Devices
    .d_rdata_in(d_rdata),

    .d_req_out(d_req),
    .d_addr_out(d_addr),
    .d_we_out(d_we),
    .d_wdata_out(d_wdata),

    //address map
    .cfg_device_addr_base,
    .cfg_device_addr_mask
);


console #(
        .LogName("./log/console.log")
        ) console0 (
        .clk_in     (clk_in),
        .reset_in     (reset_in),

        .req_in     (d_req[`DEV_CONSOLE]),
        .we_in      (d_we[`DEV_CONSOLE]),
        .addr_in    (d_addr[`DEV_CONSOLE]),
        .wdata_in   (d_wdata[`DEV_CONSOLE]),
        .halt_out    (halt_from_console)
        );



wire core_rom_ce_out;
wire [`ADDR_WIDTH-1:0] core_rom_addr_out;
wire [`DATA_WIDTH-1:0] core_rom_data_in;



core_top core_top0(
    .clk_in(clk_in),
    .reset_in(reset_in),

    //to dpram
    .rom_ce_out(core_rom_ce_out),
    .rom_addr_out(core_rom_addr_out),
    .rom_data_in(core_rom_data_in),


    //to bus for mem_ram 
    .ram_ce_out(h_req[`HOST_CORE_PORT]),
    .ram_addr_out(h_addr[`HOST_CORE_PORT]),
    .ram_wdata_out(h_wdata[`HOST_CORE_PORT]),
    .ram_rdata_in(h_rdata[`HOST_CORE_PORT]),
    .ram_we_out(h_we[`HOST_CORE_PORT])
);


localparam int MemSize = 32'h200000;
localparam int MemAddrWidth = 21;


dpram #(
        .RAM_SIZE   ( MemSize ),
        .RAM_ADDR_WIDTH     ( MemAddrWidth )
    )dpram0(
    .clk_in(clk_in),
    //dara port
    .ce_in(d_req[`DEV_RAM]),
    //form memory to make the instruction of store(mem) and load(reg) can be operated 
    .mem_addr_in(d_addr[`DEV_RAM]),
    .mem_data_in(d_wdata[`DEV_RAM]),
    .mem_we_in(d_we[`DEV_RAM]),
    //instrution port connect with bus form pc_reg
    .chip_enable_in(core_rom_ce_out),
    .pc_in(core_rom_addr_out),
    //to memory form bus (data port of load)
    .mem_data_out(d_rdata[`DEV_RAM]),
    //to pc_reg form bus(instruction port)
    .inst_out(core_rom_data_in)
);
endmodule