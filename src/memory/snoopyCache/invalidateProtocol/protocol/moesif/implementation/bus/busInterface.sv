interface BusInterface();
	
	import types::*;

	logic sharedIn;
	logic sharedOut, forwardOut;
	BusCommand cpuCommandOut;
	BusCommand snoopyCommandIn;

	modport controller (
		input sharedIn, snoopyCommandIn,
		output cpuCommandOut, forwardOut, sharedOut
	);
	
	modport bus (
		input cpuCommandOut, forwardOut, sharedOut,
		output sharedIn, snoopyCommandIn
	);
endinterface : BusInterface
