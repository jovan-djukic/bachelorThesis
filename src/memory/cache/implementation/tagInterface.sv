import types::*;

interface TagInterface #(
	int TAG_WIDTH 	= 6,
	int INDEX_WIDTH = 6
);
		
	logic[INDEX_WIDTH - 1 : 0] index;
	logic[TAG_WIDTH - 1   : 0] tagIn, tagOut;
	State				 							 stateIn, stateOut;
	logic											 hit, writeTag, writeState;

	modport tagPort(
		input index, tagIn, stateIn, writeTag, writeState,
		output tagOut, stateOut, hit
	);
endinterface : TagInterface

