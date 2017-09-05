interface SnoopyProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import commands::*;

	STATE_TYPE snoopyStateIn, snoopyStateOut;
	Command 	 snoopyCommandIn;

	modport controller(
		input snoopyStateIn,
		output  snoopyStateOut, snoopyCommandIn
	);

	modport protocol (
		input  snoopyStateOut, snoopyCommandIn,
		output snoopyStateIn
	);
endinterface : SnoopyProtocolInterface
