interface ReplacementAlgorithmInterface #(
	parameter NUMBER_OF_CACHE_LINES = 4,
	parameter COUNTER_WIDTH         = NUMBER_OF_CACHE_LINES <= 4   ? 2 :
																		NUMBER_OF_CACHE_LINES <= 8   ? 3 : 
																		NUMBER_OF_CACHE_LINES <= 16  ? 4 : 
																		NUMBER_OF_CACHE_LINES <= 32  ? 5 :
																		NUMBER_OF_CACHE_LINES <= 64  ? 6 :
																		NUMBER_OF_CACHE_LINES <= 128 ? 7 : 8
)();

	logic [COUNTER_WIDTH - 1 : 0] lastAccessedCacheLine;
	logic [COUNTER_WIDTH - 1 : 0] replacementCacheLine;
	logic                         enable, reset;  

	modport slave (
		input lastAccessedCacheLine, enable, reset,
		output replacementCacheLine
	);
endinterface
