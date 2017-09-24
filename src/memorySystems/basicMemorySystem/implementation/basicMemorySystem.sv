module BasicMemorySystem#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH,
	int NUMBER_OF_DEVICES
)(
	MemoryInterface.slave deviceMemoryInterface[NUMBER_OF_DEVICES],
	MemoryInterface.master ramMemoryInterface,
	input logic clock, reset
);
	ArbiterInterface deviceArbiterInterface[NUMBER_OF_DEVICES]();

	Arbiter#(
		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
	) arbiter(
		.arbiterInterfaces(deviceArbiterInterface),
		.clock(clock),
		.reset(reset)
	);

	BUS#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
	) bus(
		.deviceMemoryInterface(deviceMemoryInterface),
		.deviceArbiterInterface(deviceArbiterInterface),
		.ramMemoryInterface(ramMemoryInterface)
	);
endmodule : BasicMemorySystem
