interface TestInterface#(
	int INDEX_WIDTH				= 6,
	int SET_ASSOCIATIVITY	= 2	
)();

	localparam NUMBER_OF_CACHE_LINES = 1 << SET_ASSOCIATIVITY;

	ReplacementAlgorithmInterface#(.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)) replacementAlgorithmInterface();
	logic[INDEX_WIDTH - 1 : 0] cpuIndexIn, snoopyIndexIn;

	bit clock;
	logic reset;

endinterface : TestInterface
