module SetAssociativeCache#(
	int TAG_WIDHT            = 6,
	int INDEX_WIDTH          = 6,
	int OFFSET_WIDTH         = 4,
	int SET_ASSOCIATIVITY    = 2,
	int DATA_WIDTH           = 16,
	type STATE_TYPE          = logic[1 : 0],
	STATE_TYPE INVALID_STATE = 2'b0
)(
	CacheInterface.slave cacheInterface,
	output logic[SET_ASSOCIATIVITY - 1 : 0] cpuCacheNumber, snoopyCacheNumber,
	input logic accessEnable, invalidateEnable, clock, reset
);

	//generate variables
	genvar i;

	//adjusted parameters for direct mapping cache units
	localparam ADJUSTED_TAG_WIDTH   = TAG_WIDHT + SET_ASSOCIATIVITY;
	localparam ADJUSTED_INDEX_WIDTH = INDEX_WIDTH - SET_ASSOCIATIVITY;

	//REPLACEMENT_ALGORITHM_BEGIN
	//parameters need for replacement algorithms
	localparam NUMBER_OF_CACHE_LINES = 1 << ADJUSTED_INDEX_WIDTH;

	ReplacementAlgorithmInterface#(
		.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)	
	) replacementAlgorithmInterface();

	SetAssociativeLRU#(
		.INDEX_WIDTH(INDEX_WIDTH)
	) setAssociativeLRU(
		.replacementAlgorithmInterface(replacementAlgorithmInterface),
		.cpuIndexIn(cache.cpuIndex),
		.snoopyIndexIn(cache.snoopyIndex),
		.clock(clock),
		.reset(reset)
	);

	//assigns for control signals of replacement algorithm
	assign replacementAlgorithmInterface.accessEnable     = accessEnable;
	assign replacementAlgorithmInterface.invalidateEnable = invalidateEnable;

	//REPLACEMENT_ALGORITHM_END

	//CACHE_UNITS_BEGIN
	//parameters required for cache units
	localparam NUMBER_OF_SMALLER_CACHES = 1 << SET_ASSOCIATIVITY;

	CacheInterface#(
		.TAG_WIDHT(ADJUSTED_TAG_WIDTH),
		.INDEX_WIDTH(ADJUSTED_INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE)
	) cacheInterfaces[NUMBER_OF_SMALLER_CACHES]();
	
	DirectMappintCacheUnit#(
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) directMappingCacheUnits[NUMBER_OF_SMALLER_CACHES](
		.cacheInterface(cacheInterfaces),
		.clock(clock),
		.reset(reset)
	);

	//input signals assigns
	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//cpu controller assings
			assign cacheInterfaces[i].cpuIndex   = cacheInterface.cpuIndex;
			assign cacheInterfaces[i].spuOffset  = cacheInterface.cpuOffset;
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

	//encoders for cache numbers
	//cpu encoder
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (cpuIndividualHitSignals[i] == 1) begin
				cpuCacheNumber = i;
			end
		end
	end
	//snoopy encoder
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (snoopyIndividualHitSignals[i] == 1) begin
				snoopyCacheNumber = i;
			end
		end
	end
	
	//multiplexers for out signals
	//helper signals 
	logic[ADJUSTED_TAG_WIDTH - 1 : 0] cpuTagOuts[NUMBER_OF_SMALLER_CACHES];
	logic[DATA_WIDTH - 1         : 0] cpuDataOuts[NUMBER_OF_SMALLER_CACHES];
	STATE_TYPE cpuStateOuts[NUMBER_OF_SMALLER_CACHES], snoopyStateOuts[NUMBER_OF_SMALLER_CACHES];

	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//cpu controller helper signal assigns
			assign cpuTagOuts[i]   = cacheInterfaces[i].cpuTagOut;
			assign cpuDataOuts[i]  = cacheInterfaces[i].cpuDataOut;
			assign cpuStateOuts[i] = cacheInterfaces[i].cpuStateOut;
			
			//snoopy controller helper singal assigns
			assign snoopyStateOuts[i] = cacheInterfaces[i].snoopyStateOut;
		end
	endgenerate

	//cpu controller multiplexer
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (cpuCacheNumber == i) begin
				cacheInterface.cpuTagOut   = cpuTagOuts[i];
				cacheInterface.cpuDataOut  = cpuDataOuts[i];
				cacheInterface.cpuStateOut = cpuStateOuts[i];
			end
		end
	end

	//snoopy controller multiplexer
	always_comb begin
		for (int i = 0; i< NUMBER_OF_SMALLER_CACHES; i++) begin
			if (snoopyCacheNumber == i) begin
				cacheInterface.snoopyStateOut = snoopyStateOuts[i];
			end
		end
	end
	//HIT_AND_CONTROL_LOGIC_END
endmodule : SetAssociativeCache
