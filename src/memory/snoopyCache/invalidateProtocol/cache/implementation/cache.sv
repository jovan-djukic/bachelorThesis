module Cache#(
	int ADDRESS_WIDTH        = 16,
	int DATA_WIDTH           = 16,
	int TAG_WIDTH            = 6,
	int INDEX_WIDTH          = 6,
	int OFFSET_WIDTH         = 4,
	int SET_ASSOCIATIVITY    = 2,
	type STATE_TYPE          = logic[1 : 0],
	STATE_TYPE INVALID_STATE = 2'b0
)(
	MemoryInterface.slave cpuSlaveInterface,
	MemoryInterface.master cpuMasterInterface,
	CPUProtocolInterface.controller cpuProtocolInterface,
	CPUCommandInterface.controller cpuCommandInterface,
	ArbiterInterface.device cpuArbiterInterface,

	ReadMemoryInterface.slave snoopySlaveInterface,
	SnoopyProtocolInterface.controller snoopyProtocolInterface,
	SnoopyCommandInterface.controller snoopyCommandInterface,
	ArbiterInterface.device snoopyArbiterInterface,
	input logic clock, reset
);

	logic accessEnable, invalidateEnable;

	CPUCacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) cpuCacheInterface();

	SnoopyCacheInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) snoopyCacheInterface();

	SetAssociativeCacheUnit#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) setAssociativeCache(
		.cpuCacheInterface(cpuCacheInterface),
		.snoopyCacheInterface(snoopyCacheInterface),
		.accessEnable(accessEnable),
		.invalidateEnable(invalidateEnable),
		.clock(clock),
		.reset(reset)
	);

	//concurrencty lock
	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cpuMasterMemoryInterface();

	CPUCommandInterface cpuBusCommandInterface();

	ArbiterInterface cpuArbiterArbiterInterface();

	SnoopyCommandInterface snoopyBusCommandInterface();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) snoopyMasterReadMemoryInterface();	

	logic cpuHit, snoopyHit;
	assign cpuHit    = cpuCacheInterface.hit;
	assign snoopyHit = snoopyCacheInterface.hit;

	ConcurrencyLock#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH)
	) concurrencyLock(
		.cpuSlaveMemoryInterface(cpuSlaveInterface),
		.cpuMasterMemoryInterface(cpuMasterMemoryInterface),
		.cpuBusCommandInterface(cpuBusCommandInterface),
		.cpuControllerCommandInterface(cpuCommandInterface),
		.cpuArbiterArbiterInterface(cpuArbiterArbiterInterface),
		.cpuDeviceArbiterInterface(cpuArbiterInterface),
		.snoopyBusCommandInterface(snoopyBusCommandInterface),
		.snoopyControllerCommandInterface(snoopyCommandInterface),
		.snoopyMasterReadMemoryInterface(snoopyMasterReadMemoryInterface),
		.snoopySlaveReadMemoryInterface(snoopySlaveInterface),
		.cpuHit(cpuHit),
		.snoopyHit(snoopyHit)
	);

	//controllers
	SnoopyController#(
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) snoopyController(
		.slaveInterface(snoopyMasterReadMemoryInterface),
		.cacheInterface(snoopyCacheInterface),
		.protocolInterface(snoopyProtocolInterface),
		.commandInterface(snoopyBusCommandInterface),
		.arbiterInterface(snoopyArbiterInterface),
		.invalidateEnable(invalidateEnable),
		.clock(clock),
		.reset(reset)
	);

	CPUController#(
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) cpuController(
		.slaveInterface(cpuMasterMemoryInterface),
		.masterInterface(cpuMasterInterface),
		.cacheInterface(cpuCacheInterface),
		.protocolInterface(cpuProtocolInterface),
		.commandInterface(cpuBusCommandInterface),
		.arbiterInterface(cpuArbiterArbiterInterface),
		.accessEnable(accessEnable),
		.clock(clock),
		.reset(reset)
	);
endmodule : Cache
