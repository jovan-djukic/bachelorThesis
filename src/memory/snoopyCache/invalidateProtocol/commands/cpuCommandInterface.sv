interface CPUCommandInterface();
	import commands::*;

	Command commandOut;
	logic 	isInvalidated;

	modport controller (
		input  isInvalidated,
		output commandOut 
	);
	
	modport bus (
		input commandOut,
		output isInvalidated 
	);
endinterface : CPUCommandInterface
