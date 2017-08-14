module TagUnit#(
	type STATE_TYPE = logic[1 : 0],
	STATE_TYPE INVALID_STATE
)(
	TagUnitInterface.slave tagUnitInterface,
	input logic clock, reset
);

	localparam NUMBER_OF_CACHE_LINES = 1 << tagUnitInterface.INDEX_WIDTH;

	STATE_TYPE state[NUMBER_OF_CACHE_LINES];
	logic[tagUnitInterface.TAG_WIDTH - 1 : 0] tag[NUMBER_OF_CACHE_LINES];

	assign tagUnitInterface.tagOut 		= tag[tagUnitInterface.index];
	assign tagUnitInterface.stateOut	= state[tagUnitInterface.index];
	assign tagUnitInterface.hit				= tag[tagUnitInterface.index] == tagUnitInterface.tagIn && state[tagUnitInterface.index] != INVALID_STATE ? 1 : 0;

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				state[i] <= INVALID_STATE;
			end
		end else begin
			if (tagUnitInterface.writeTag == 1) begin
				tag[tagUnitInterface.index] <= tagUnitInterface.tagIn;
			end	
			if (tagUnitInterface.writeState == 1) begin
				state[tagUnitInterface.index] <= tagUnitInterface.stateIn;
			end
		end
	end
endmodule : TagUnit
