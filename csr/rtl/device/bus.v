module bus #(
    parameter Devices = 2, // the number of devices which is lined on bus (read only)
    parameter Hosts = 1, // the number of hosts which can read and write
    parameter DataWidth = 32,
    parameter AddressWidth = 32 
)(
    input wire clk_in,
    input wire reset_in,

    //Hosts
    input wire h_req_in [Hosts],
    output reg h_gnt_out [Hosts], //授權

    input wire [AddressWidth-1:0] h_addr_in [Hosts],
    input wire h_we_in [Hosts],
    input wire [DataWidth-1:0] h_wdata_in [Hosts],
    output reg [DataWidth-1:0] h_rdata_out [Hosts],

    //Devices
    output reg d_req_out [Devices],
    
    output reg [AddressWidth-1:0] d_addr_out [Devices],
    output reg d_we_out [Devices],
    output reg [DataWidth-1:0] d_wdata_out [Devices],
    input reg [DataWidth-1:0] d_rdata_in [Devices],

    //Device address map
    input wire [AddressWidth-1:0] cfg_device_addr_base [Devices],
    input wire [AddressWidth-1:0] cfg_device_addr_mask [Devices]
);
    localparam HOST_NUM = Hosts > 1 ? clog2(Hosts):1; //取log可以知道需要幾個bit，例如：今天我有五個host至少我要2^3 ＝ 8個才有位置給予這五個host編號
    localparam DEVICE_NUM = Devices > 1 ? clog2(Devices):1;
    reg [HOST_NUM-1:0] host_sel_req, host_sel_resp;
    reg [DEVICE_NUM-1:0] device_sel_req, device_sel_resp;

    //choosing the host who send the request 編號越大越先做
    always @(*) begin
        host_sel_req = 0;
        for(integer host = Hosts - 1; host >= 0; host = host - 1)begin
            if(h_req_in[host] == 1)begin
                host_sel_req = HOST_NUM'(host);//one integer
            end
        end
    end

    //choosing the device who get the request
    always @(*) begin
        device_sel_req = 0;
        for(integer device = 0; device < Devices; device = device + 1)begin
            if((h_addr_in[host_sel_req] & cfg_device_addr_mask[device]) == cfg_device_addr_base[device])begin
                device_sel_req = DEVICE_NUM'(device); //one integer
            end
        end
    end

    always @(*) begin         
        if (reset_in==1'b1) begin
            host_sel_resp = '0;
            device_sel_resp = '0;
        end else begin
            // Responses are always expected 1 cycle after the request
            device_sel_resp = device_sel_req;
            host_sel_resp = host_sel_req;
        end
    end

    //將host的東西傳送過去給正確的device
    always @(*) begin
        for(integer device = 0; device < Devices; device = device +1)begin
            if(DEVICE_NUM'(device) == device_sel_req)begin //if we get the same value when we are checking the device select request
                d_req_out[device] = h_req_in[host_sel_req];
                d_addr_out[device] = h_addr_in[host_sel_req];
                d_we_out[device] = h_we_in[host_sel_req];
                d_wdata_out[device] = h_wdata_in[host_sel_req]; 
            end else begin
                d_req_out[device] = 1'b0;
                d_addr_out[device] = 'b0;//nomatar the width it will give it all zero;
                d_we_out[device] = 1'b0;
                d_wdata_out[device] = 'b0;
            end
        end
    end

    
    always @(*) begin
        for (integer host = Hosts - 1; host >= 0; host = host - 1 ) begin
            h_gnt_out[host] = 1'b0;
            if(HOST_NUM'(host) == host_sel_resp)begin
                h_rdata_out[host] = d_rdata_in[device_sel_resp];
            end else begin
                h_rdata_out[host] = 'b0;
            end
        end
        h_gnt_out[host_sel_req] = h_req_in[host_sel_req];
    end

    function integer clog2 (input integer n); begin
    n = n - 1;
    for (clog2 = 0; n > 0; clog2 = clog2 + 1)
      n = n >> 1;
  end
  endfunction
endmodule

    