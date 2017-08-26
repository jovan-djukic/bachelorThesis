interface TestInterface#(
	int ADDRESS_WITDH     = 32,
	int DATA_WIDTH        = 32,
	int TAG_WIDTH         = 6,
	int INDEX_WIDTH       = 6,
	int OFFSET_WIDTH      = 4,
	int SET_ASSOCIATIVITY = 2
)();

	import types::*;

	MemoryInterface#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH)
	) masterInterface();

	MemoryInterface#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH)
	) slaveInterface();

	CacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.STATE_TYPE(CacheLineState),
		.INVALID_STATE(INVALID)
	) cacheInterface();

	BusInterface busInterface();
	logic accessEnable, invalidateEnable;

	bit clock, reset;

endinterface : TestInterface
