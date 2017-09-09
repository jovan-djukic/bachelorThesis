module TestBench();
	import uvm_pkg::*;
	import testPackage::*;
	import types::*;

	TestInterface testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	SnoopyBus#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
	) snoopyBus(
		.cpuSlaveMemoryInterface(testInterface.cpuSlaveMemoryInterface),
		.cpuBusCommandInterface(testInterface.cpuBusCommandInterface),
		.snoopyMasterReadMemoryInterface(testInterface.snoopyMasterReadMemoryInterface),
		.snoopyBusCommandInterface(testInterface.snoopyBusCommandInterface),
		.cpuGrants(testInterface.cpuGrants),
		.snoopyGrants(testInterface.snoopyGrants),
		.ramMemoryInterface(testInterface.ramMemoryInterface)
	);

	initial begin
			
		uvm_config_db#(virtual TestInterface)::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("BusTest");
	end
endmodule : TestBench
