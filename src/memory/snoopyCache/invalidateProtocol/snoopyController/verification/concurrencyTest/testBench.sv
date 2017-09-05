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
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	CacheController cacheController(
		.cpuSlaveInterface(testInterface.cpuSlaveInterface),
		.cpuMasterInterface(testInterface.cpuMasterInterface),
		.snoopySlaveInterface(testInterface.snoopySlaveInterface),
		.cacheInterface(testInterface.cacheInterface),
		.protocolInterface(testInterface.protocolInterface),
		.commandInterface(testInterface.commandInterface),
		.cpuArbiterInterface(testInterface.cpuArbiterInterface),
		.snoopyArbiterInterface(testInterface.snoopyArbiterInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);


	initial begin
			
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("ConcurrencyTest");
	end
endmodule : TestBench
