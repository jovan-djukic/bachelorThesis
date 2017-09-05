interface CPUProtocolInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	import commands::*;

	logic cpuRead, cpuWrite;
	logic writeBackRequired, invalidateRequired;
	STATE_TYPE cpuStateIn, cpuStateOut;

	modport controller(
		input cpuStateIn, writeBackRequired, invalidateRequired,
		output  cpuStateOut, cpuRead, cpuWrite
	);

	modport protocol (
		input  cpuStateOut, cpuRead, cpuWrite,
		output cpuStateIn, writeBackRequired, invalidateRequired
	);
endinterface : CPUProtocolInterface
