interface ArbiterInterface();

	logic request;
	logic grant;

	modport device (
		input grant,
		output request
	);

	modport arbiter (
		input request,
		output grant
	);
	
endinterface : ArbiterInterface
