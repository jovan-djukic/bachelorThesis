interface TestInterface#(
	int NUMBER_OF_DEVICES
)();
	ArbiterInterface arbiterInterfaces[NUMBER_OF_DEVICES]();

	logic[NUMBER_OF_DEVICES - 1 : 0] requests, grants;

	generate
		genvar i;
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign arbiterInterfaces[i].request = requests[i];
			assign grants[i] = arbiterInterfaces[i].grant;
		end
	endgenerate

	logic reset;
	bit clock;
endinterface : TestInterface
