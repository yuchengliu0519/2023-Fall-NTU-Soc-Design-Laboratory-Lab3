module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,    
    
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);


    // write your code here!
    reg ap_start;
    reg ap_done;
    reg ap_idle;
    reg [31:0] data_length;
    reg [3:0] we;
    reg [3:0] counter;
    //axi lite read

    reg reg_arready;
    reg reg_rvalid;
    reg [(pDATA_WIDTH-1):0] reg_rdata;
    reg [(pADDR_WIDTH-1):0] reg_araddr;

    
    assign arready = reg_arready;
    assign rvalid = reg_rvalid;
    assign rdata = reg_rdata;
    reg reg_rvalid_temp;
    reg reg_rvalid_temp2;
    always@(posedge axis_clk) begin
        if(axis_rst_n==0) begin
            reg_arready <= 1;
        end
       // else if((reg_arready == 1) && (arvalid == 1))begin
       else if(arvalid == 1)begin
            reg_arready <= 0;
        end
        else begin
            reg_arready <= 1;
        end
        
        if(axis_rst_n==0) begin
            reg_rvalid <= 0;
        end
        else if(reg_rvalid_temp2) begin
            reg_rvalid <= 1;
        end
        else if((reg_rvalid == 1) && (rready == 1))begin
            reg_rvalid <= 0;
        end
        else begin
            reg_rvalid <= reg_rvalid;
        end
        
        if(axis_rst_n==0) begin
            reg_rvalid_temp <= 0;
        end
        else if((arvalid == 1) && (arready == 1)) begin
            reg_rvalid_temp <= 1;
        end
        else begin
            reg_rvalid_temp <= 0;
        end
        
        if(axis_rst_n==0) begin
            reg_rvalid_temp2 <= 0;
        end
        else if(reg_rvalid_temp) begin
            reg_rvalid_temp2 <= 1;
        end
        else begin
            reg_rvalid_temp2 <= 0;
        end
    end

    always@(posedge axis_clk) begin

        if(reg_arready == arvalid)begin
            reg_araddr <= araddr;
        end
        else begin
            reg_araddr <= reg_araddr;
        end
    end
    always@(*) begin
        if((rready == 1) && (reg_rvalid == 1)) begin
            if(ap_done==1 && ap_idle==1)begin
                reg_rdata = {29'b0,ap_done,ap_idle,ap_start};
            end
            else if(ap_idle==1)begin
                reg_rdata = tap_Do;
            end
            else begin
                reg_rdata = 0;
            end
        end
        else begin
            reg_rdata = reg_rdata;
        end
    end
    

    
    //axi lite write
    
    reg reg_awready;
    reg reg_wready;

    reg [(pADDR_WIDTH-1):0] reg_awaddr;
    reg [(pDATA_WIDTH-1):0] reg_wdata;
    assign rdata = reg_rdata;
    assign awready = reg_awready;
    assign wready = reg_wready;
    
    always@(posedge axis_clk) begin
        if(axis_rst_n==0) begin
            reg_awready <= 1;
        end
        else if((reg_awready == 1) && (awvalid == 1))begin
            reg_awready <= 0;
        end
        else begin
            reg_awready <= 1;
        end
        
        if(axis_rst_n==0) begin
            reg_wready <= 1;
        end
        else if((reg_wready == 1) && (wvalid == 1))begin
            reg_wready <= 0;
        end
        else begin
            reg_wready <= 1;
        end
    end
    reg reg_wready_temp;
    always@(posedge axis_clk) begin
        if(axis_rst_n==0) begin
            reg_wready_temp <= 0;
        end
        else if((reg_wready == 1) && (wvalid == 1) && awaddr>=12'h20)begin
            reg_wready_temp <= 1;
        end
        else begin
            reg_wready_temp <= 0;
        end
    end
    always@(posedge axis_clk) begin
        if((reg_awready == 1) && (awvalid==1))begin
            reg_awaddr <= awaddr;
        end
        else begin
            reg_awaddr <= reg_awaddr;
        end
    end
    
    always@(posedge axis_clk) begin

        if((reg_wready == 1) && (wvalid == 1))begin
            reg_wdata <= wdata;
        end
        else begin
            reg_wdata <= reg_wdata;
        end
    end
    always@(posedge axis_clk) begin
        if(axis_rst_n==0) begin
            data_length <= 0;
        end
        else if(reg_awaddr == 11'h10)begin
            data_length <= reg_wdata;
        end
        else begin
            data_length <= data_length;
        end
    end
    always@(posedge axis_clk) begin
        if(axis_rst_n==0) begin
            ap_start <= 0;
        end
        else if(wvalid==1 && wready==1 && awaddr==0)begin
            ap_start <= wdata;
        end
        else if(ap_start) begin
            ap_start <= 0;
        end
        else begin
            ap_start <= ap_start;
        end
    end
    //reg reg_tap_EN;

    //reg reg_tap_Di;
    
    assign tap_WE = we;
    assign tap_EN = 1;

    assign tap_Di = reg_wdata;
    reg [(pADDR_WIDTH-1):0] reg_tap_A;
    assign tap_A = (counter>=0 && counter<=10)?(counter<<2):reg_tap_A;
    always@(posedge axis_clk) begin
        if(axis_rst_n==0)begin
            reg_tap_A <= 0;
        end
        else if(reg_wready_temp)begin
            reg_tap_A <= reg_awaddr-32;
        end
        else begin
            reg_tap_A <= reg_araddr-32;
        end
    end
    
    always@(posedge axis_clk) begin
        if(axis_rst_n==0) begin
            we <= 4'b0;
        end
        else if(reg_wready_temp)begin
            we <= 4'b1111;
        end
        else begin
            we <= 0;
        end
    end  
    /*
    always@(*)begin
     if(awaddr>=12'h20 || araddr>=12'h20)begin
        reg_tap_EN = 1;
     end
     else begin
        reg_tap_EN = 0;
     end
    end
    */
/*
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,
*/

assign data_EN = 1;
assign data_WE = (counter>=4'd11)?4'b1111:0;
reg [(pADDR_WIDTH-1):0] reg_data_A;

assign data_EN = 1;
reg [(pDATA_WIDTH-1):0] reg_data_Di;
reg reg_ss_tready;
assign data_Di = reg_data_Di;
always@(*)begin
    if(ss_tready==1 && ss_tvalid==1)begin
        reg_data_Di = ss_tdata;
    end
    else begin
        reg_data_Di = 0;
    end
end

always@(*)begin
    if(counter == 4'd11)begin
        reg_ss_tready =1;
    end
    else begin
        reg_ss_tready = 0;
    end
end
assign ss_tready = reg_ss_tready;
reg [3:0] pointer;
always@(posedge axis_clk)begin
    if(axis_rst_n==0)begin
        pointer <= 0;
    end
    else if(ap_start || (pointer==4'd10 && counter==4'd10))begin
        pointer <= 0;
    end
    else if(counter == 4'd15 || counter==4'd10) begin
        pointer <= pointer + 1;
    end
    else begin
        pointer <= pointer;
    end
end
wire [3:0] pointerpluscounter;
assign pointerpluscounter = (pointer  >= counter)?(pointer - counter):(4'd11-counter+pointer);
assign data_A = reg_data_A<<2;
always@(*)begin
    if(counter>=4'd11)begin
        reg_data_A = pointer;
    end
    else begin
        reg_data_A = pointerpluscounter;
    end
end
always@(posedge axis_clk)begin
    if(axis_rst_n==0)begin
        counter <= 4'd15;
    end
    else if(ap_start)begin
        counter <= 4'd11;
    end
    else if(counter==4'd11)begin
        counter <= 4'd0;
    end
    else if(counter<=4'd10)begin
        counter <= counter + 1;
    end
    else begin
    end
end
wire [31:0] multiply_result;
assign multiply_result = $signed(tap_Do)*$signed(data_Do);
reg [31:0] adder;
always@(posedge axis_clk)begin
    if(counter>=4'd1 && counter<=4'd11)begin
        adder <= adder + multiply_result;
    end
    else if(counter==0 || counter==4'd15)begin
        adder <= 0;
    end
    else begin
        adder <= adder;
    end
end
/*    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    */
    reg temp;
always@(posedge axis_clk)begin
    if(axis_rst_n==0)begin
        temp <= 0;
    end
    else if(counter==0)begin
        temp <= 1;
    end
    else begin
        temp <= temp;
    end
end
    assign sm_tvalid = (counter==0 && temp)? 1:0;
    assign sm_tdata = (counter==0)? adder:0;
    reg [9:0] count_x;
always@(posedge axis_clk)begin
    if(axis_rst_n==0)begin
        count_x <= 0;
    end
    else if(counter==0 && temp)begin
        count_x <= count_x + 1;
    end
    else begin
        count_x <= count_x;
    end
end
assign sm_tlast = (count_x==data_length && counter==1)?1:0;

always@(posedge axis_clk)begin
    if(axis_rst_n==0 || sm_tlast==1)begin
        ap_idle <= 1;
    end
    else if(ap_start==1)begin
        ap_idle <= 0;
    end
    else begin
        ap_idle <= ap_idle;
    end
end
always@(posedge axis_clk)begin
    if(axis_rst_n==0 )begin
        ap_done <= 0;
    end
    else if(sm_tlast==1)begin
        ap_done <= 1;
    end
    else begin
        ap_done <= ap_done;
    end
end
endmodule