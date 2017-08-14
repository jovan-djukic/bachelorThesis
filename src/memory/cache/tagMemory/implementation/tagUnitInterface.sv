interface TagUnitInterface #(
	type STATE_TYPE = logic[1 : 0],
	int TAG_WIDTH 	= 6,
	int INDEX_WIDTH = 6
);
		
	logic[INDEX_WIDTH - 1 : 0] index;
	logic[TAG_WIDTH - 1   : 0] tagIn, tagOut;
	STATE_TYPE				 				 stateIn, stateOut;
	logic											 hit, writeTag, writeState;

	modport slave(
		input index, tagIn, stateIn, writeTag, writeState,
		output tagOut, stateOut, hit
	);

endinterface : TagUnitInterface

