interface SnoopyCommandInterface();
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
