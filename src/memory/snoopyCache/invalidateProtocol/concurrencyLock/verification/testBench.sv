module TestBench();
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	ConcurrencyLock#(
		.OFFSET_WIDTH(OFFSET_WIDTH)
	) concurrencyLock(
		.cpuSlaveMemoryInterface(testInterface.cpuSlaveMemoryInterface),
		.cpuMasterMemoryInterface(testInterface.cpuMasterMemoryInterface),
		.cpuBusCommandInterface(testInterface.cpuBusCommandInterface),
		.cpuControllerCommandInterface(testInterface.cpuControllerCommandInterface),
		.cpuArbiterArbiterInterface(testInterface.cpuArbiterArbiterInterface),
		.cpuDeviceArbiterInterface(testInterface.cpuDeviceArbiterInterface),
		.snoopyBusCommandInterface(testInterface.snoopyBusCommandInterface),
		.snoopyControllerCommandInterface(testInterface.snoopyControllerCommandInterface),
		.snoopySlaveReadMemoryInterface(testInterface.snoopySlaveReadMemoryInterface),
		.snoopyMasterReadMemoryInterface(testInterface.snoopyMasterReadMemoryInterface),
		.cpuHit(testInterface.cpuHit),
		.snoopyHit(testInterface.snoopyHit)
	);

	initial begin
			
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("ConcurrencyLockTest");
	end
endmodule : TestBench