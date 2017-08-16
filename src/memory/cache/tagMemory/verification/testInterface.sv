interface TestInterface#(
	type STATE_TYPE				= logic[1 : 0],
	int TAG_WIDTH					= 6,
	int INDEX_WIDTH				= 6,
	int SET_ASSOCIATIVITY = 4
);
		
	TagUnitInterface#(
		.STATE_TYPE(STATE_TYPE),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH)
	) tagUnitInterface();

	bit clock;
	logic reset;
	//select signal for demultiplexers
	logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumberIn;
	//select signal for out use i.e. replacement algorithm
	logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumberOut;

endinterface : TestInterface
