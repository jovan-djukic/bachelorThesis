interface TestInterface#(
	int ADDRESS_WIDTH        = 32,
	int DATA_WIDTH           = 32,
	int TAG_WIDTH            = 16,
	int INDEX_WIDTH          = 8,
	int OFFSET_WIDTH         = 8,
	int SET_ASSOCIATIVITY    = 4,
	type STATE_TYPE          = logic [1 : 0],
	STATE_TYPE INVALID_STATE = 0
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

endinterface : TestInterface
