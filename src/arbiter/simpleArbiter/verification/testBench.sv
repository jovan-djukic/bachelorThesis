module TestBench();
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	Arbiter#(
		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
	) arbiter(
		.arbiterInterfaces(testInterface.arbiterInterfaces)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);
		run_test("ArbiterTest");
	end
endmodule : TestBench
