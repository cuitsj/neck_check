module ads7883_ctrl(
    input                       clk,                //时钟信号
    input                       rst_n,              //复位信号，低电平有效
	input                       en_adc,        	    //ADC控制器使能信号，高电平有效
    input                       ads7883_sdo,        //连接ADC模块数据输出管脚
    
	output reg                  adc_finish,         //ADC12位数据更新完成标志
	output reg signed [12:0]    adc_data,           //AD转换最终输出的12位数据
	output reg                  ads7883_sclk,       //ADC芯片时钟信号
	output reg                  ads7883_ncs         //ADC片选信号，低电平ADC进入转换模式，高电平ADC进入采集模式同时SDO计入高阻态
);
parameter CLK_STEP;             //ADC时钟步长，当前值是2

reg [6:0] adc_clk_cnt;          //保存线性序列机计数器计数值，计数范围是0-68，7位二进制足够。

reg signed [12:0] adc_buffer;   //中途保存ADC数据的寄存器

//AD时钟周期计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        adc_clk_cnt <= 7'd0;
    else if(adc_clk_cnt == 7'd34*CLK_STEP || !en_adc)
        adc_clk_cnt <= 7'd0;
    else
        adc_clk_cnt <= adc_clk_cnt+1'b1;
end

//在一个线性系列机计数器周期内按照ads7883时序进行数据接收，获取AD值
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        adc_buffer      <= 13'd0;
        ads7883_sclk    <= 1'b1;
        ads7883_ncs     <= 1'b0;    //复位时片选为0
        adc_data        <= 13'd0;
        adc_finish      <= 1'b0;
    end
    else begin
        case (adc_clk_cnt)
            0: begin
                adc_buffer      <= 13'd0;
                ads7883_sclk    <= 1'b1;
                ads7883_ncs     <= 1'b1;
                adc_finish      <= 1'b0;
            end
            1: ads7883_ncs              <= 1'b0;//片选信号低电平，sdo输出第一个前导0
            1*CLK_STEP: ads7883_sclk    <= 1'b0;//1,距离片选拉低要大于7ns
            2*CLK_STEP: ads7883_sclk    <= 1'b1;
            3*CLK_STEP: ads7883_sclk    <= 1'b0;//2,第二个时钟周期下降沿，sdo输出第二个前导0
            4*CLK_STEP: ads7883_sclk    <= 1'b1;
            5*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//3
                adc_buffer[11]  <= ads7883_sdo;
            end
            6*CLK_STEP: ads7883_sclk <= 1'b1;
            7*CLK_STEP: begin
                ads7883_sclk <= 1'b0;//4
                adc_buffer[10] <= ads7883_sdo;
            end
            8*CLK_STEP: ads7883_sclk <= 1'b1;
            9*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//5
                adc_buffer[9]   <= ads7883_sdo;
            end
            10*CLK_STEP: ads7883_sclk <= 1'b1;
            11*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//6
                adc_buffer[8]   <= ads7883_sdo;
            end
            12*CLK_STEP: ads7883_sclk <= 1'b1;
            13*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//7
                adc_buffer[7]   <= ads7883_sdo;
            end
            14*CLK_STEP: ads7883_sclk <= 1'b1;
            15*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//8
                adc_buffer[6]   <= ads7883_sdo;
            end
            16*CLK_STEP    : ads7883_sclk <= 1'b1;
            17*CLK_STEP: begin
                ads7883_sclk <= 1'b0;//9
                adc_buffer[5] <= ads7883_sdo;
            end
            18*CLK_STEP: ads7883_sclk <= 1'b1;
            19*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//10
                adc_buffer[4]   <= ads7883_sdo;
            end
            20*CLK_STEP: ads7883_sclk <= 1'b1;
            21*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//11
                adc_buffer[3]   <= ads7883_sdo;
            end
            22*CLK_STEP: ads7883_sclk <= 1'b1;
            23*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//12
                adc_buffer[2]   <= ads7883_sdo;
            end
            24*CLK_STEP: ads7883_sclk <= 1'b1;
            25*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//13
                adc_buffer[1]   <= ads7883_sdo;
            end
            26*CLK_STEP: ads7883_sclk <= 1'b1;  //第13个下降沿偶的第一个上升沿，转换结束
            27*CLK_STEP: begin
                ads7883_sclk    <= 1'b0;//14
                adc_buffer[0]   <= ads7883_sdo;
            end
            (27*CLK_STEP)+1: begin
                adc_data <= {1'b0,adc_buffer[11:0]};  //将接收到的12位数据赋给输出端口，数据更新完成
                adc_finish <= 1'b1;
                end
            28*CLK_STEP: begin
                ads7883_sclk <= 1'b1;
                adc_buffer <= 0;
                adc_finish <= 1'b0;
                end
            29*CLK_STEP: ads7883_sclk <= 1'b0;      //15,第15个时钟周期的下降沿，输出第一个滞后0
            30*CLK_STEP: ads7883_sclk <= 1'b1;
            31*CLK_STEP: ads7883_sclk <= 1'b0;      //16,第16个时钟周期的下降沿，输出第二个滞后0
            32*CLK_STEP: ads7883_sclk <= 1'b1;
            33*CLK_STEP: begin
                ads7883_sclk    <= 1'b1;
                ads7883_ncs     <= 1'b1;//片选信号拉高
            end
            34*CLK_STEP: begin
                ads7883_sclk    <= 1'b1;        //采样转换读取数据的一个周期结束
            end                                 //片选信号拉高20纳秒超过tw1的10纳秒符合时序规则
            default: ;
        endcase
    end
end
endmodule
