interface ProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import commands::*;

	logic cpuRead, cpuWrite;
	logic writeBackRequired, invalidateRequired;
	STATE_TYPE cpuStateIn, cpuStateOut, snoopyStateIn, snoopyStateOut;
	Command snoopyCommandIn;

	modport controller(
		input cpuStateIn, writeBackRequired, invalidateRequired, snoopyStateIn,
		output  cpuStateOut, cpuRead, cpuWrite, snoopyStateOut, snoopyCommandIn
	);

	modport protocol (
		input  cpuStateOut, cpuRead, cpuWrite, snoopyStateOut, snoopyCommandIn,
		output cpuStateIn, writeBackRequired, invalidateRequired, snoopyStateIn
	);
endinterface : ProtocolInterface
