//these are adjusted parameters
module SetAssociativeCacheUnit#(
	type STATE_TYPE          = logic[1 : 0]
)(
	CPUCacheInterface.cache cpuCacheInterface,
	SnoopyCacheInterface.cache snoopyCacheInterface,
	input logic accessEnable, invalidateEnable,
	input logic clock, reset
);

	//generate variables
	genvar i;
	//REPLACEMENT_ALGORITHM_BEGIN
	//parameters need for replacement algorithms
	localparam NUMBER_OF_CACHE_LINES = 1 << cpuCacheInterface.SET_ASSOCIATIVITY;

	ReplacementAlgorithmInterface#(
		.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)	
	) replacementAlgorithmInterface();

	SetAssociativeLRU#(
		.INDEX_WIDTH(cpuCacheInterface.INDEX_WIDTH)
	) setAssociativeLRU(
		.replacementAlgorithmInterface(replacementAlgorithmInterface),
		.cpuIndexIn(cpuCacheInterface.index),
		.snoopyIndexIn(snoopyCacheInterface.index),
		.clock(clock),
		.reset(reset)
	);

	//assigns for control signals of replacement algorithm
	assign replacementAlgorithmInterface.accessEnable          = accessEnable;
	assign replacementAlgorithmInterface.invalidateEnable      = invalidateEnable;
	assign replacementAlgorithmInterface.lastAccessedCacheLine = cpuCacheInterface.cacheNumber;
	assign replacementAlgorithmInterface.invalidatedCacheLine  = snoopyCacheInterface.cacheNumber;

	//REPLACEMENT_ALGORITHM_END

	//CACHE_UNITS_BEGIN
	//parameters required for cache units
	localparam NUMBER_OF_SMALLER_CACHES = 1 << cpuCacheInterface.SET_ASSOCIATIVITY;

	CPUCacheInterface#(
		.TAG_WIDTH(cpuCacheInterface.TAG_WIDTH),
		.INDEX_WIDTH(cpuCacheInterface.INDEX_WIDTH),
		.OFFSET_WIDTH(cpuCacheInterface.OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(cpuCacheInterface.SET_ASSOCIATIVITY),
		.DATA_WIDTH(cpuCacheInterface.DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(cpuCacheInterface.INVALID_STATE)
	) cpuCacheInterfaces[NUMBER_OF_SMALLER_CACHES]();
	
	SnoopyCacheInterface#(
		.TAG_WIDTH(snoopyCacheInterface.TAG_WIDTH),
		.INDEX_WIDTH(snoopyCacheInterface.INDEX_WIDTH),
		.OFFSET_WIDTH(snoopyCacheInterface.OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(snoopyCacheInterface.SET_ASSOCIATIVITY),
		.DATA_WIDTH(snoopyCacheInterface.DATA_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(snoopyCacheInterface.INVALID_STATE)
	) snoopyCacheInterfaces[NUMBER_OF_SMALLER_CACHES]();

	//input signals assigns
	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//generate modules
			DirectMappingCacheUnit#(
				.CACHE_NUMBER(i),
				.STATE_TYPE(STATE_TYPE)
			) directMappingCacheUnit(
				.cpuCacheInterface(cpuCacheInterfaces[i]),
				.snoopyCacheInterface(snoopyCacheInterfaces[i]),
				.clock(clock),
				.reset(reset)
			);
			//cpu controller assings
			assign cpuCacheInterfaces[i].index   = cpuCacheInterface.index;
			assign cpuCacheInterfaces[i].offset  = cpuCacheInterface.offset;
			assign cpuCacheInterfaces[i].tagIn   = cpuCacheInterface.tagIn;
			assign cpuCacheInterfaces[i].dataIn  = cpuCacheInterface.dataIn;
			assign cpuCacheInterfaces[i].stateIn = cpuCacheInterface.stateIn;

			//snoopy controller assings
			assign snoopyCacheInterfaces[i].index   = snoopyCacheInterface.index;
			assign snoopyCacheInterfaces[i].offset  = snoopyCacheInterface.offset;
			assign snoopyCacheInterfaces[i].tagIn   = snoopyCacheInterface.tagIn;
			assign snoopyCacheInterfaces[i].stateIn = snoopyCacheInterface.stateIn;
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
			assign cpuIndividualHitSignals[i]    = cpuCacheInterfaces[i].hit;
			assign snoopyIndividualHitSignals[i] = snoopyCacheInterfaces[i].hit;
		end
	endgenerate	
	//collective hit signal
	assign cpuCacheInterface.hit    = (| cpuIndividualHitSignals);
	assign snoopyCacheInterface.hit = (| snoopyIndividualHitSignals);

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
	assign cpuCacheSelectSignals    = cpuCacheInterface.hit == 1 ? cpuIndividualHitSignals : replacementSelectSignals;
	assign snoopyCacheSelectSignals = snoopyIndividualHitSignals;

	//write control signals
	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//cpu controller write signals
			assign cpuCacheInterfaces[i].writeTag    =  cpuCacheInterface.writeTag == 1 && cpuCacheSelectSignals[i] == 1 ? 1 : 0;
			assign cpuCacheInterfaces[i].writeData   =  cpuCacheInterface.writeData == 1 && cpuCacheSelectSignals[i] == 1 ? 1 : 0;
			assign cpuCacheInterfaces[i].writeState  =  cpuCacheInterface.writeState == 1 && cpuCacheSelectSignals[i] == 1 ? 1 : 0;

			//snoopy controller write signals
			assign snoopyCacheInterfaces[i].writeState = snoopyCacheInterface.writeState == 1 && snoopyCacheSelectSignals[i] == 1 ? 1 : 0;
		end
	endgenerate

	//multiplexers for out signals
	//helper signals 
	logic[cpuCacheInterface.TAG_WIDTH - 1         : 0] cpuTagOuts[NUMBER_OF_SMALLER_CACHES];
	logic[cpuCacheInterface.DATA_WIDTH - 1        : 0] cpuDataOuts[NUMBER_OF_SMALLER_CACHES], snoopyDataOuts[NUMBER_OF_SMALLER_CACHES];
	logic[cpuCacheInterface.SET_ASSOCIATIVITY - 1 : 0] cpuCacheNumbers[NUMBER_OF_SMALLER_CACHES], snoopyCacheNumbers[NUMBER_OF_SMALLER_CACHES];
	STATE_TYPE cpuStateOuts[NUMBER_OF_SMALLER_CACHES], snoopyStateOuts[NUMBER_OF_SMALLER_CACHES];

	generate
		for (i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			//cpu controller helper signal assigns
			assign cpuTagOuts[i]      = cpuCacheInterfaces[i].tagOut;
			assign cpuDataOuts[i]     = cpuCacheInterfaces[i].dataOut;
			assign cpuStateOuts[i]    = cpuCacheInterfaces[i].stateOut;
			assign cpuCacheNumbers[i] = cpuCacheInterfaces[i].cacheNumber;
			
			//snoopy controller helper singal assigns
			assign snoopyDataOuts[i]     = snoopyCacheInterfaces[i].dataOut;
			assign snoopyStateOuts[i]    = snoopyCacheInterfaces[i].stateOut;
			assign snoopyCacheNumbers[i] = snoopyCacheInterfaces[i].cacheNumber;
		end
	endgenerate
	//encoders for cache numbers
	//cpu encoder
	always_comb begin
		cpuCacheInterface.cacheNumber = 0;
		
		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (cpuCacheSelectSignals[i] == 1) begin
				cpuCacheInterface.cacheNumber = cpuCacheNumbers[i];
			end
		end
	end
	//snoopy encoder
	always_comb begin
		snoopyCacheInterface.cacheNumber = 0;

		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (snoopyCacheSelectSignals[i] == 1) begin
				snoopyCacheInterface.cacheNumber = snoopyCacheNumbers[i];
			end
		end
	end
	

	//cpu controller multiplexer
	always_comb begin
		cpuCacheInterface.tagOut   = 0; 
		cpuCacheInterface.dataOut  = 0;
		cpuCacheInterface.stateOut = cpuCacheInterface.INVALID_STATE;

		for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
			if (cpuCacheInterface.cacheNumber == i) begin
				cpuCacheInterface.tagOut   = cpuTagOuts[i];
				cpuCacheInterface.dataOut  = cpuDataOuts[i];
				cpuCacheInterface.stateOut = cpuStateOuts[i];
			end
		end
	end

	//snoopy controller multiplexer
	always_comb begin
		snoopyCacheInterface.stateOut = snoopyCacheInterface.INVALID_STATE;
		snoopyCacheInterface.dataOut  = 0;

		for (int i = 0; i< NUMBER_OF_SMALLER_CACHES; i++) begin
			if (snoopyCacheInterface.cacheNumber == i) begin
				snoopyCacheInterface.stateOut = snoopyStateOuts[i];
				snoopyCacheInterface.dataOut  = snoopyDataOuts[i];
			end
		end
	end
	//HIT_AND_CONTROL_LOGIC_END
endmodule : SetAssociativeCacheUnit
