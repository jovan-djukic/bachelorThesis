module BUS#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH,
	int NUMBER_OF_DEVICES
)(
	MemoryInterface.slave deviceMemoryInterface[NUMBER_OF_DEVICES],
	ArbiterInterface.device deviceArbiterInterface[NUMBER_OF_DEVICES],
	MemoryInterface.master ramMemoryInterface
);
	genvar i;

	logic[ADDRESS_WIDTH - 1 : 0] address[NUMBER_OF_DEVICES], ramAddress;
	logic[DATA_WIDTH - 1    : 0] dataIn[NUMBER_OF_DEVICES], dataOut[NUMBER_OF_DEVICES], ramDataIn, ramDataOut;
	logic 											 readEnabled[NUMBER_OF_DEVICES], writeEnabled[NUMBER_OF_DEVICES], functionComplete[NUMBER_OF_DEVICES], grant[NUMBER_OF_DEVICES];
	logic												 ramReadEnabled, ramWriteEnabled, ramFunctionComplete;
	
	generate
		for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
			assign deviceArbiterInterface[i].request = deviceMemoryInterface[i].readEnabled == 1 || 
																						 		 deviceMemoryInterface[i].writeEnabled == 1 || 
																						 		 deviceMemoryInterface[i].functionComplete == 1 ? 1 : 0;

			assign grant[i]        = deviceArbiterInterface[i].grant;

			assign address[i]			 = deviceMemoryInterface[i].address;
			assign dataOut[i]      = deviceMemoryInterface[i].dataOut;
			assign readEnabled[i]  = deviceMemoryInterface[i].readEnabled;
			assign writeEnabled[i] = deviceMemoryInterface[i].writeEnabled;

			assign deviceMemoryInterface[i].dataIn           = dataIn[i];
			assign deviceMemoryInterface[i].functionComplete = functionComplete[i];
		end
	endgenerate

	assign ramMemoryInterface.address      = ramAddress;
	assign ramMemoryInterface.dataOut      = ramDataOut;
	assign ramMemoryInterface.readEnabled  = ramReadEnabled;
	assign ramMemoryInterface.writeEnabled = ramWriteEnabled;

	assign ramDataIn           = ramMemoryInterface.dataIn;
	assign ramFunctionComplete = ramMemoryInterface.functionComplete;

	always_comb begin
		ramAddress      = 0;
		ramDataOut      = 0;
		ramReadEnabled  = 0;
		ramWriteEnabled = 0;

		for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
			if (grant[i] == 1) begin
					ramAddress      = address[i];
					ramDataOut      = dataOut[i];
					ramReadEnabled  = readEnabled[i];
					ramWriteEnabled = writeEnabled[i];
				break;
			end
		end
	end

	always_comb begin
		for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
			if (grant[i] == 1) begin
				dataIn[i]           = ramDataIn;
				functionComplete[i] = ramFunctionComplete;
			end else begin
				dataIn[i]           = 0;
				functionComplete[i] = 0;
			end
		end
	end
endmodule : BUS
