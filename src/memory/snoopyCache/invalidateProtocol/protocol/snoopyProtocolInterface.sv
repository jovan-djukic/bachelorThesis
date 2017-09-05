interface SnoopyProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import commands::*;

	STATE_TYPE stateIn, stateOut;
	Command 	 commandIn;

	modport controller(
		input stateIn,
		output stateOut, commandIn
	);

	modport protocol (
		input  stateOut, commandIn,
		output stateIn
	);
endinterface : SnoopyProtocolInterface
