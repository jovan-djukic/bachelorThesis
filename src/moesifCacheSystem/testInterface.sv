interface TestInterface#(
	int ADDRESS_WIDTH    = 16,
	int DATA_WIDTH       = 16,
	int NUMBER_OF_CACHES = 4
)();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) memoryInterface[NUMBER_OF_CACHES]();

	logic reset;
	bit clock;

endinterface : TestInterface
