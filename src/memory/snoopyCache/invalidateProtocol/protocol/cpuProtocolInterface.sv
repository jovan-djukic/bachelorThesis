interface CPUProtocolInterface#(
	type STATE_TYPE
)();
	import commands::*;

	logic read, write;
	logic writeBackRequired, invalidateRequired, readExclusiveRequired;
	STATE_TYPE stateIn, stateOut, writeBackState;

	modport controller(
		input stateIn, writeBackRequired, invalidateRequired, readExclusiveRequired,
		output stateOut, writeBackState, read, write
	);

	modport protocol (
		input stateOut, writeBackState, read, write,
		output stateIn, writeBackRequired, invalidateRequired, readExclusiveRequired
	);
endinterface : CPUProtocolInterface
