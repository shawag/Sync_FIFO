`timescale 1ns / 1ps
`define SVA 
module Sync_FIFO #(
    parameter  P_DATA_WIDTH = 8 ,
    parameter  P_FIFO_DEPTH = 16,
    parameter  P_FIFO_DWIDTH = $clog2(P_FIFO_DEPTH)
) 
(
    input                       i_clk,
    input                       i_rst_n,

    input                       i_wren,
    input [P_DATA_WIDTH-1:0]    i_wdata,
    input       i_rden,
    output [P_DATA_WIDTH-1:0]   o_rdata,
    output                      o_rddata_valid,

    output                      o_fifo_full,
    output                      o_fifo_empty,

    input  [P_FIFO_DWIDTH-1:0]  i_cfg_almost_full,
    input  [P_FIFO_DWIDTH-1:0]  i_cfg_almost_empty,

    output                      o_fifo_almost_full,
    output                      o_fifo_almost_empty,

    output [P_FIFO_DWIDTH-1:0]  o_fifo_space
    
);
//**************************************************
logic   [P_DATA_WIDTH-1:0]  rdata;
logic                       rddata_valid;
//**************************************************
assign o_rdata = rdata;
assign o_rddata_valid = rddata_valid;
//**************************************************
logic   [P_FIFO_DWIDTH:0]   fifo_wr_ptr_exp;
logic   [P_FIFO_DWIDTH:0]   fifo_rd_ptr_exp;

logic   [P_FIFO_DWIDTH-1:0]  fifo_wr_ptr;
logic   [P_FIFO_DWIDTH-1:0]  fifo_rd_ptr;
//**************************************************
integer i;
//**************************************************
logic   [P_DATA_WIDTH-1:0]  fifo_ram[P_FIFO_DEPTH-1:0];
//**************************************************
assign  fifo_wr_ptr = fifo_wr_ptr_exp[P_FIFO_DWIDTH-1:0];
assign  fifo_rd_ptr = fifo_rd_ptr_exp[P_FIFO_DWIDTH-1:0];
//**************************************************
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        fifo_wr_ptr_exp <= {(P_FIFO_DWIDTH+1){1'b0}};
    else if(i_wren) begin
        if(fifo_wr_ptr_exp < P_FIFO_DEPTH+P_FIFO_DEPTH-1)
            fifo_wr_ptr_exp <= fifo_wr_ptr_exp + 1'b1;
        else
            fifo_wr_ptr_exp <= {(P_FIFO_DWIDTH+1){1'b0}};
    end
end
//**************************************************
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        fifo_rd_ptr_exp <= {(P_FIFO_DWIDTH+1){1'b0}};
    else if(i_rden) begin
        if(fifo_rd_ptr_exp < P_FIFO_DEPTH+P_FIFO_DEPTH-1)
            fifo_rd_ptr_exp <= fifo_rd_ptr_exp + 1'b1;
        else
            fifo_rd_ptr_exp <= {(P_FIFO_DWIDTH+1){1'b0}}; 
    end
end
//**************************************************
assign  o_fifo_space = fifo_wr_ptr_exp - fifo_rd_ptr_exp;
assign  o_fifo_full = (o_fifo_space == P_FIFO_DEPTH) | ((o_fifo_space == P_FIFO_DEPTH-1) & i_wren & ~i_rden);
assign  o_fifo_empty = (o_fifo_space == 0) | ((o_fifo_space == 1) & ~i_wren & i_rden);
assign  o_fifo_almost_full = (o_fifo_space >= i_cfg_almost_full) | ((o_fifo_space == i_cfg_almost_full-1) & i_wren & ~i_rden);
assign  o_fifo_almost_empty = (o_fifo_space <= i_cfg_almost_empty) | ((o_fifo_space == i_cfg_almost_empty+1) & ~i_wren & i_rden);
//**************************************************
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        for (i = 0; i<P_FIFO_DEPTH;i=i+1 ) begin
            fifo_ram[i] <= {P_DATA_WIDTH{1'b0}};
        end
    else begin
        if(i_wren)
            fifo_ram[fifo_wr_ptr] <= i_wdata;
    end
end
//**************************************************
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        rdata <= {P_DATA_WIDTH{1'b0}};
    else begin
        if(i_rden)
            rdata <= fifo_ram[fifo_rd_ptr];
    end
end
//**************************************************
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        rddata_valid <= 1'b0;
    else if(i_rden)
        rddata_valid <= 1'b1;
    else
        rddata_valid <= 1'b0;
end

`ifdef SVA
Bis0: assert property(rddata_valid_checker)
else
    $error("rddata_valid is not 1 @ %t", $time);

property rddata_valid_checker;
    @(posedge i_clk) i_rden |-> ##1 rddata_valid;
endproperty
`endif



    
endmodule //Sync_FIFO
