module DirectMappingCacheUnit#(
	type STATE_TYPE  = logic[1 : 0],
	STATE_TYPE INVALID_STATE = 2'b0
)(
	CacheInterface.slave cacheInterface,
	input clock, reset
);

	localparam NUMBER_OF_CACHE_LINES    = 1 << cacheInterface.INDEX_WIDTH;
	localparam NUMBER_OF_WORDS_PER_LINE = 1 << cacheInterface.OFFSET_WIDTH;

	STATE_TYPE states[NUMBER_OF_CACHE_LINES];
	logic[cacheInterface.TAG_WIDTH - 1  : 0] tags[NUMBER_OF_CACHE_LINES];
	logic[cacheInterface.DATA_WIDTH - 1 : 0] data[NUMBER_OF_CACHE_LINES][NUMBER_OF_WORDS_PER_LINE];

	//cpu controller assigns
	assign cacheInterface.cpuTagOut   = tags[cacheInterface.cpuIndex];
	assign cacheInterface.cpuStateOut = states[cacheInterface.cpuIndex];
	assign cacheInterface.cpuHit      = cacheInterface.cpuTagOut == cacheInterface.cpuTagIn && cacheInterface.cpuStateOut != INVALID_STATE ? 1 : 0;
	assign cacheInterface.cpuDataOut  = data[cacheInterface.cpuIndex][cacheInterface.cpuOffset];
	
	//snoopy controller assigns
	assign cacheInterface.snoopyStateOut = states[cacheInterface.snoopyIndex];
	assign cacheInterface.snoopyHit      = cacheInterface.snoopyTagIn == tags[cacheInterface.snoopyIndex] && cacheInterface.snoopyStateOut != INVALID_STATE ? 1 : 0;
	assign cacheInterface.snoopyDataOut  = data[cacheInterface.snoopyIndex][cacheInterface.snoopyOffset];

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				states[i] <= INVALID_STATE;
			end
		end else begin
			//cpu controller writes
			if (cacheInterface.cpuWriteTag == 1) begin
				tags[cacheInterface.cpuIndex] <= cacheInterface.cpuTagIn;
			end
			if (cacheInterface.cpuWriteState == 1) begin
				states[cacheInterface.cpuIndex] <= cacheInterface.cpuStateIn;
			end
			if (cacheInterface.cpuWriteData == 1) begin
				data[cacheInterface.cpuIndex][cacheInterface.cpuOffset] <= cacheInterface.cpuDataIn;
			end

			//snoopy controller writes
			if (cacheInterface.snoopyWriteState == 1) begin
				states[cacheInterface.snoopyIndex] <= cacheInterface.snoopyStateIn;
			end
		end
	end

endmodule : DirectMappingCacheUnit
