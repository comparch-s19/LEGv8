module GPIO_DE0_to_DE10(in,out);
	input [31:0]in;
	output [35:0]out;
	assign {out[0],out[2]}=2'b00;
	assign {out[3],out[1]}=in[1:0];
	assign out[15:4]=in[13:2];
	assign {out[18],out[16]}=2'b00;
	assign {out[19],out[17]}=in[15:14];
	assign out[35:20]=in[31:16];
endmodule
