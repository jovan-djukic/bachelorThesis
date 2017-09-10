module TestBench();
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	SnoopyController#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH)
	)snoopyController(
		.slaveInterface(testInterface.slaveInterface),
		.cacheInterface(testInterface.cacheInterface),
		.protocolInterface(testInterface.protocolInterface),
		.commandInterface(testInterface.commandInterface),
		.arbiterInterface(testInterface.arbiterInterface),
		.invalidateEnable(testInterface.invalidateEnable),
		.reset(testInterface.reset),
		.clock(testInterface.clock)
	);

	SetAssociativeCacheUnit#(
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) setAssociativeCacheUnit(
		.cpuCacheInterface(testInterface.cpuCacheInterface),
		.snoopyCacheInterface(testInterface.cacheInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	CPUProtocolInterface#(
		.STATE_TYPE(STATE_TYPE)
	) cpuProtocolInterface();

	WriteThroughInvalidate writeThroughInvalidate(
		.cpuProtocolInterface(cpuProtocolInterface),
		.snoopyProtocolInterface(testInterface.protocolInterface)
	);

	initial begin
			
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("SnoopyControllerTest");
	end
endmodule : TestBench
