interface MESIFInterface();
	logic sharedIn, sharedOut, ramWriteRequired;

	modport protocol (
		input sharedIn,
		output sharedOut, ramWriteRequired
	);

	modport bus (
		input sharedOut, ramWriteRequired,
		output sharedIn
	);
endinterface : MESIFInterface
