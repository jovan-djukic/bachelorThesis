module WriteBackInvalidateCacheSystem#(
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
	import writeBackInvalidateStates::*;
	genvar i;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cacheBusCPUMemoryInterface[NUMBER_OF_DEVICES]();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) busCacheCPUMemoryInterface[NUMBER_OF_DEVICES]();

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) busRamMemoryInterface();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cacheBusSnoopyMemoryInterface[NUMBER_OF_DEVICES]();
	logic ramWriteRequired[NUMBER_OF_DEVICES];
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

			WriteBackInvalidate writeBackInvalidate(
				.cpuProtocolInterface(cpuProtocolInterface),
				.snoopyProtocolInterface(snoopyProtocolInterface),
				.ramWriteRequired(ramWriteRequired[i])
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

	//bus
	SnoopyBus#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.NUMBER_OF_CACHES(NUMBER_OF_DEVICES)
	) snoopyBus(
		.cpuSlaveMemoryInterface(busCacheCPUMemoryInterface),
		.cpuBusCommandInterface(cacheBusCPUCommandInterface),
		.snoopyMasterReadMemoryInterface(cacheBusSnoopyMemoryInterface),
		.snoopyBusCommandInterface(cacheBusSnoopyCommandInterface),
		.cpuGrants(cpuGrants),
		.snoopyGrants(snoopyGrants),
		.ramMemoryInterface(busRamMemoryInterface)
	);

	logic ramUpdate;
	always_comb begin
		ramUpdate = 0;
		for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
			if (ramWriteRequired[i] == 1) begin
				ramUpdate = 1;
				break;
			end
		end
	end

	logic dataAvailable, functionComplete[NUMBER_OF_DEVICES];
	logic[DATA_WIDTH - 1 : 0] dataIns[NUMBER_OF_DEVICES], dataIn;
	generate
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign functionComplete[i] = cacheBusSnoopyMemoryInterface[i].functionComplete;
			assign dataIns[i]          = cacheBusSnoopyMemoryInterface[i].dataIn;
		end
	endgenerate 
	always_comb begin
		dataAvailable = 0;
		dataIn        = 0;

		for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
			if (snoopyGrants[i] == 1 && functionComplete[i] == 1) begin
				dataAvailable = 1;
				dataIn        = dataIns[i];
				break;
			end
		end
	end
	//ram assigns
	assign ramMemoryInterface.address      = busRamMemoryInterface.address;
	assign ramMemoryInterface.readEnabled  = busRamMemoryInterface.readEnabled;
	assign ramMemoryInterface.writeEnabled = busRamMemoryInterface.writeEnabled == 1 || (ramUpdate == 1 && dataAvailable == 1) ? 1 :0;
	assign ramMemoryInterface.dataOut      = ramUpdate == 0 ? busRamMemoryInterface.dataOut : dataIn;

	assign busRamMemoryInterface.dataIn           = ramMemoryInterface.dataIn;
	assign busRamMemoryInterface.functionComplete = ramMemoryInterface.functionComplete;

	generate 
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign busCacheCPUMemoryInterface[i].address      = cacheBusCPUMemoryInterface[i].address;
			assign busCacheCPUMemoryInterface[i].readEnabled  = cacheBusCPUMemoryInterface[i].readEnabled;
			assign busCacheCPUMemoryInterface[i].writeEnabled = cacheBusCPUMemoryInterface[i].writeEnabled;
			assign busCacheCPUMemoryInterface[i].dataOut      = cacheBusCPUMemoryInterface[i].dataOut;

			assign cacheBusCPUMemoryInterface[i].dataIn           = busCacheCPUMemoryInterface[i].dataIn;
			assign cacheBusCPUMemoryInterface[i].functionComplete = busCacheCPUMemoryInterface[i].functionComplete == 1 && 
																															(ramUpdate == 0 || ramMemoryInterface.functionComplete == 1) ? 1 : 0;
		end
	endgenerate
endmodule : WriteBackInvalidateCacheSystem
