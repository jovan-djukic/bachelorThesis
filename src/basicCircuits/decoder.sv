module Decoder#(
	int INPUT_WIDTH,
	int NUMBER_OF_OUTPUTS = 1 << INPUT_WIDTH
)(
	input logic[INPUT_WIDTH - 1 : 0] inputSignal,
	output logic outputSignals[NUMBER_OF_OUTPUTS]
);

	always_comb begin
		for (int i = 0; i < NUMBER_OF_OUTPUTS; i++) begin
			if (inputSignal == i) begin
				outputSignals[i] = 1;
			end else begin
				outputSignals[i] = 0;
			end
		end
	end

endmodule
