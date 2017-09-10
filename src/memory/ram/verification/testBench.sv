module TestBench();
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(ADDRESS_WIDTH, DATA_WIDTH) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	RAM#(
		.DATA_WIDTH(DATA_WIDTH),
		.SIZE_IN_WORDS(SIZE),
		.DELAY(4)
	) ram(
		.memoryInterface(testInterface.memoryInterface),
		.clock(testInterface.clock)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(ADDRESS_WIDTH, DATA_WIDTH))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);
		run_test("MemoryTest");
	end
endmodule : TestBench
