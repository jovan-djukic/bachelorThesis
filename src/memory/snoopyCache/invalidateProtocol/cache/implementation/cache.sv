module Cache#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH,
	int TAG_WIDTH,
	int INDEX_WIDTH,
	int OFFSET_WIDTH ,
	int SET_ASSOCIATIVITY,
	type STATE_TYPE,
	STATE_TYPE INVALID_STATE
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

	ArbiterInterface cpuArbiterArbiterInterface(), snoopyArbiterArbiterInterface();

	SnoopyCommandInterface snoopyBusCommandInterface();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) snoopyMasterReadMemoryInterface();	

	logic cpuHit, snoopyHit, invalidateRequired;

	assign cpuHit             = cpuCacheInterface.hit;
	assign snoopyHit          = snoopyCacheInterface.hit;
	assign invalidateRequired = cpuProtocolInterface.invalidateRequired;

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
		.snoopyArbiterArbiterInterface(snoopyArbiterArbiterInterface),
		.snoopyDeviceArbiterInterface(snoopyArbiterInterface),
		.snoopyMasterReadMemoryInterface(snoopyMasterReadMemoryInterface),
		.snoopySlaveReadMemoryInterface(snoopySlaveInterface),
		.cpuHit(cpuHit),
		.snoopyHit(snoopyHit),
		.invalidateRequired(invalidateRequired),
		.clock(clock),
		.reset(reset)
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
		.arbiterInterface(snoopyArbiterArbiterInterface),
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
