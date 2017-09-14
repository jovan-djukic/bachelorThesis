interface DUTInterface#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH
)(input bit clock, reset);

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) memoryInterface();

endinterface : DUTInterface
