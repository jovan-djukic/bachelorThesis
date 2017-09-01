interface BusInterface#(
	int NUMBER_OF_CACHES   = 4,
	int CACHE_NUMBER_WIDTH = $clog2(NUMBER_OF_CACHES)
)();
	import busCommands::*;

	BusCommand cpuCommandOut, cpuCommandIn;
	BusCommand snoopyCommandIn, snoopyCommandOut;
	logic[CACHE_NUMBER_WIDTH - 1 : 0] cacheNumberIn, cacheNumberOut;

	modport controller (
		input  snoopyCommandIn, cpuCommandIn, cacheNumberIn,
		output cpuCommandOut, snoopyCommandOut, cacheNumberOut
	);
	
	modport bus (
		input cpuCommandOut, snoopyCommandOut, cacheNumberOut,
		output snoopyCommandIn, cpuCommandIn, cacheNumberIn
	);
endinterface : BusInterface
