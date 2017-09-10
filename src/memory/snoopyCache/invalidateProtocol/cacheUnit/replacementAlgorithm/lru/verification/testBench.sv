module TestBench();
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(
		.INDEX_WIDTH(INDEX_WIDTH), 
		.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	SetAssociativeLRU#(
		.INDEX_WIDTH(INDEX_WIDTH)
	) setAssociativeLRU(
		.replacementAlgorithmInterface(testInterface.replacementAlgorithmInterface),
		.cpuIndexIn(testInterface.cpuIndexIn),
		.snoopyIndexIn(testInterface.snoopyIndexIn),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(
			.INDEX_WIDTH(INDEX_WIDTH), 
			.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);
		run_test("SetAssociativeLRUTest");
	end
endmodule : TestBench
