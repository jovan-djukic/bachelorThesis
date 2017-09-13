interface TestInterface#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH,
	int TAG_WIDTH,
	int INDEX_WIDTH,
	int OFFSET_WIDTH,
	int SET_ASSOCIATIVITY,
	type STATE_TYPE,
	STATE_TYPE INVALID_STATE
)();
	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) masterInterface();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) slaveInterface();

	CPUCacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) cacheInterface();

	CPUCommandInterface commandInterface();

	ArbiterInterface arbiterInterface();

	CPUProtocolInterface#(
		.STATE_TYPE(STATE_TYPE)
	) protocolInterface();

	logic accessEnable, invalidateEnable;

	bit clock, reset;

endinterface : TestInterface
