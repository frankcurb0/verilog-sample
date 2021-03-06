`timescale 1ns/1ns

module tb_myosctest;

reg rst_n;	//低电平复位信号
wire clkdiv;	//输出测试8分频信号


myosctest	myosctest(
				.rst_n(rst_n),
				.clkdiv(clkdiv)
			);

initial begin
	rst_n = 0;
	#1000;
	rst_n = 1;
	#50000;
	$stop;
end



endmodule


