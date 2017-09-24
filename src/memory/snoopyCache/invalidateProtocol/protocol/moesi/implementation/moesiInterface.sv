interface MOESIInterface();
	logic sharedIn, sharedOut;

	modport protocol (
		input sharedIn, 
		output sharedOut
	);

	modport bus (
		input sharedOut,
		output sharedIn
	);
endinterface : MOESIInterface
