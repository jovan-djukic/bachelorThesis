interface TestInterface#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH   
)();
	import cases::*;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cpuMasterMemoryInterface(), cpuSlaveMemoryInterface();

	CPUCommandInterface cpuBusCommandInterface(), cpuControllerCommandInterface();

	ArbiterInterface cpuArbiterArbiterInterface(), cpuDeviceArbiterInterface(), snoopyArbiterArbiterInterface(), snoopyDeviceArbiterInterface();

	SnoopyCommandInterface snoopyBusCommandInterface(), snoopyControllerCommandInterface();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) snoopySlaveReadMemoryInterface(), snoopyMasterReadMemoryInterface();

	logic cpuHit, snoopyHit, invalidateRequired;

	bit clock;

	ConcurrencyLockCase concurrencyLockCase;	

	logic reset;
endinterface : TestInterface
