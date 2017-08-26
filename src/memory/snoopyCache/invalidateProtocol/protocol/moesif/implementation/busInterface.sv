interface BusInterface();
	
	logic sharedIn;

	modport controller (
		input sharedIn
	);
endinterface : BusInterface
