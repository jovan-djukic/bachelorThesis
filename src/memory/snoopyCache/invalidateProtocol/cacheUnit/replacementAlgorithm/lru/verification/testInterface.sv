interface TestInterface#(
	int INDEX_WIDTH,
	int NUMBER_OF_CACHE_LINES
)();

	ReplacementAlgorithmInterface#(
		.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)
	) replacementAlgorithmInterface();
	logic[INDEX_WIDTH - 1 : 0] cpuIndexIn, snoopyIndexIn;

	bit clock;
	logic reset;

endinterface : TestInterface
