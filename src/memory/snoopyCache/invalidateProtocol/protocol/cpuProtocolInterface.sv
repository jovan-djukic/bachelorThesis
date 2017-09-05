interface CPUProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import commands::*;

	logic read, write;
	logic writeBackRequired, invalidateRequired;
	STATE_TYPE stateIn, stateOut;

	modport controller(
		input stateIn, writeBackRequired, invalidateRequired,
		output stateOut, read, write
	);

	modport protocol (
		input stateOut, read, write,
		output stateIn, writeBackRequired, invalidateRequired
	);
endinterface : CPUProtocolInterface
