module TestBench();
	
	import uvm_pkg::*;
	import baseTestPackage::*;
	import simpleWriteTestPackage::*;
	import types::*;

	TestInterface#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	MOESIFController#(
		.CACHE_ID(CACHE_ID)
	) moesifController(
		.cpuSlaveInterface(testInterface.cpuSlaveInterface),
		.cpuMasterInterface(testInterface.cpuMasterInterface),
		.snoopySlaveInterface(testInterface.snoopySlaveInterface),
		.cacheInterface(testInterface.cacheInterface),
		.busInterface(testInterface.busInterface),
		.cpuArbiterInterface(testInterface.cpuArbiterInterface),
		.snoopyArbiterInterface(testInterface.snoopyArbiterInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
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
		automatic SimpleCacheWriteTestItemFactory testFactory = new();
			
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
		))::set(uvm_root::get(), "*", TEST_INTERFACE_NAME, testInterface);

		uvm_config_db#(BaseTestItemFactory#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
		))::set(uvm_root::get(), "*", TEST_FACTORY_NAME, testFactory);

		run_test("SimpleCacheWriteTest");
	end
endmodule : TestBench
