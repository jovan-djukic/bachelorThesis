module TestBench();
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import testPackage::*;

	TestInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) memoryInterface[NUMBER_OF_DEVICES]();
	
	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) ramMemoryInterface();

	generate
		genvar i;
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign memoryInterface[i].address      = testInterface.dutInterface[i].memoryInterface.address;
			assign memoryInterface[i].dataOut      = testInterface.dutInterface[i].memoryInterface.dataOut;
			assign memoryInterface[i].readEnabled  = testInterface.dutInterface[i].memoryInterface.readEnabled;
			assign memoryInterface[i].writeEnabled = testInterface.dutInterface[i].memoryInterface.writeEnabled;

			assign testInterface.dutInterface[i].memoryInterface.dataIn           = memoryInterface[i].dataIn;
			assign testInterface.dutInterface[i].memoryInterface.functionComplete = memoryInterface[i].functionComplete;
		end
	endgenerate

	MESIFCacheSystem#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
	) mesiCahceSystem(
		.deviceMemoryInterface(memoryInterface),
		.ramMemoryInterface(ramMemoryInterface),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	//ram memory
	RAM#(
		.DATA_WIDTH(DATA_WIDTH),
		.SIZE_IN_WORDS(SIZE_IN_WORDS),
		.DELAY(RAM_DELAY),
		.IS_TEST(IS_TEST)
	) ram(
		.memoryInterface(ramMemoryInterface),
		.clock(testInterface.clock)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("MemoryTest");
	end
endmodule : TestBench
