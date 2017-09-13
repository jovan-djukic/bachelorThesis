//these are adjusted index and tag widths, not originals
interface SnoopyCacheInterface#(
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
	logic[TAG_WIDTH - 1         : 0] tagIn;
	logic[DATA_WIDTH - 1        : 0] dataOut;
	logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber;
	STATE_TYPE                  		 stateIn, stateOut;
	logic                       		 hit, writeState;

	modport cache (
		input index, offset, tagIn, stateIn, writeState,
		output dataOut, cacheNumber, stateOut, hit
	);

	modport controller (
		input dataOut, cacheNumber, stateOut, hit,
		output index, offset, tagIn, stateIn, writeState
	);
	
endinterface : SnoopyCacheInterface
