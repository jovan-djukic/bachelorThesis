module DirectMappingCacheUnit#(
	int CACHE_NUMBER = 0,
	type STATE_TYPE  = logic[1 : 0]
)(
	CPUCacheInterface.cache cpuCacheInterface,
	SnoopyCacheInterface.cache snoopyCacheInterface,
	input clock, reset
);

	localparam NUMBER_OF_CACHE_LINES    = 1 << cpuCacheInterface.INDEX_WIDTH;
	localparam NUMBER_OF_WORDS_PER_LINE = 1 << cpuCacheInterface.OFFSET_WIDTH;

	STATE_TYPE states[NUMBER_OF_CACHE_LINES];
	logic[cpuCacheInterface.TAG_WIDTH - 1  : 0] tags[NUMBER_OF_CACHE_LINES];
	logic[cpuCacheInterface.DATA_WIDTH - 1 : 0] data[NUMBER_OF_CACHE_LINES][NUMBER_OF_WORDS_PER_LINE];

	//cache number assign
	assign cpuCacheInterface.cacheNumber    = CACHE_NUMBER;
	assign snoopyCacheInterface.cacheNumber = CACHE_NUMBER;

	//cpu controller assigns
	assign cpuCacheInterface.tagOut   = tags[cpuCacheInterface.index];
	assign cpuCacheInterface.stateOut = states[cpuCacheInterface.index];
	assign cpuCacheInterface.hit      = cpuCacheInterface.tagOut == cpuCacheInterface.tagIn && cpuCacheInterface.stateOut != cpuCacheInterface.INVALID_STATE ? 1 : 0;
	assign cpuCacheInterface.dataOut  = data[cpuCacheInterface.index][cpuCacheInterface.offset];
	
	//snoopy controller assigns
	assign snoopyCacheInterface.stateOut = states[snoopyCacheInterface.index];
	assign snoopyCacheInterface.hit      = snoopyCacheInterface.tagIn == tags[snoopyCacheInterface.index] && 
																				 snoopyCacheInterface.stateOut != snoopyCacheInterface.INVALID_STATE ? 1 : 0;
	assign snoopyCacheInterface.dataOut  = data[snoopyCacheInterface.index][snoopyCacheInterface.offset];

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				states[i] <= cpuCacheInterface.INVALID_STATE;
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
