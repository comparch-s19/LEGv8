module DE10_DatapathTest(KEY, MAX10_CLK1_50, GPIO, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, SW);
	// connection names for DE10-Lite FPGA board - names must match pin assignment file
	input [1:0]KEY;
	input MAX10_CLK1_50;
	input [9:0] SW;
	output [35:0]GPIO;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output [9:0] LEDR;
	
	wire [31:0]GPIO0; // virtual DE0 GPIO0 connected to a subset of the 36 GPIO pins
	
	tri[31:0]GPIO1; // dummy connection as GPIO1 doesn't exist on the DE10-Lite
	
	// create wires for memory interface
	tri [63:0] data;
	wire [31:0] address;
	wire mem_read, mem_write;
	wire [1:0] size;
	
	// create remaining wires for datapath inteface
	wire [63:0] constant;
	wire [4:0] status; // 5 bits: {V, C, N, Z, Znot_registered}
	wire [31:0] instruction;
	//////////// CHANGE THE NUMBER OF BITS TO MATCH YOUR CONTROL WORD ///////////
	wire [32:0] ControlWord;
	//////////// OPTIONAL PROGRAM COUNTER OUTPUT - NOT USED FOR THIS TEST ///////
	//////////// REMOVE THIS IF YOUR DATAPATH DOESN'T HAVE THIS SIGNAL //////////
	wire [15:0] PC_out;
	//////////// if your datapath has any other signals besides:
	// ControlWord (input)
	// constant (input)
	// status (output)
	// instruction (output)
	// data (inout)
	// address (output)
	// mem_write (output)
	// mem_read (output)
	// size (output)
	// clock (input)
	// reset (input)
	// PC_out (optional output)
	// r0, r1, r2, r3, r4, r5, r6, r7 (outputs)
	///////////// make sure to add them and connect them to whatever makes sense
	
	// use the button for a clock and reset
	wire clock, reset;
	// buttons are active low so invert them to get possitive logic
	assign clock = ~KEY[1];
	assign reset = ~KEY[0];
	
	// wires of outputs for visualization on GPIO Board
	wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7;
	
	// DIP switch input from GPIO Board - dummy connection
	wire [31:0] DIP_SW;
	
	// wires for 7-segment decoder outputs
	wire [6:0] h0, h1, h2, h3, h4, h5, h6, h7, hd0, hd1, hd2, hd3, hd4, hd5, hd6, hd7; // hd6 and hd7 are dummy wires
	// create 7-segment decoders (4x at a time)
	// display lower 16 bits of address on hex 7:4 (on GPIO board)
	/////// NOTE IF YOUR RAM OR ROM MEMORY ADDRESS IS > 16 BITS YOU WONT BE ABLE TO SEE IT ALL
	/////// CONSIDER ADJUSTING YOUR MEMORY MAP TO 16 BITS JUST FOR DE10-Lite TESTING
	/////// OR USE THE HEXS ON THE DE10-Lite TO DISPLAY MORE OF THE ADDRESS
	quad_7seg_decoder address_decoder (address[15:0], h7, h6, h5, h4);
	// display lower 16 bits of data on hex 3:0 (on GPIO board)
	quad_7seg_decoder data_decoder (data[15:0], h3, h2, h1, h0);
	
	// ten_to_thirtytwo_switches module uses the upper two switches [9:8] to select which set of 8-bits of the output are changed by the lower 8 switches
	// this is used to create 32 control signal wires from the ten switches on the DE10-Lite
	wire [31:0] virtual_switches;
	ten_to_thirtytwo_switches switch_converter_inst (SW, virtual_switches);
	///// in this case there are more constol signals than virtual switches so some control signals must have fixed values
	///// here concatenation is used to fix the upper two bits of DA (which are the lower 5 bits of the CW) to 00
	///// this concept could be applied to SA and SB if needed since we are only able to see 8 registers anyway
	assign ControlWord[32:0] = {virtual_switches[30:3], 2'b00, virtual_switches[2:0]};
	///// My control word decoding (change these notes for your CW:
	// Virtual Switch Bank 00 Bits 7 6 5 4 3   2 1 0
	//                             SA[4:0]     DA[2:0]
	//
	// Virtual Switch Bank 01 Bits 7  6  5   4 3 2 1 0
	//                             FS[2:0]     SB[4:0]
	//
	// Virtual Switch Bank 10 Bits 7     6  5      4    3 2       1 0
	//                             MW  size[1:0]  RW  PS[1:0]   FS[4:3]
	//
	// Virtual Switch Bank 11 Bits 7   6   5   4  3     2    1     0
	//                             -  SL  IL  DS[1:0]  AS  PCSel  Bs
	//
	////////////////////////////////////////////////////////////////////////////////
	
	// Display the lower 24-bits of the control word on the DE10-Lite HEXs
	quad_7seg_decoder control_word_decoder1 (ControlWord[15:0], hd3, hd2, hd1, hd0);
	quad_7seg_decoder control_word_decoder2 (ControlWord[31:16], hd7, hd6, hd5, hd4);
	// display the remaining control word bits on the LEDs
	assign LEDR[8:0] = ControlWord[32:24];
	// give the constant a value
	assign constant = 64'd24;
	
	/////////// This line should be completely replaced with your datapath and the
	/////////// connection order appropriate using the names from this file
	DatapathWithMem datapath (ControlWord, constant, status, instruction, data, address, mem_write, mem_read, size, clock, reset, PC_out, r0, r1, r2, r3, r4, r5, r6, r7);
	
	// GPIO1 is not connected on the DE10-Lite
	GPIO_Board gpio_inst (MAX10_CLK1_50,
		r0, r1, r2, r3, r4, r5, r6, r7, // row display inputs
		h0, 1'b0, h1, 1'b0, // hex display inputs
		h2, 1'b0, h3, 1'b0, // decimal points are turned off
		h4, 1'b0, h5, 1'b0, 
		h6, 1'b0, h7, 1'b0, 
		DIP_SW, // 32x DIP switch output connected to dummy wire
		32'b0, // 32x LED input (doesn't work on DE10-Lite)
		GPIO0, // (output) needs to be converted before connecting to GPIO
		GPIO1 // (input/output) connect to dummy wire
	);
	
	// GPIO0 needs to be re-mapped for the DE10-Lite to work
	GPIO_DE0_to_DE10 gpio_converter_inst (GPIO0, GPIO);
	
	assign HEX0 = ~hd0;
	assign HEX1 = ~hd1;
	assign HEX2 = ~hd2;
	assign HEX3 = ~hd3;
	assign HEX4 = ~hd4;
	assign HEX5 = ~hd5;
	
endmodule
