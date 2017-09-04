module Arbiter#(
	int NUMBER_OF_DEVICES = 4
)(
	ArbiterInterface.arbiter arbiterInterfaces[NUMBER_OF_DEVICES]
);
	logic requests[NUMBER_OF_DEVICES];
	logic[NUMBER_OF_DEVICES - 1 : 0] grants;

	generate
		genvar i;
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign requests[i] = arbiterInterfaces[i].request;

			assign arbiterInterfaces[i].grant = grants[i];
		end
	endgenerate

	always_comb begin
		for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
			grants[i] = 0;
			 if ((| grants) == 0 && requests[i] == 1) begin
				grants[i] = 1;
			end
		end	
	end
endmodule : Arbiter
