interface TestInterface#(
	int ADDRESS_WIDTH        = 32,
	int DATA_WIDTH           = 32
)();
	import cases::*;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cpuMasterMemoryInterface(), cpuSlaveMemoryInterface();

	CPUCommandInterface cpuBusCommandInterface(), cpuControllerCommandInterface();

	ArbiterInterface cpuArbiterArbiterInterface(), cpuDeviceArbiterInterface();

	SnoopyCommandInterface snoopyBusCommandInterface(), snoopyControllerCommandInterface();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) snoopySlaveReadMemoryInterface(), snoopyMasterReadMemoryInterface();

	logic cpuHit, snoopyHit;

	bit clock;

	ConcurrencyLockCase concurrencyLockCase;	
endinterface : TestInterface
