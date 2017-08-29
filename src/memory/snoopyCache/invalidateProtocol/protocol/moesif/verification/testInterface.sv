interface TestInterface#(
	int ADDRESS_WITDH      = 32,
	int DATA_WIDTH         = 32,
	int TAG_WIDTH          = 16,
	int INDEX_WIDTH        = 8,
	int OFFSET_WIDTH       = 8,
	int SET_ASSOCIATIVITY  = 4,
	int NUMBER_OF_CACHES   = 8,
	int CACHE_NUMBER_WIDTH = $clog2(NUMBER_OF_CACHES)
)();

	import types::*;

	MemoryInterface#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH)
	) cpuMasterInterface();

	MemoryInterface#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH)
	) cpuSlaveInterface();

	ReadMemoryInterface#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH)
	) snoopySlaveInterface();

	CacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(CacheLineState),
		.INVALID_STATE(INVALID)
	) cacheInterface();

	BusInterface#(
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
	) busInterface();

	ArbiterInterface cpuArbiterInterface(), snoopyArbiterInterface();

	logic accessEnable, invalidateEnable;

	bit clock, reset;

endinterface : TestInterface
