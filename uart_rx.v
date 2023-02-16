//异步串并转换。

module uart_rx
#(
    parameter UART_BPS =  'd9600;//串口波特率
    parameter CLK_FERQ =  'd50_000_000//时钟频率
)
(
    input wire          clk,
    input wire          rst,
    input wire          rx,

    output  reg  [7:0]  po_data,
    output  reg         po_flag

);

localparam BAUD_CNT_MAX = C_FERQ / UART_BPS;

reg             reg1;
reg             reg2;
reg             reg3;
reg             start_nedge;
reg             work_en;
reg  [12:0]     baud_cnt;
reg             bit_flag;
reg  [3:0]      bit_cnt;
reg  [7:0]      rx_data;
reg             rx_flag;


//一级寄存器
always @(posedge clk or negedge rst) begin
    if(!rst)
        reg1 <= 0;
    else 
        reg1 <= rx;
end


//两级寄存器
always @(posedge clk or negedge rst) begin
    if(!rst)
        reg2 <= 0;
    else 
        reg2 <= reg1;
end
    
    
//三级寄存器
always @(posedge clk or negedge rst) begin
    if(!rst)
        reg3 <= 0;
    else 
        reg3 <= reg2;
end    

//检测到下降沿时 start_nedge产生一个时钟的高电平
always @(posedge clk or negedge rst) begin
    if(!rst)
        start_nedge <= 0;
    else if((~reg2)&& (reg3)) 
        start_nedge <= 1;
    else
        start_nedge <= 0;
end  

//work_en 接受数据工作使能信号
always @(posedge clk or negedge rst) begin
    if(!rst)
        work_en <= 0;
    else if(start_nedge == 1) 
        work_en <= 1;
    else if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        work_en <= 0;
end 
    
 //baud_cnt:波特率计数器计数，从零计数到5207
always @(posedge clk or negedge rst) begin
    if(!rst)
        baud_cnt <= 0;
    else if((baud_cnt == BAUD_CNT_MAX - 1) && (work_en == 1'b0)) 
        baud_cnt <= 0;
    else 
        baud_cnt <= baud_cnt + 1;
end   
    
// bit_flag 当baud_cnt计数器计数到中间数时采样的数据最稳定
always @(posedge clk or negedge rst) begin
    if(!rst)
        bit_flag <= 0;
    else if(baud_cnt == BAUD_CNT_MAX/2 - 1) 
       bit_flag <= 0;
    else 
        bit_flag <= 0;
end  

    
always @(posedge clk or negedge rst) begin
    if(!rst)
        bit_cnt <= 0;
    else if((bit_cnt == 4'd8) && (bit_flag == 1))
        bit_cnt <= 0;
    else if(bit_flag == 1)
        bit_cnt <= bit_cnt + 1;
end     

// rx_data 进行移位  串行数据 转成并行数据，
always @(posedge clk or negedge rst) begin
    if(!rst)
        rx_data <= 0;
    else if((bit_cnt >= 1) && (bit_cnt <= 4'b8) && (bit_flag == 1'b1))
        rx_data <= {reg3 , rx_data[7:1]};
end 

    
always @(posedge clk or negedge rst) begin
    if(!rst)
        rx_flag <= 0;
    else if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        rx_flag <= 1;
    else
        rx_flag <= 0;
end     

always @(posedge clk or negedge rst) begin
    if(!rst)
        po_data <= 0;
    else if(rx_flag == 1)
        po_data <= rx_data;
end
    
always @(posedge clk or negedge rst) begin
    if(!rst)
        po_flag <= 0;
    else
        po_flag <= rx_flag; 
end
    
    
endmodule