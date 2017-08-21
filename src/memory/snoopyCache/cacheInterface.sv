interface CacheInterface#(
	type STATE_TYPE  = logic[1 : 0],
	int TAG_WIDTH    = 6,
	int INDEX_WIDTH  = 6,
	int OFFSET_WIDTH = 4,
	int DATA_WIDTH	 = 16
)();

	//cpu controller ports
	logic[INDEX_WIDTH - 1  : 0] cpuIndex;
	logic[OFFSET_WIDTH - 1 : 0] cpuOffset;
	logic[TAG_WIDTH - 1    : 0] cpuTagIn, cpuTagOut;
	logic[DATA_WIDTH - 1   : 0] cpuDataIn, cpuDataOut;
	STATE_TYPE                  cpuStateIn, cpuStateOut;
	logic                       cpuHit, cpuWriteTag, cpuWriteData, cpuWriteState;

	//snoopy controller ports
	logic[INDEX_WIDTH - 1  : 0] snoopyIndex;
	logic[OFFSET_WIDTH - 1 : 0] snoopyOffset;
	logic[TAG_WIDTH - 1    : 0] snoopyTagIn;
	logic[DATA_WIDTH - 1   : 0] snoopyDataOut;
	STATE_TYPE                  snoopyStateIn, snoopyStateOut;
	logic                       snoopyHit, snoopyWriteState;

	modport slave (
		input cpuIndex, cpuOffset, cpuTagIn, cpuDataIn, cpuStateIn, cpuWriteTag, cpuWriteData, cpuWriteState, snoopyIndex, snoopyOffset, snoopyTagIn, snoopyStateIn,
		snoopyWriteState,
		output cpuTagOut, cpuDataOut, cpuStateOut, cpuHit, snoopyDataOut, snoopyStateOut, snoopyHit
	);
	
endinterface : CacheInterface
