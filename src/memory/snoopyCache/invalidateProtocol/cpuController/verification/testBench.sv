module TestBench();
	import uvm_pkg::*;
	import testPackage::*;
	import commands::*;

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

	CPUController cpuController(
		.slaveInterface(testInterface.slaveInterface),
		.masterInterface(testInterface.masterInterface),
		.cacheInterface(testInterface.cacheInterface),
		.protocolInterface(testInterface.protocolInterface),
		.commandInterface(testInterface.commandInterface),
		.arbiterInterface(testInterface.arbiterInterface),
		.accessEnable(testInterface.accessEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

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
		.STATE_TYPE(STATE_TYPE)
	) setAssociativeCacheUnit(
		.cpuCacheInterface(testInterface.cacheInterface),
		.snoopyCacheInterface(snoopyCacheInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	WriteThroughInvalidate writeThroughInvalidate(
		.cpuProtocolInterface(testInterface.protocolInterface)
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

		run_test("CPUControllerTest");
	end
endmodule : TestBench
