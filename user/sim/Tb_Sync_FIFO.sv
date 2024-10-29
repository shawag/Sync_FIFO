`timescale 1ns / 1ps
module Tb_Sync_FIFO ();

parameter  P_DATA_WIDTH = 8;
parameter  P_FIFO_DEPTH = 16;
parameter  P_FIFO_DWIDTH = $clog2(P_FIFO_DEPTH);
integer                     seed;
int                         fsdbDump;

logic                       clk;
logic                       rst_n;
logic                       wren;
logic [P_DATA_WIDTH-1:0]    wdata;
logic                       rden;
wire  [P_DATA_WIDTH-1:0]    rdata;
wire                        rddata_valid;
wire                        fifo_full;
wire                        fifo_empty;

logic                       sample_full;
logic                       sample_empty;

wire                       fifo_almost_full;
wire                       fifo_almost_empty;
wire [P_FIFO_DWIDTH-1:0]   fifo_space;


logic [P_DATA_WIDTH-1:0]    wdata_array[$];
logic [P_DATA_WIDTH-1:0]    rdata_array[$];

integer                     wr_cnt;
integer                     rd_cnt;
integer                     cnt;

int                         file1;
int                         file2;

//setting format of time reporting
initial     $timeformat(-9, 3, "ns", 0);
initial begin
    if(!$value$plusargs("seed=%d", seed))
        seed = 100;
    //$srandom(seed); 
    $display("seed = %d\n", seed);

    if(!$value$plusargs("fsdbDump = %d", fsdbDump))
        fsdbDump = 1;
    if(fsdbDump) begin
        $fsdbDumpfile("Tb_Sync_FIFO.fsdb");
        $fsdbDumpvar(0);
        $fsdbDumpMDA("Tb_Sync_FIFO.u_Sync_FIFO.fifo_ram");
    end

end

initial begin
    clk = 1'b0;
    forever begin
        #(1e9/(2*40e6)) clk = ~clk;
    end
end

initial begin
    rst_n = 1'b0;
    #30
    rst_n = 1'b1;
end

initial begin
    wren = 1'b0;
    rden = 1'b0;
    wdata = 0;
    wr_cnt = 0;
    rd_cnt = 0;
    cnt=0;
    sample_full = 0;
    sample_empty = 0;

    @(posedge rst_n);

    repeat(1e4) begin
        @(posedge clk);
        sample_full = fifo_full;
        sample_empty = fifo_empty;

        if(rddata_valid) begin
            rdata_array[rd_cnt] = rdata;
            rd_cnt = rd_cnt + 1;
        end

        #1
        wren = 0;
        if(rden)
        rden = 0;

        wren = {$random(seed)} %2;
        rden = {$random(seed)} %2;

        if((~sample_full) & wren) begin
            wdata_array[wr_cnt] = {$random(seed)} %256;
            wdata = wdata_array[wr_cnt];
            wr_cnt = wr_cnt + 1;
        end
        else
            wren = 0;
        if(~(~sample_empty & rden))
            rden = 0;    
    end
    file1 = $fopen("wdata.txt", "w");
    file2 = $fopen("rdata.txt", "w");
    for (cnt=0;cnt<rd_cnt;cnt=cnt+1) begin
        if(rdata_array[cnt] != wdata_array[cnt])
            $display("ERROR: address is %0d",cnt);

        $fdisplay(file1,"%x",wdata_array[cnt]);
        $fdisplay(file2,"%x",rdata_array[cnt]); 
    end
    $fclose(file1);
    $fclose(file2);

    $finish;
end





Sync_FIFO #(
    .P_DATA_WIDTH(P_DATA_WIDTH),
    .P_FIFO_DEPTH(P_FIFO_DEPTH)
) u_Sync_FIFO (
.i_clk                  (clk),
.i_rst_n                (rst_n),
.i_wren                 (wren),
.i_rden                (rden),
.i_wdata                (wdata),
.o_rdata                (rdata),
.o_rddata_valid         (rddata_valid),
.o_fifo_full            (fifo_full),
.o_fifo_empty           (fifo_empty),
.i_cfg_almost_full      (3),
.i_cfg_almost_empty     (3),
.o_fifo_almost_full     (fifo_almost_full),
.o_fifo_almost_empty    (fifo_almost_empty),
.o_fifo_space           (fifo_space)
);
    
endmodule //moduleName
