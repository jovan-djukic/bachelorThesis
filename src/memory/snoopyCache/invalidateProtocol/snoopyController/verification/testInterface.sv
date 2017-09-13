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
	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) slaveInterface();

	SnoopyCacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) cacheInterface();

	CPUCacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) cpuCacheInterface();

	SnoopyCommandInterface commandInterface();

	ArbiterInterface arbiterInterface();

	SnoopyProtocolInterface#(
		.STATE_TYPE(STATE_TYPE)
	) protocolInterface();

	logic accessEnable, invalidateEnable;

	bit clock, reset;

	bit supply;

endinterface : TestInterface
