interface SnoopyCommandInterface#(
	int NUMBER_OF_CACHES   = 4,
	int CACHE_NUMBER_WIDTH = $clog2(NUMBER_OF_CACHES)
)();
	import commands::*;

	Command snoopyCommandIn, snoopyCommandOut;
	logic[CACHE_NUMBER_WIDTH - 1 : 0] cacheNumberOut;
	logic															isInvalidated; 

	modport controller (
		input  snoopyCommandIn, isInvalidated,
		output snoopyCommandOut, cacheNumberOut
	);
	
	modport bus (
		input snoopyCommandOut, cacheNumberOut,
		output snoopyCommandIn, isInvalidated
	);
endinterface : SnoopyCommandInterface
