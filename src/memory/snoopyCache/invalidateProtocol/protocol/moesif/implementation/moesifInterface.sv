interface MOESIFInterface();
	logic sharedIn, sharedOut, ownedIn, ownedOut;

	modport protocol (
		input sharedIn, ownedIn,
		output sharedOut, ownedOut
	);

	modport bus (
		input sharedOut, ownedOut,
		output sharedIn, ownedIn
	);
endinterface : MOESIFInterface
