module SnoopyBus#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH,
	int NUMBER_OF_CACHES
)(
	MemoryInterface.slave cpuSlaveMemoryInterface[NUMBER_OF_CACHES],
	CPUCommandInterface.bus cpuBusCommandInterface[NUMBER_OF_CACHES],
	ReadMemoryInterface.master snoopyMasterReadMemoryInterface[NUMBER_OF_CACHES],
	SnoopyCommandInterface.bus snoopyBusCommandInterface[NUMBER_OF_CACHES],
	input logic[NUMBER_OF_CACHES - 1 : 0] cpuGrants, snoopyGrants,
	MemoryInterface.master ramMemoryInterface
);
	import commands::*;

	//generate variable
	genvar i;

	//cpu controller memory interface
	logic[ADDRESS_WIDTH - 1 : 0] address, addresses[NUMBER_OF_CACHES];
	logic[DATA_WIDTH - 1    : 0] dataOut, dataOuts[NUMBER_OF_CACHES], dataIn;
	logic												 readEnabled, readsEnabled[NUMBER_OF_CACHES], writeEnabled, writesEnabled[NUMBER_OF_CACHES], functionComplete;

	generate 
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			//cpu controller outputs
			assign addresses[i]     = cpuSlaveMemoryInterface[i].address;
			assign dataOuts[i]      = cpuSlaveMemoryInterface[i].dataOut;
			assign readsEnabled[i]  = cpuSlaveMemoryInterface[i].readEnabled;
			assign writesEnabled[i] = cpuSlaveMemoryInterface[i].writeEnabled;

			//cpu controller inputs
			assign cpuSlaveMemoryInterface[i].dataIn           = dataIn;
			assign cpuSlaveMemoryInterface[i].functionComplete = functionComplete;
		end
	endgenerate

	always_comb begin
		address      = 0;
		dataOut      = 0;
		readEnabled  = 0;
		writeEnabled = 0;

		for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
			if (cpuGrants[i] == 1) begin
				address      = addresses[i];
				dataOut      = dataOuts[i];
				readEnabled  = readsEnabled[i];
				writeEnabled = writesEnabled[i];
				break;
			end
		end
	end

	//cpu command interface
	Command commandOut, commandOuts[NUMBER_OF_CACHES];
	logic 	isInvalidated;

	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			//cpu command interface inputs
			assign commandOuts[i] = cpuBusCommandInterface[i].commandOut;

			//cpu command interface outputs
			assign cpuBusCommandInterface[i].isInvalidated = isInvalidated;
		end
	endgenerate

	always_comb begin
		commandOut = NONE;
		for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
			if (cpuGrants[i] == 1) begin
				commandOut = commandOuts[i];
				break;
			end
		end
	end

	//if none of the snoopies respond assign to memory 
	assign ramMemoryInterface.address      = address;
	assign ramMemoryInterface.dataOut      = dataOut;
	assign ramMemoryInterface.writeEnabled = writeEnabled;
	assign ramMemoryInterface.readEnabled  = (| snoopyGrants) == 0 ? readEnabled : 0;

	//snoopy memory interface
	logic[DATA_WIDTH - 1 : 0] dataIns[NUMBER_OF_CACHES];
	logic 						  		  functionCompletes[NUMBER_OF_CACHES];

	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			//snoopy memory interface outputs
			assign dataIns[i]           = snoopyMasterReadMemoryInterface[i].dataIn;
			assign functionCompletes[i] = snoopyMasterReadMemoryInterface[i].functionComplete;

			//snoopy memory interface inputs
			assign snoopyMasterReadMemoryInterface[i].address     = address;
			assign snoopyMasterReadMemoryInterface[i].readEnabled = readEnabled;
		end
	endgenerate

	always_comb begin
		dataIn           = ramMemoryInterface.dataIn;
		functionComplete = ramMemoryInterface.functionComplete;

		for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
			if (snoopyGrants[i] == 1) begin
				dataIn           = dataIns[i];
				functionComplete = functionCompletes[i];
				break;
			end
		end
	end

	//snoopy command interface
	logic[NUMBER_OF_CACHES - 1 : 0] areInvalidated;

	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			//outputs
			assign areInvalidated[i] = snoopyBusCommandInterface[i].isInvalidated;

			//input
			assign snoopyBusCommandInterface[i].commandIn = commandOut;
		end
	endgenerate

	assign isInvalidated = (& areInvalidated) == 1 ? 1 : 0;
endmodule : SnoopyBus
