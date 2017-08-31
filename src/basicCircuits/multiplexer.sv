module Multiplexer#(
	type PORT_TYPE          = logic[0 : 0],
	int NUMBER_OF_INPUTS    = 4,
	int SELECT_SIGNAL_WIDTH = $clog2(NUMBER_OF_INPUTS)
)(
	input PORT_TYPE inputSignals[NUMBER_OF_INPUTS],
	input logic[SELECT_SIGNAL_WIDTH - 1 : 0] select,
	output PORT_TYPE outputSignal
);

	always_comb begin
		outputSignal = 0;
		for (int i = 0; i < NUMBER_OF_INPUTS; i++) begin
			if (i == select) begin
				outputSignal = inputSignals[i];
				break;
			end
		end
	end

endmodule
