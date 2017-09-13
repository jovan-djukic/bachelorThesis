module Arbiter#(
	int NUMBER_OF_DEVICES,
	int DEVICE_NUMBER_WIDTH = $clog2(NUMBER_OF_DEVICES)
)(
	ArbiterInterface.arbiter arbiterInterfaces[NUMBER_OF_DEVICES],
	input logic clock, reset
);
	logic[NUMBER_OF_DEVICES - 1   : 0] grants;
	logic[DEVICE_NUMBER_WIDTH - 1 : 0] currentDevice;
	logic 														 requests[NUMBER_OF_DEVICES];

	generate
		genvar i;
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign requests[i] = arbiterInterfaces[i].request;

			assign arbiterInterfaces[i].grant = grants[i];
		end
	endgenerate

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			grants <= 0;
		end else if ((| grants) == 0) begin
			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				if (requests[i] == 1) begin
					grants[i]     <= 1;
					currentDevice <= i;
					break;
				end
			end
		end else if (requests[currentDevice] == 0) begin
			grants[currentDevice] <= 0;
		end
	end
endmodule : Arbiter
