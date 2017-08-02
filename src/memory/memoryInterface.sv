interface MemoryInterface #(
	int ADDRESS_WITDH	= 32,
	int DATA_WIDTH		= 32
)(input logic clock);
	logic	[ADDRESS_WITDH - 1 : 0] address;
	logic [DATA_WIDTH - 1		 : 0] dataIn, dataOut;
	logic 												writeEnabled, readEnabled;

	modport master(
		input 	dataIn, clock,
		output 	address, dataOut, writeEnabled, readEnabled
	);

	modport slave(
		input 	dataOut, address, writeEnabled, readEnabled, clock,
		output	dataIn
	);
endinterface
