interface SnoopyProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import commands::*;

	STATE_TYPE stateIn, stateOut;
	Command 	 commandIn;
	logic request;

	modport controller(
		input stateIn, request,
		output stateOut, commandIn
	);

	modport protocol (
		input  stateOut, commandIn,
		output stateIn, request
	);
endinterface : SnoopyProtocolInterface
