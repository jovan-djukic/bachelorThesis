module DirectMappingCacheUnit#(
	int TAG_WIDTH,
	int INDEX_WIDTH,
	int OFFSET_WIDTH,
	int SET_ASSOCIATIVITY,
	int DATA_WIDTH,
	type STATE_TYPE,
	STATE_TYPE INVALID_STATE,
	int CACHE_NUMBER
)(
	CPUCacheInterface.cache cpuCacheInterface,
	SnoopyCacheInterface.cache snoopyCacheInterface,
	input clock, reset
);

	localparam NUMBER_OF_CACHE_LINES    = 1 << INDEX_WIDTH;
	localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

	STATE_TYPE states[NUMBER_OF_CACHE_LINES];
	logic[TAG_WIDTH - 1  : 0] tags[NUMBER_OF_CACHE_LINES];
	logic[DATA_WIDTH - 1 : 0] data[NUMBER_OF_CACHE_LINES][NUMBER_OF_WORDS_PER_LINE];

	//cache number assign
	assign cpuCacheInterface.cacheNumber    = CACHE_NUMBER;
	assign snoopyCacheInterface.cacheNumber = CACHE_NUMBER;

	//cpu controller assigns
	assign cpuCacheInterface.tagOut   = tags[cpuCacheInterface.index];
	assign cpuCacheInterface.stateOut = states[cpuCacheInterface.index];
	assign cpuCacheInterface.hit      = cpuCacheInterface.tagOut == cpuCacheInterface.tagIn && cpuCacheInterface.stateOut != INVALID_STATE ? 1 : 0;
	assign cpuCacheInterface.dataOut  = data[cpuCacheInterface.index][cpuCacheInterface.offset];
	
	//snoopy controller assigns
	assign snoopyCacheInterface.stateOut = states[snoopyCacheInterface.index];
	assign snoopyCacheInterface.hit      = snoopyCacheInterface.tagIn == tags[snoopyCacheInterface.index] && snoopyCacheInterface.stateOut != INVALID_STATE ? 1 : 0;
	assign snoopyCacheInterface.dataOut  = data[snoopyCacheInterface.index][snoopyCacheInterface.offset];

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				states[i] <= INVALID_STATE;
			end
		end else begin
			//cpu controller writes
			if (cpuCacheInterface.writeTag == 1) begin
				tags[cpuCacheInterface.index] <= cpuCacheInterface.tagIn;
			end
			if (cpuCacheInterface.writeState == 1) begin
				states[cpuCacheInterface.index] <= cpuCacheInterface.stateIn;
			end
			if (cpuCacheInterface.writeData == 1) begin
				data[cpuCacheInterface.index][cpuCacheInterface.offset] <= cpuCacheInterface.dataIn;
			end

			//snoopy controller writes
			if (snoopyCacheInterface.writeState == 1) begin
				states[snoopyCacheInterface.index] <= snoopyCacheInterface.stateIn;
			end
		end
	end

endmodule : DirectMappingCacheUnit
