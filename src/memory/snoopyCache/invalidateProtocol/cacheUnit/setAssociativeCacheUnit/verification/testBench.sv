module TestBench();
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)				
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	SetAssociativeCacheUnit#(
		.STATE_TYPE(STATE_TYPE)
	)	setAssociativeCacheUnit(
		.cpuCacheInterface(testInterface.cpuCacheInterface),
		.snoopyCacheInterface(testInterface.snoopyCacheInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)				
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);
		run_test("CacheUnitTest");
	end
endmodule : TestBench
