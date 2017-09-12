module TestBench();
	import uvm_pkg::*;
	import testPackage::*;
	genvar i;

	TestInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cacheBusCPUMemoryInterface[NUMBER_OF_CACHES]();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) busRamMemoryInterface();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cacheBusSnoopyMemoryInterface[NUMBER_OF_CACHES]();
	MOESIFInterface moesifInterface[NUMBER_OF_CACHES]();
	CPUCommandInterface cacheBusCPUCommandInterface[NUMBER_OF_CACHES]();
	SnoopyCommandInterface cacheBusSnoopyCommandInterface[NUMBER_OF_CACHES]();
	ArbiterInterface cpuArbiterInterface[NUMBER_OF_CACHES](), snoopyArbiterInterface[NUMBER_OF_CACHES]();

	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			CPUProtocolInterface#(
				.STATE_TYPE(STATE_TYPE)
			) cpuProtocolInterface();

			SnoopyProtocolInterface#(
				.STATE_TYPE(STATE_TYPE)
			) snoopyProtocolInterface();

			MOESIF moesif(
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
				.STATE_TYPE(STATE_TYPE),
				.INVALID_STATE(INVALID_STATE)
			)	cache(
				.cpuSlaveInterface(testInterface.memoryInterface[i]),
				.cpuMasterInterface(cacheBusCPUMemoryInterface[i]),
				.cpuProtocolInterface(cpuProtocolInterface),
				.cpuCommandInterface(cacheBusCPUCommandInterface[i]),
				.cpuArbiterInterface(cpuArbiterInterface[i]),
				.snoopySlaveInterface(cacheBusSnoopyMemoryInterface[i]),
				.snoopyProtocolInterface(snoopyProtocolInterface),
				.snoopyCommandInterface(cacheBusSnoopyCommandInterface[i]),
				.snoopyArbiterInterface(snoopyArbiterInterface[i]),
				.clock(testInterface.clock),
				.reset(testInterface.reset)
			);
		end
	endgenerate
	//arbiters
	Arbiter#(
		.NUMBER_OF_DEVICES(NUMBER_OF_CACHES)
	) arbiter(
		.arbiterInterfaces(cpuArbiterInterface),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	logic[NUMBER_OF_CACHES - 1 : 0] cpuGrants, snoopyGrants;
	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			assign cpuGrants[i] = cpuArbiterInterface[i].grant;
			assign snoopyArbiterInterface[i].grant = snoopyArbiterInterface[i].request;
			assign snoopyGrants[i] = snoopyArbiterInterface[i].grant;
		end
	endgenerate

	//moesif protocol bus
	logic sharedIn;
	logic[NUMBER_OF_CACHES - 1 : 0] sharedOuts;
	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			assign sharedOuts[i] = moesifInterface[i].sharedOut;
		end
	endgenerate
	assign sharedIn = (| sharedOuts) == 1 ? 1 : 0;
	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			assign moesifInterface[i].sharedIn = sharedIn;
		end
	endgenerate

	//bus
	SnoopyBus#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
	) snoopyBus(
		.cpuSlaveMemoryInterface(cacheBusCPUMemoryInterface),
		.cpuBusCommandInterface(cacheBusCPUCommandInterface),
		.snoopyMasterReadMemoryInterface(cacheBusSnoopyMemoryInterface),
		.snoopyBusCommandInterface(cacheBusSnoopyCommandInterface),
		.cpuGrants(cpuGrants),
		.snoopyGrants(snoopyGrants),
		.ramMemoryInterface(busRamMemoryInterface)
	);

	//ram memory
	RAM#(
		.SIZE_IN_WORDS(SIZE_IN_WORDS)
	) ram(
		.memoryInterface(busRamMemoryInterface),
		.clock(testInterface.clock)
	);

	initial begin
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("MemoryTest");
	end
endmodule : TestBench
