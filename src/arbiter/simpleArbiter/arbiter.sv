module Arbiter#(
	int NUBMER_OF_DEVICES = 4
)(
	ArbiterInterface.arbiter arbiterInterfaces[NUBMER_OF_DEVICES]
);
	logic requests[NUBMER_OF_DEVICES];
	logic[NUBMER_OF_DEVICES - 1 : 0] grants;

	generate
		genvar i;
		for (i = 0; i < NUBMER_OF_DEVICES; i++) begin
			assign requests[i] = arbiterInterfaces[i].request;

			assign arbiterInterfaces[i].grant = grants[i];
		end
	endgenerate

	always_comb begin
		for (int i = 0; i < NUBMER_OF_DEVICES; i++) begin
			if ((| grants) != 0) begin
				grants[i] = 0;	
			end else if (requests[i] == 1) begin
				grants[i] = 1;
			end
		end	
	end
endmodule : Arbiter
