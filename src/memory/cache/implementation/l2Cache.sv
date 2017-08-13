import types::*;

module L2Cache#(
	int TAG_WIDTH			= 6,
	int INDEX_WIDTH		= 6,
	int OFFSET_WIDTH	= 4
)(
	MemoryInterface.master ramInterface,
);
endmodule
