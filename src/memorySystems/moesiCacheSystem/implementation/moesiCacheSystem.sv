module MOESICacheSystem#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH,
	int TAG_WIDTH,
	int INDEX_WIDTH,
	int OFFSET_WIDTH,
	int SET_ASSOCIATIVITY,
	int NUMBER_OF_DEVICES
)(
	MemoryInterface.slave deviceMemoryInterface[NUMBER_OF_DEVICES],
	MemoryInterface.master ramMemoryInterface,
	input logic clock, reset
);
	import MOESIStates::*;
	genvar i;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cacheBusCPUMemoryInterface[NUMBER_OF_DEVICES]();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) busRamMemoryInterface();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cacheBusSnoopyMemoryInterface[NUMBER_OF_DEVICES]();
	MOESIInterface moesifInterface[NUMBER_OF_DEVICES]();
	CPUCommandInterface cacheBusCPUCommandInterface[NUMBER_OF_DEVICES]();
	SnoopyCommandInterface cacheBusSnoopyCommandInterface[NUMBER_OF_DEVICES]();
	ArbiterInterface cpuArbiterInterface[NUMBER_OF_DEVICES](), snoopyArbiterInterface[NUMBER_OF_DEVICES]();

	generate
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			CPUProtocolInterface#(
				.STATE_TYPE(CacheLineState)
			) cpuProtocolInterface();

			SnoopyProtocolInterface#(
				.STATE_TYPE(CacheLineState)
			) snoopyProtocolInterface();

			MOESI moesif(
				.cpuProtocolInterface(cpuProtocolInterface),
				.snoopyProtocolInterface(snoopyProtocolInterface),
				.moesifInterface(moesifInterface[i])
			);

			Cache#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.STATE_TYPE(CacheLineState),
				.INVALID_STATE(INVALID)
			)	cache(
				.cpuSlaveInterface(deviceMemoryInterface[i]),
				.cpuMasterInterface(cacheBusCPUMemoryInterface[i]),
				.cpuProtocolInterface(cpuProtocolInterface),
				.cpuCommandInterface(cacheBusCPUCommandInterface[i]),
				.cpuArbiterInterface(cpuArbiterInterface[i]),
				.snoopySlaveInterface(cacheBusSnoopyMemoryInterface[i]),
				.snoopyProtocolInterface(snoopyProtocolInterface),
				.snoopyCommandInterface(cacheBusSnoopyCommandInterface[i]),
				.snoopyArbiterInterface(snoopyArbiterInterface[i]),
				.clock(clock),
				.reset(reset)
			);
		end
	endgenerate
	//arbiters
	Arbiter#(
		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
	) arbiter(
		.arbiterInterfaces(cpuArbiterInterface),
		.clock(clock),
		.reset(reset)
	);

	logic[NUMBER_OF_DEVICES - 1 : 0] cpuGrants, snoopyGrants;
	generate
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign cpuGrants[i] = cpuArbiterInterface[i].grant;
			assign snoopyArbiterInterface[i].grant = snoopyArbiterInterface[i].request;
			assign snoopyGrants[i] = snoopyArbiterInterface[i].grant;
		end
	endgenerate

	//moesif protocol bus
	logic sharedIn;
	logic[NUMBER_OF_DEVICES - 1 : 0] sharedOuts;
	generate
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign sharedOuts[i] = moesifInterface[i].sharedOut;
		end
	endgenerate
	assign sharedIn = (| sharedOuts) == 1 ? 1 : 0;
	generate
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign moesifInterface[i].sharedIn = sharedIn;
		end
	endgenerate

	//bus
	SnoopyBus#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.NUMBER_OF_CACHES(NUMBER_OF_DEVICES)
	) snoopyBus(
		.cpuSlaveMemoryInterface(cacheBusCPUMemoryInterface),
		.cpuBusCommandInterface(cacheBusCPUCommandInterface),
		.snoopyMasterReadMemoryInterface(cacheBusSnoopyMemoryInterface),
		.snoopyBusCommandInterface(cacheBusSnoopyCommandInterface),
		.cpuGrants(cpuGrants),
		.snoopyGrants(snoopyGrants),
		.ramMemoryInterface(ramMemoryInterface)
	);
endmodule : MOESICacheSystem
