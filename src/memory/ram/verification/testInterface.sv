interface TestInterface#(
	int ADDRESS_WIDTH = 32,
	int DATA_WIDTH 		= 32 
)();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
		.DATA_WIDTH(DATA_WIDTH)
	) memoryInterface();
	bit clock;

endinterface : TestInterface
