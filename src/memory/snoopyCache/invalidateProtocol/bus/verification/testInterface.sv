interface TestInterface();
	import types::*;
	import commands::*;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) cpuSlaveMemoryInterface[NUMBER_OF_CACHES]();

	CPUCommandInterface cpuBusCommandInterface[NUMBER_OF_CACHES]();

	ReadMemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) snoopyMasterReadMemoryInterface[NUMBER_OF_CACHES]();

	SnoopyCommandInterface snoopyBusCommandInterface[NUMBER_OF_CACHES]();

	logic[NUMBER_OF_CACHES - 1 : 0] cpuGrants, snoopyGrants;

	MemoryInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) ramMemoryInterface();

	bit clock;
	
	MemoryCollectedItem cpuSlaveMemoryInterfaceStruct[NUMBER_OF_CACHES];
	CPUCommandCollectedItem cpuBusCommandInterfaceStruct[NUMBER_OF_CACHES];
	ReadMemoryCollectedItem snoopyMasterReadMemoryInterfaceStruct[NUMBER_OF_CACHES];
	SnoopyCommandCollectedItem snoopyBusCommandInterfaceStruct[NUMBER_OF_CACHES];
	MemoryCollectedItem ramMemoryInterfaceStruct;

	genvar i;
	
	generate
		for (i = 0; i < NUMBER_OF_CACHES; i++) begin
			//cpu memory interface
			assign cpuSlaveMemoryInterface[i].address      = cpuSlaveMemoryInterfaceStruct[i].address;
			assign cpuSlaveMemoryInterface[i].dataOut      = cpuSlaveMemoryInterfaceStruct[i].dataOut;
			assign cpuSlaveMemoryInterface[i].readEnabled  = cpuSlaveMemoryInterfaceStruct[i].readEnabled;
			assign cpuSlaveMemoryInterface[i].writeEnabled = cpuSlaveMemoryInterfaceStruct[i].writeEnabled;

			assign cpuSlaveMemoryInterfaceStruct[i].dataIn           = cpuSlaveMemoryInterface[i].dataIn;
			assign cpuSlaveMemoryInterfaceStruct[i].functionComplete = cpuSlaveMemoryInterface[i].functionComplete;
			
			//cpu command interface
			assign cpuBusCommandInterface[i].commandOut = cpuBusCommandInterfaceStruct[i].commandOut;
			
			assign cpuBusCommandInterfaceStruct[i].isInvalidated = cpuBusCommandInterface[i].isInvalidated;

			//snoopy memory interface
			assign snoopyMasterReadMemoryInterface[i].dataIn           = snoopyMasterReadMemoryInterfaceStruct[i].dataIn;
			assign snoopyMasterReadMemoryInterface[i].functionComplete = snoopyMasterReadMemoryInterfaceStruct[i].functionComplete;

			assign snoopyMasterReadMemoryInterfaceStruct[i].address     = snoopyMasterReadMemoryInterface[i].address;
			assign snoopyMasterReadMemoryInterfaceStruct[i].readEnabled = snoopyMasterReadMemoryInterface[i].readEnabled;

			//snoopy command interface
			assign snoopyBusCommandInterface[i].isInvalidated = snoopyBusCommandInterfaceStruct[i].isInvalidated;
			
			assign snoopyBusCommandInterfaceStruct[i].commandIn = snoopyBusCommandInterface[i].commandIn;
		end
	endgenerate

	assign ramMemoryInterface.dataIn           = ramMemoryInterfaceStruct.dataIn;
	assign ramMemoryInterface.functionComplete = ramMemoryInterfaceStruct.functionComplete;

	assign ramMemoryInterfaceStruct.address      = ramMemoryInterface.address;
	assign ramMemoryInterfaceStruct.dataOut      = ramMemoryInterface.dataOut;
	assign ramMemoryInterfaceStruct.readEnabled  = ramMemoryInterface.readEnabled;
	assign ramMemoryInterfaceStruct.writeEnabled = ramMemoryInterface.writeEnabled;
endinterface : TestInterface
