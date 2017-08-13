interface MemoryInterface #(
	int ADDRESS_WITDH	= 32,
	int DATA_WIDTH		= 32
)();
	logic	[ADDRESS_WITDH - 1 : 0] address;
	logic [DATA_WIDTH - 1		 : 0] dataIn, dataOut;
	logic 												writeEnabled, readEnabled, functionComplete;

	modport master(
		input 	dataIn, functionComplete,
		output 	address, dataOut, writeEnabled, readEnabled
	);

	modport slave(
		input 	dataOut, address, writeEnabled, readEnabled, 
		output	dataIn, functionComplete
	);
endinterface
