module TestBench();

	import uvm_pkg::*;
	import setAssociativeLRUTestPackage::*;

	TestInterface#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	SetAssociativeLRU#(
		.INDEX_WIDTH(INDEX_WIDTH)
	) setAssociativeLRU(
		.replacementAlgorithmInterface(testInterface.replacementAlgorithmInterface),
		.indexIn(testInterface.indexIn),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))::set(uvm_root::get(), "*", "TestInterface", testInterface);
		run_test("SetAssociativeLRUTest");
	end
endmodule : TestBench
