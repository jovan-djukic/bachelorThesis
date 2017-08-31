module Demultiplexer#(
	type PORT_TYPE           = logic[0 : 0],
	PORT_TYPE INACTIVE_VALUE = 0,
	int NUMBER_OF_OUTPUTS    = 4,
	int SELECT_WIDTH         = $clog2(NUMBER_OF_OUTPUTS)
)(
	input PORT_TYPE inputSignal,
	input logic[SELECT_WIDTH - 1 : 0] select,
	output PORT_TYPE outputSignals[NUMBER_OF_OUTPUTS]
);

	always_comb begin
		for (int i = 0; i < NUMBER_OF_OUTPUTS; i++) begin
			if (i == select) begin
				outputSignals[i] = inputSignal;
			end else begin
				outputSignals[i] = INACTIVE_VALUE;
			end
		end
	end

endmodule : Demultiplexer
