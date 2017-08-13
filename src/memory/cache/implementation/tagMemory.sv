import types::*;

module TagMemory#(
	int TAG_WIDTH 	= 6,
	int INDEX_WIDTH	= 6
)(
	//input ports
	input logic[INDEX_WIDTH - 1 : 0] index,
	input logic[TAG_WIDTH - 1   : 0] tagIn,
	input State				 							 stateIn,
	input logic											 writeTag, writeState, clock, reset,

	//output ports
	output logic[TAG_WIDTH - 1 : 0] tagOut,
	output State			              stateOut,
	output logic										hit
);

	localparam NUMBER_OF_CACHE_LINES = 1 << INDEX_WIDTH;

	State state[NUMBER_OF_CACHE_LINES];
	logic[TAG_WIDTH - 1 : 0] tag[NUMBER_OF_CACHE_LINES];

	assign tagOut 	= tag[index];
	assign stateOut	= state[index];
	assign hit			= tag[index] == tagIn && state[index] != INVALID;

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				state[i] <= INVALID;
			end
		end else begin
			if (writeTag == 1) begin
				tag[index] <= tagIn;
			end	
			if (writeState == 1) begin
				state[index] <= stateIn;
			end
		end
	end
endmodule
