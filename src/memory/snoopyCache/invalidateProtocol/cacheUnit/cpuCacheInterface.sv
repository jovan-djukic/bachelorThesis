//these are adjusted index and tag widths, not originals
interface CPUCacheInterface#(
	int TAG_WIDTH,
	int INDEX_WIDTH,
	int OFFSET_WIDTH,
	int SET_ASSOCIATIVITY,
	int DATA_WIDTH,
	type STATE_TYPE,
	STATE_TYPE INVALID_STATE
)();
	logic[INDEX_WIDTH - 1       : 0] index;
	logic[OFFSET_WIDTH - 1      : 0] offset;
	logic[TAG_WIDTH - 1         : 0] tagIn, tagOut;
	logic[DATA_WIDTH - 1        : 0] dataIn, dataOut;
	logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber;
	STATE_TYPE                  		 stateIn, stateOut;
	logic                       		 hit, writeTag, writeData, writeState;

	modport cache (
		input index, offset, tagIn, dataIn, stateIn, writeTag, writeData, writeState, 
		output tagOut, dataOut, cacheNumber, stateOut, hit 
	);

	modport controller (
		input tagOut, dataOut, cacheNumber, stateOut, hit, 
		output index, offset, tagIn, dataIn, stateIn, writeTag, writeData, writeState 
	);
	
endinterface : CPUCacheInterface
