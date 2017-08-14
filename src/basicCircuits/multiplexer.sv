module Multiplexer#(
	type PORT_TYPE = logic[0 : 0],
	int NUMBER_OF_INPUTS 		= 4,
	int SELECT_SIGNAL_WIDTH	= NUMBER_OF_INPUTS <= 4		? 2 :
														NUMBER_OF_INPUTS <= 8		? 3 :
														NUMBER_OF_INPUTS <= 16	? 4 : 
														NUMBER_OF_INPUTS <= 32	? 5 : 
														NUMBER_OF_INPUTS <= 62	? 6 :
														NUMBER_OF_INPUTS <= 128 ? 7 :
														NUMBER_OF_INPUTS <= 256 ? 8 :
														NUMBER_OF_INPUTS <= 512 ? 9 : 10
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
