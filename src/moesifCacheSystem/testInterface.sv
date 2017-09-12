interface TestInterface#(
	int ADDRESS_WIDTH    = 16,
	int DATA_WIDTH       = 16,
	int NUMBER_OF_CACHES = 4
)();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) memoryInterface[NUMBER_OF_CACHES]();
	
	logic[ADDRESS_WIDTH - 1 : 0] address[NUMBER_OF_CACHES];
	logic[DATA_WIDTH - 1    : 0] dataIn[NUMBER_OF_CACHES], dataOut[NUMBER_OF_CACHES];
	logic 											 readEnabled[NUMBER_OF_CACHES], writeEnabled[NUMBER_OF_CACHES], functionComplete[NUMBER_OF_CACHES];

	generate
		genvar i;
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			assign memoryInterface[i].address      = address[i];
			assign memoryInterface[i].dataOut      = dataOut[i];
			assign memoryInterface[i].readEnabled  = readEnabled[i];
			assign memoryInterface[i].writeEnabled = writeEnabled[i];

			assign dataIn[i]           = memoryInterface[i].dataIn;
			assign functionComplete[i] = memoryInterface[i].functionComplete;
		end
	endgenerate

	logic reset;
	bit clock;

endinterface : TestInterface
