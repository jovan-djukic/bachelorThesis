interface TestInterface#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH 
)();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
		.DATA_WIDTH(DATA_WIDTH)
	) memoryInterface();
	bit clock;

endinterface : TestInterface
