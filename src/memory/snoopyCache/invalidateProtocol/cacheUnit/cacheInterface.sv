//resetthese are adjusted index and tag widths, not originals
interface CacheInterface#(
	int TAG_WIDTH            = 6,
	int INDEX_WIDTH          = 6,
	int OFFSET_WIDTH         = 4,
	int SET_ASSOCIATIVITY    = 2,
	int DATA_WIDTH           = 16,
	type STATE_TYPE          = logic[1 : 0],
	STATE_TYPE INVALID_STATE = 2'b0
)();

	//cpu controller ports
	logic[INDEX_WIDTH - 1       : 0] cpuIndex;
	logic[OFFSET_WIDTH - 1      : 0] cpuOffset;
	logic[TAG_WIDTH - 1         : 0] cpuTagIn, cpuTagOut;
	logic[DATA_WIDTH - 1        : 0] cpuDataIn, cpuDataOut;
	logic[SET_ASSOCIATIVITY - 1 : 0] cpuCacheNumber;
	STATE_TYPE                  		 cpuStateIn, cpuStateOut;
	logic                       		 cpuHit, cpuWriteTag, cpuWriteData, cpuWriteState;

	//snoopy controller ports
	logic[INDEX_WIDTH - 1       : 0] snoopyIndex;
	logic[OFFSET_WIDTH - 1      : 0] snoopyOffset;
	logic[TAG_WIDTH - 1         : 0] snoopyTagIn;
	logic[DATA_WIDTH - 1        : 0] snoopyDataOut;
	logic[SET_ASSOCIATIVITY - 1 : 0] snoopyCacheNumber;
	STATE_TYPE                  		 snoopyStateIn, snoopyStateOut;
	logic                       		 snoopyHit, snoopyWriteState;

	modport cache (
		input cpuIndex, cpuOffset, cpuTagIn, cpuDataIn, cpuStateIn, cpuWriteTag, cpuWriteData, cpuWriteState, snoopyIndex, snoopyOffset, snoopyTagIn, snoopyStateIn,
		snoopyWriteState,
		output cpuTagOut, cpuDataOut, cpuCacheNumber, cpuStateOut, cpuHit, snoopyDataOut, snoopyCacheNumber, snoopyStateOut, snoopyHit
	);

	modport controller (
		input cpuTagOut, cpuDataOut, cpuCacheNumber, cpuStateOut, cpuHit, snoopyDataOut, snoopyCacheNumber, snoopyStateOut, snoopyHit,
		output cpuIndex, cpuOffset, cpuTagIn, cpuDataIn, cpuStateIn, cpuWriteTag, cpuWriteData, cpuWriteState, snoopyIndex, snoopyOffset, snoopyTagIn, snoopyStateIn,
		snoopyWriteState
	);
	
endinterface : CacheInterface
