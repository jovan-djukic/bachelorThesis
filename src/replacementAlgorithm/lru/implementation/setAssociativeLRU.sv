module SetAssociativeLRU#(
	int INDEX_WIDTH = 6
)(
	ReplacementAlgorithmInterface.slave replacementAlgorithmInterface,
	input logic[INDEX_WIDTH - 1 : 0] cpuIndexIn, snoopyIndexIn,
	input logic clock, reset
);

	localparam NUMBER_INDIVIDUAL_LRUS	=	1 << INDEX_WIDTH;

	ReplacementAlgorithmInterface#(
		.NUMBER_OF_CACHE_LINES(replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES)
	) replacementAlgorithmInterfaces[NUMBER_INDIVIDUAL_LRUS]();

	LRU lrus[NUMBER_INDIVIDUAL_LRUS] (
		.replacementAlgorithmInterface(replacementAlgorithmInterfaces),
		.clock(clock),
		.reset(reset)
	);

	//LRU_INPUTS_BEGIN
	//lastAccessedCacheLine goes in each lru module
	genvar i;
	generate
		for (i = 0; i < NUMBER_INDIVIDUAL_LRUS; i++) begin
			assign replacementAlgorithmInterfaces[i].lastAccessedCacheLine = replacementAlgorithmInterface.lastAccessedCacheLine;
			assign replacementAlgorithmInterfaces[i].invalidatedCacheLine  = replacementAlgorithmInterface.invalidatedCacheLine;
		end
	endgenerate

	//multiplexers for enable signals
	//accessEnable multiplexer
	logic accessEnables[NUMBER_INDIVIDUAL_LRUS];
	generate
		for (i = 0; i < NUMBER_INDIVIDUAL_LRUS; i++) begin
			assign replacementAlgorithmInterfaces[i].accessEnable = accessEnables[i]; 
		end
	endgenerate
	always_comb begin
		for (int i = 0; i < NUMBER_INDIVIDUAL_LRUS; i++) begin
			if (cpuIndexIn == i) begin
				accessEnables[i] = replacementAlgorithmInterface.accessEnable;
			end else begin
				accessEnables[i] = 0;
			end
		end
	end

	//invalidateEnable multiplexer
	logic invalidateEnables[NUMBER_INDIVIDUAL_LRUS];
	generate
		for (i = 0; i < NUMBER_INDIVIDUAL_LRUS; i++) begin
			assign replacementAlgorithmInterfaces[i].invalidateEnable = invalidateEnables[i]; 
		end
	endgenerate
	always_comb begin
		for (int i = 0; i < NUMBER_INDIVIDUAL_LRUS; i++) begin
			if (snoopyIndexIn == i) begin
				invalidateEnables[i] = replacementAlgorithmInterface.invalidateEnable;
			end else begin
				invalidateEnables[i] = 0;
			end
		end
	end
	//LRU_INPUTS_END

	//LRU_OUTPUTS_BEGIN 
	//replacementCacheLine demultiplexer
	logic[replacementAlgorithmInterface.COUNTER_WIDTH - 1 : 0] replacementCacheLines[NUMBER_INDIVIDUAL_LRUS];
	generate
		for (i = 0; i < NUMBER_INDIVIDUAL_LRUS; i++) begin
			assign replacementCacheLines[i] = replacementAlgorithmInterfaces[i].replacementCacheLine;
		end
	endgenerate
	always_comb begin
		for (int i = 0; i < NUMBER_INDIVIDUAL_LRUS; i++) begin
			if (cpuIndexIn == i) begin
				replacementAlgorithmInterface.replacementCacheLine = replacementCacheLines[i];
			end
		end
	end

	//LRU_OUTPUTS_END
endmodule : SetAssociativeLRU
