interface ReadMemoryInterface#(
	int ADDRESS_WIDTH = 32,
	int DATA_WIDTH    = 32
)();

	logic[ADDRESS_WIDTH - 1 : 0] address;
	logic[DATA_WIDTH - 1    : 0] dataIn;
	logic 											 readEnabled, functionComplete;

	modport master (
		input dataIn, functionComplete,
		output address, readEnabled
	);

	modport slave (
		input address, readEnabled,
		output dataIn, functionComplete
	);

endinterface : ReadMemoryInterface
