module TestBench();
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import types::*;	
	import setAssociativeTagMemoryTestPackage::*;

	TestInterface#(
		.STATE_TYPE(State),
		.TAG_WIDTH(ADJUSTED_TAG_WIDTH),
		.INDEX_WIDTH(ADJUSTED_INDEX_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;
		
	SetAssociativeTagMemory#(
		.STATE_TYPE(State),
		.INVALID_STATE(INVALID),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	) setAssociativeTagMemory (
		.tagUnitInterface(testInterface.tagUnitInterface),
		.clock(testInterface.clock),
		.reset(testInterface.reset),
		.cacheNumberIn(testInterface.cacheNumberIn),
		.cacheNumberOut(testInterface.cacheNumberOut)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(
			.STATE_TYPE(State),
			.TAG_WIDTH(ADJUSTED_TAG_WIDTH),
			.INDEX_WIDTH(ADJUSTED_INDEX_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		))::set(uvm_root::get(), "*", "TestInterface", testInterface);
		run_test("TagAccessTest");
	end

endmodule : TestBench
