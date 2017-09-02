interface ProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import busCommands::*;

	logic cpuRead, cpuWrite;
	logic writeBackRequired, invalidateRequired;
	STATE_TYPE cpuStateIn, cpuStateOut, snoopyStateIn, snoopyStateOut;
	BusCommand snoopyCommandIn;

	modport controller(
		input cpuStateIn, writeBackRequired, invalidateRequired, snoopyStateIn,
		output  cpuStateOut, cpuRead, cpuWrite, snoopyStateOut, snoopyCommandIn
	);

	modport protocol (
		input  cpuStateOut, cpuRead, cpuWrite, snoopyStateOut, snoopyCommandIn,
		output cpuStateIn, writeBackRequired, invalidateRequired, snoopyStateIn
	);
endinterface : ProtocolInterface
