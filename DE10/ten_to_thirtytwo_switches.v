module ten_to_thirtytwo_switches(in, out);
	input [9:0] in;
	output reg [31:0] out;
	
	always @(in) begin
		case(in[9:8])
			2'b00: out[ 7: 0] <= in[7:0];
			2'b01: out[15: 8] <= in[7:0];
			2'b10: out[23:16] <= in[7:0];
			2'b11: out[31:24] <= in[7:0];
		endcase
	end
endmodule
