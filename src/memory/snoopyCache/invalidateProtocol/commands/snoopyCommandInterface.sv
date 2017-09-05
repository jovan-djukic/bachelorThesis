interface SnoopyCommandInterface#(
	int NUMBER_OF_CACHES   = 4,
	int CACHE_NUMBER_WIDTH = $clog2(NUMBER_OF_CACHES)
)();
	import commands::*;

	Command commandIn;
	logic		isInvalidated; 

	modport controller (
		input  commandIn,
		output isInvalidated
	);
	
	modport bus (
		input isInvalidated,
		output commandIn
	);
endinterface : SnoopyCommandInterface
