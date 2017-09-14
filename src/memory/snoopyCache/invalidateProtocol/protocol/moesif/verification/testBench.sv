module TestBench();
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(
		.STATE_TYPE(STATE_TYPE)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	MOESIF moesif(
		.cpuProtocolInterface(testInterface.cpuProtocolInterface),
		.snoopyProtocolInterface(testInterface.snoopyProtocolInterface),
		.moesifInterface(testInterface.moesifInterface)
	);

	initial begin
			
		uvm_config_db#(virtual TestInterface#(
			.STATE_TYPE(STATE_TYPE)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("MOESIFTest");
	end
endmodule : TestBench
