interface CPUProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import commands::*;

	logic read, write;
	logic writeBackRequired, invalidateRequired, readExclusiveRequired;
	STATE_TYPE stateIn, stateOut;

	modport controller(
		input stateIn, writeBackRequired, invalidateRequired, readExclusiveRequired,
		output stateOut, read, write
	);

	modport protocol (
		input stateOut, read, write,
		output stateIn, writeBackRequired, invalidateRequired, readExclusiveRequired
	);
endinterface : CPUProtocolInterface
