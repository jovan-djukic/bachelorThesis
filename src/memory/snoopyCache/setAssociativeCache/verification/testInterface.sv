interface TestInterface#(
	int TAG_WIDTH            = 6,
	int INDEX_WIDTH          = 6,
	int OFFSET_WIDTH         = 4,
	int SET_ASSOCIATIVITY    = 2,
	int DATA_WIDTH           = 16,
	type STATE_TYPE          = logic[1 : 0],
	STATE_TYPE INVALID_STATE = 2'b0
);
	
	CacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) cacheInterface();
	logic[SET_ASSOCIATIVITY - 1 : 0] cpuCacheNumber, snoopyCacheNumber;
	bit accessEnable, invalidateEnable, clock, reset;

endinterface : TestInterface
