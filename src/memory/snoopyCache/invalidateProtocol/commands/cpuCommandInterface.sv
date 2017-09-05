interface CpuCommandInterface#(
	int NUMBER_OF_CACHES   = 4,
	int CACHE_NUMBER_WIDTH = $clog2(NUMBER_OF_CACHES)
)();
	import commands::*;

	Command cpuCommandOut, cpuCommandIn;
	logic[CACHE_NUMBER_WIDTH - 1 : 0] cacheNumberIn;
	logic[NUMBER_OF_CACHES - 1   : 0] isInvalidated;

	modport controller (
		input  cpuCommandIn, cacheNumberIn,
		output cpuCommandOut, isInvalidated 
	);
	
	modport bus (
		input cpuCommandOut, isInvalidated,
		output cpuCommandIn, cacheNumberIn
	);
endinterface : CpuCommandInterface
