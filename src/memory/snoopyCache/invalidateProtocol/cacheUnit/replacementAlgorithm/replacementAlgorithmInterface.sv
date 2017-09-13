interface ReplacementAlgorithmInterface #(
	parameter NUMBER_OF_CACHE_LINES,
	parameter COUNTER_WIDTH         = NUMBER_OF_CACHE_LINES <= 2   ? 1 :
																		NUMBER_OF_CACHE_LINES <= 4   ? 2 :
																		NUMBER_OF_CACHE_LINES <= 8   ? 3 : 
																		NUMBER_OF_CACHE_LINES <= 16  ? 4 : 
																		NUMBER_OF_CACHE_LINES <= 32  ? 5 :
																		NUMBER_OF_CACHE_LINES <= 64  ? 6 :
																		NUMBER_OF_CACHE_LINES <= 128 ? 7 : 8
)();

	logic [COUNTER_WIDTH - 1 : 0] lastAccessedCacheLine, invalidatedCacheLine, replacementCacheLine;
	logic                         accessEnable, invalidateEnable;  

	modport slave (
		input lastAccessedCacheLine, invalidatedCacheLine, accessEnable, invalidateEnable,
		output replacementCacheLine
	);
endinterface
