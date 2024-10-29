module clint (
    input wire clk_in,
    input wire reset_in,

    input wire req_in,
    input wire we_in,
    input wire [31 : 0] addr_in, //risc-v的timer是透過mmio的方式讀取mtime , msip, mtimecmp
    input wire [31 : 0] data_in,
    output reg [31 : 0] data_out,

    //to csr
    output reg timer_interrupt_req_out,
    output reg software_interrupt_req_out
);
//MMIO ADDRESS
localparam MSIP_BASE = 16'h0;
localparam MTIMECMP_BASE = 16'h4000;
localparam MTIME_BASE = 16'hbff8;
wire [15:0] raddr = addr_in [15:0];

//存取值域的reg
reg [31 : 0] mtime_mem[0:1]; //64bit
reg [31 : 0] mtimecmp_mem[0:1]; //64bit
reg [31 : 0] msip_mem;
wire [63 : 0] mtime = {mtime_mem[1], mtime_mem[0]};
wire [63 : 0] mtimecmp = {mtimecmp_mem[1], mtimecmp_mem[0]};
wire [63 : 0] msip = {32'b0, msip_mem};

//進位
wire carry = (mtime_mem[0] == 32'hFFFF_FFFF);

always @(posedge clk_in) begin
    //reset 時所有reg歸零
    if(reset_in == 1) begin
        mtime_mem[0] <= 32'b0;
        mtime_mem[1] <= 32'b0;
        mtimecmp_mem[0] <= 32'b0;
        mtimecmp_mem[1] <= 32'b0;
        msip_mem <= 32'b0;
    end else if (we_in == 1)begin
        //if we need write data into those register
        if(raddr == MSIP_BASE)begin
            msip_mem <= data_in;            
        end else if (raddr == MTIMECMP_BASE)begin
            mtimecmp_mem[0] <= data_in;
        end else if (raddr == (MTIMECMP_BASE + 16'h4)) begin //next address
            mtimecmp_mem[1] <= data_in;
        end
    end else begin //mtimer
        mtime_mem[0] <= mtime_mem[0] + 32'b1;
        mtime_mem[1] <= mtime_mem[1] + {31'b0,carry}; 
    end
end

always @(*) begin
    if(req_in == 1)begin
        //if we need to read those register
        if (raddr == MSIP_BASE) begin
            data_out = msip_mem;
        end else if (raddr == MTIMECMP_BASE) begin
            data_out = mtimecmp_mem[0];
        end else if (raddr == (MTIMECMP_BASE + 16'h4)) begin
            data_out = mtimecmp_mem[1];
        end else if (raddr == MTIME_BASE) begin
            data_out = mtime_mem[0];
        end else if (raddr == (MTIME_BASE + 16'h4)) begin
            data_out = mtime_mem[1];
        end
    end else begin
        data_out = 32'b0;
    end
end

assign timer_interrupt_req_out = (mtime >= mtimecmp) & (mtimecmp != 64'h0);
//ISR 完成後可以重新reload(set mtimecmp),也可以關閉time interrupt(set mie.MTIE ＝ 1)
assign software_interrupt_req_out = (msip != 64'h0);
//after isr finish software interrupt, it need to turn off the software interrupt which set misp = 0



endmodule