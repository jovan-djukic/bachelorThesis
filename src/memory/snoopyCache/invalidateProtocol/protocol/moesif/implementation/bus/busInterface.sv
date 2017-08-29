interface BusInterface#(
	int NUMBER_OF_CACHES   = 4,
	int CACHE_NUMBER_WIDTH = $clog2(NUMBER_OF_CACHES)
)();
	
	import types::*;

	logic sharedIn;
	logic sharedOut, forwardOut;
	BusCommand cpuCommandOut, cpuCommandIn;
	BusCommand snoopyCommandIn, snoopyCommandOut;
	logic[CACHE_NUMBER_WIDTH - 1 : 0] cacheNumberIn, cacheNumberOut;

	modport controller (
		input sharedIn, snoopyCommandIn, cpuCommandIn, cacheNumberIn,
		output cpuCommandOut, snoopyCommandOut, forwardOut, sharedOut, cacheNumberOut
	);
	
	modport bus (
		input cpuCommandOut, snoopyCommandOut, forwardOut, sharedOut, cacheNumberOut,
		output sharedIn, snoopyCommandIn, cpuCommandIn, cacheNumberIn
	);
endinterface : BusInterface
