//these are adjusted parameters
module SetAssociativeCache#(
	type STATE_TYPE          = logic[1 : 0]
)(
	CacheInterface.cache cacheInterface,
	input logic accessEnable, invalidateEnable, clock, reset
);

	//generate variables
	genvar i;
	//REPLACEMENT_ALGORITHM_BEGIN
	//parameters need for replacement algorithms
	localparam NUMBER_OF_CACHE_LINES = 1 << cacheInterface.SET_ASSOCIATIVITY;

	ReplacementAlgorithmInterface#(
		.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)	
	) replacementAlgorithmInterface();

	SetAssociativeLRU#(
		.INDEX_WIDTH(cacheInterface.INDEX_WIDTH)
	) setAssociativeLRU(
		.replacementAlgorithmInterface(replacementAlgorithmInterface),
		.cpuIndexIn(cacheInterface.cpuIndex),
		.snoopyIndexIn(cacheInterface.snoopyIndex),
		.clock(clock),
		.reset(reset)
	);

	//assigns for control signals of replacement algorithm
	assign replacementAlgorithmInterface.accessEnable          = accessEnable;
	assign replacementAlgorithmInterface.invalidateEnable      = invalidateEnable;
	assign replacementAlgorithmInterface.lastAccessedCacheLine = cacheInterface.cpuCacheNumber;
	assign replacementAlgorithmInterface.invalidatedCacheLine  = cacheInterface.snoopyCacheNumber;

	//REPLACEMENT_ALGORITHM_END

	//CACHE_UNITS_BEGIN
	//parameters required for cache units
	localparam NUMBER_OF_SMALLER_CACHES = 1 << cacheInterface.SET_ASSOCIATIVITY;

	CacheInterface#(
		.TAG_WIDTH(cacheInterface.TAG_WIDTH),
		.INDEX_WIDTH(cacheInterface.INDEX_WIDTH),
		.OFFSET_WIDTH(cacheInterface.OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(cacheInterface.SET_ASSOCIATIVITY),
		.DATA_WIDTH(cacheInterface.DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(cacheInterface.INVALID_STATE)
	) cacheInterfaces[NUMBER_OF_SMALLER_CACHES]();
	
	//input signals assigns
	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//generate modules
			DirectMappingCacheUnit#(
				.CACHE_NUMBER(i),
				.STATE_TYPE(STATE_TYPE)
			) directMappingCacheUnit(
				.cacheInterface(cacheInterfaces[i]),
				.clock(clock),
				.reset(reset)
			);
			//cpu controller assings
			assign cacheInterfaces[i].cpuIndex   = cacheInterface.cpuIndex;
			assign cacheInterfaces[i].cpuOffset  = cacheInterface.cpuOffset;
			assign cacheInterfaces[i].cpuTagIn   = cacheInterface.cpuTagIn;
			assign cacheInterfaces[i].cpuDataIn  = cacheInterface.cpuDataIn;
			assign cacheInterfaces[i].cpuStateIn = cacheInterface.cpuStateIn;

			//snoopy controller assings
			assign cacheInterfaces[i].snoopyIndex   = cacheInterface.snoopyIndex;
			assign cacheInterfaces[i].snoopyOffset  = cacheInterface.snoopyOffset;
			assign cacheInterfaces[i].snoopyTagIn   = cacheInterface.snoopyTagIn;
			assign cacheInterfaces[i].snoopyStateIn = cacheInterface.snoopyStateIn;
		end
	endgenerate	

	//CACHE_UNIT_END

	//HIT_AND_CONTROL_LOGIC_BEGIN
	//hit signal
	//individual hit signals
	logic[NUMBER_OF_SMALLER_CACHES - 1 : 0] cpuIndividualHitSignals;
	logic[NUMBER_OF_SMALLER_CACHES - 1 : 0] snoopyIndividualHitSignals;
	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			assign cpuIndividualHitSignals[i]    = cacheInterfaces[i].cpuHit;
			assign snoopyIndividualHitSignals[i] = cacheInterfaces[i].snoopyHit;
		end
	endgenerate	
	//collective hit signal
	assign cacheInterface.cpuHit    = (| cpuIndividualHitSignals);
	assign cacheInterface.snoopyHit = (| snoopyIndividualHitSignals);

	//select signals
	//cpu controller select signals
	//decoder for replacement cache number
	logic[NUMBER_OF_SMALLER_CACHES - 1 : 0] replacementSelectSignals;
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (replacementAlgorithmInterface.replacementCacheLine == i) begin
				replacementSelectSignals[i] = 1;
			end else begin
				replacementSelectSignals[i] = 0;
			end
		end
	end
	//cache select signals
	logic[NUMBER_OF_SMALLER_CACHES - 1 : 0] cpuCacheSelectSignals, snoopyCacheSelectSignals;
	assign cpuCacheSelectSignals    = cacheInterface.cpuHit == 1 ? cpuIndividualHitSignals : replacementSelectSignals;
	assign snoopyCacheSelectSignals = snoopyIndividualHitSignals;

	//write control signals
	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//cpu controller write signals
			assign cacheInterfaces[i].cpuWriteTag    =  cacheInterface.cpuWriteTag == 1 && cpuCacheSelectSignals[i] == 1 ? 1 : 0;
			assign cacheInterfaces[i].cpuWriteData   =  cacheInterface.cpuWriteData == 1 && cpuCacheSelectSignals[i] == 1 ? 1 : 0;
			assign cacheInterfaces[i].cpuWriteState  =  cacheInterface.cpuWriteState == 1 && cpuCacheSelectSignals[i] == 1 ? 1 : 0;

			//snoopy controller write signals
			assign cacheInterfaces[i].snoopyWriteState = cacheInterface.snoopyWriteState == 1 && snoopyCacheSelectSignals[i] == 1 ? 1 : 0;
		end
	endgenerate

	//multiplexers for out signals
	//helper signals 
	logic[cacheInterface.TAG_WIDTH - 1         : 0] cpuTagOuts[NUMBER_OF_SMALLER_CACHES];
	logic[cacheInterface.DATA_WIDTH - 1        : 0] cpuDataOuts[NUMBER_OF_SMALLER_CACHES], snoopyDataOuts[NUMBER_OF_SMALLER_CACHES];
	logic[cacheInterface.SET_ASSOCIATIVITY - 1 : 0] cpuCacheNumbers[NUMBER_OF_SMALLER_CACHES], snoopyCacheNumbers[NUMBER_OF_SMALLER_CACHES];
	STATE_TYPE cpuStateOuts[NUMBER_OF_SMALLER_CACHES], snoopyStateOuts[NUMBER_OF_SMALLER_CACHES];

	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//cpu controller helper signal assigns
			assign cpuTagOuts[i]      = cacheInterfaces[i].cpuTagOut;
			assign cpuDataOuts[i]     = cacheInterfaces[i].cpuDataOut;
			assign cpuStateOuts[i]    = cacheInterfaces[i].cpuStateOut;
			assign cpuCacheNumbers[i] = cacheInterfaces[i].cpuCacheNumber;
			
			//snoopy controller helper singal assigns
			assign snoopyDataOuts[i]     = cacheInterfaces[i].snoopyDataOut;
			assign snoopyStateOuts[i]    = cacheInterfaces[i].snoopyStateOut;
			assign snoopyCacheNumbers[i] = cacheInterfaces[i].snoopyCacheNumber;
		end
	endgenerate
	//encoders for cache numbers
	//cpu encoder
	always_comb begin
		cacheInterface.cpuCacheNumber = 0;
		
		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (cpuIndividualHitSignals[i] == 1) begin
				cacheInterface.cpuCacheNumber = cpuCacheNumbers[i];
			end
		end
	end
	//snoopy encoder
	always_comb begin
		cacheInterface.snoopyCacheNumber = 0;

		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (snoopyIndividualHitSignals[i] == 1) begin
				cacheInterface.snoopyCacheNumber = snoopyCacheNumbers[i];
			end
		end
	end
	

	//cpu controller multiplexer
	always_comb begin
		cacheInterface.cpuTagOut   = 0; 
		cacheInterface.cpuDataOut  = 0;
		cacheInterface.cpuStateOut = cacheInterface.INVALID_STATE;

		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (cacheInterface.cpuCacheNumber == i) begin
				cacheInterface.cpuTagOut   = cpuTagOuts[i];
				cacheInterface.cpuDataOut  = cpuDataOuts[i];
				cacheInterface.cpuStateOut = cpuStateOuts[i];
			end
		end
	end

	//snoopy controller multiplexer
	always_comb begin
		cacheInterface.snoopyStateOut = cacheInterface.INVALID_STATE;
		cacheInterface.snoopyDataOut  = 0;

		for (int i = 0; i< NUMBER_OF_SMALLER_CACHES; i++) begin
			if (cacheInterface.snoopyCacheNumber == i) begin
				cacheInterface.snoopyStateOut = snoopyStateOuts[i];
				cacheInterface.snoopyDataOut  = snoopyDataOuts[i];
			end
		end
	end
	//HIT_AND_CONTROL_LOGIC_END
endmodule : SetAssociativeCache
