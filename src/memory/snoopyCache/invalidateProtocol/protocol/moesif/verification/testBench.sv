module TestBench();
	
	import uvm_pkg::*;
	import simpleReadTestPackage::*;
	import types::*;

	TestInterface#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	MOESIFController moesifController(
		.slaveInterface(testInterface.slaveInterface),
		.masterInterface(testInterface.masterInterface),
		.cacheInterface(testInterface.cacheInterface),
		.busInterface(testInterface.busInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.reset(testInterface.reset),
		.clock(testInterface.clock)
	);

	SetAssociativeCacheUnit#(
		.STATE_TYPE(CacheLineState)
	) setAssociativeCacheUnit(
		.cacheInterface(testInterface.cacheInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		))::set(uvm_root::get(), "*", "TestInterface", testInterface);
		run_test("SimpleCacheReadTest");
	end
endmodule : TestBench
