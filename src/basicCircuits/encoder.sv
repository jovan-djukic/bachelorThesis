module Encoder#(
	int NUMBER_OF_INPUTS = 4,
	int OUTPUT_WIDTH     = $clog2(NUMBER_OF_INPUTS)
)(
	input logic inputSignals[NUMBER_OF_INPUTS],
	output logic[OUTPUT_WIDTH - 1 : 0] outputSignal
);

	always_comb begin
		outputSignal = 0;
		for (int i = 0; i < NUMBER_OF_INPUTS; i++) begin
			if (inputSignals[i] == 1) begin
				outputSignal = i;
			end
		end
	end

endmodule : Encoder
