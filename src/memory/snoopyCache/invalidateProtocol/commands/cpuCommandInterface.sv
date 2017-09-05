interface CPUCommandInterface#(
	int NUMBER_OF_CACHES   = 4,
	int CACHE_NUMBER_WIDTH = $clog2(NUMBER_OF_CACHES)
)();
	import commands::*;

	Command commandOut;
	logic[NUMBER_OF_CACHES - 1   : 0] isInvalidated;

	modport controller (
		input  isInvalidated,
		output commandOut 
	);
	
	modport bus (
		input commandOut,
		output isInvalidated 
	);
endinterface : CPUCommandInterface
