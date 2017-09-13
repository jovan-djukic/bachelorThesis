module ConcurrencyLock#(
	int ADDRESS_WIDTH,
	int OFFSET_WIDTH 
)(
	MemoryInterface.slave cpuSlaveMemoryInterface,
	MemoryInterface.master cpuMasterMemoryInterface,
	CPUCommandInterface.bus cpuBusCommandInterface,
	CPUCommandInterface.controller cpuControllerCommandInterface,
	ArbiterInterface.arbiter cpuArbiterArbiterInterface,
	ArbiterInterface.device cpuDeviceArbiterInterface,
	SnoopyCommandInterface.bus snoopyBusCommandInterface,
	SnoopyCommandInterface.controller snoopyControllerCommandInterface,
	ArbiterInterface.arbiter snoopyArbiterArbiterInterface,
	ArbiterInterface.device snoopyDeviceArbiterInterface,
	ReadMemoryInterface.master snoopyMasterReadMemoryInterface,
	ReadMemoryInterface.slave snoopySlaveReadMemoryInterface,
	input logic cpuHit, snoopyHit, invalidateRequired,
	input logic clock, reset
);
	//localparam ADDRESS_WIDTH = cpuSlaveMemoryInterface.ADDRESS_WIDTH;
	
	import commands::*;
	
	//lock logic
	logic busInvalidateLoop, conflict;
	
	always_comb begin
		busInvalidateLoop = 0;
		conflict          = 0;

		if (cpuSlaveMemoryInterface.address[ADDRESS_WIDTH - 1 : OFFSET_WIDTH] == snoopySlaveReadMemoryInterface.address[ADDRESS_WIDTH - 1 : OFFSET_WIDTH] &&
				((cpuControllerCommandInterface.commandOut == BUS_INVALIDATE && snoopyControllerCommandInterface.commandIn == BUS_INVALIDATE) || 
				 (cpuControllerCommandInterface.commandOut == BUS_READ_EXCLUSIVE && snoopyControllerCommandInterface.commandIn == BUS_READ_EXCLUSIVE)) && 
				cpuDeviceArbiterInterface.grant == 1) begin
			busInvalidateLoop = 1;
		end else if (cpuSlaveMemoryInterface.address[ADDRESS_WIDTH - 1 : OFFSET_WIDTH] == snoopySlaveReadMemoryInterface.address[ADDRESS_WIDTH - 1 : OFFSET_WIDTH] &&
				cpuHit == 1 && snoopyHit == 1 && (
					(cpuSlaveMemoryInterface.readEnabled == 1 && snoopyControllerCommandInterface.commandIn == BUS_INVALIDATE) ||
					(cpuSlaveMemoryInterface.readEnabled == 1 && snoopyControllerCommandInterface.commandIn == BUS_READ_EXCLUSIVE) ||
					(cpuSlaveMemoryInterface.writeEnabled == 1 && invalidateRequired == 0 && snoopyControllerCommandInterface.commandIn == BUS_READ)	||
					(cpuSlaveMemoryInterface.writeEnabled == 1 && invalidateRequired == 0 && snoopyControllerCommandInterface.commandIn == BUS_INVALIDATE) ||
					(cpuSlaveMemoryInterface.writeEnabled == 1 && invalidateRequired == 0 && snoopyControllerCommandInterface.commandIn == BUS_READ_EXCLUSIVE)
				)) begin
			conflict = 1;
		end	
	end

	//this is new
	ArbiterInterface arbiterInterfaces[2]();
	Arbiter#(
		.NUMBER_OF_DEVICES(2)
	) arbiter(
		.arbiterInterfaces(arbiterInterfaces),
		.clock(clock),
		.reset(reset)	
	);
	//cpu port
	assign arbiterInterfaces[0].request = cpuSlaveMemoryInterface.readEnabled == 1 || cpuSlaveMemoryInterface.writeEnabled == 1 ? 1 : 0;
	
	//snoopy port
	assign arbiterInterfaces[1].request = snoopyControllerCommandInterface.commandIn == BUS_READ || 
																				snoopyControllerCommandInterface.commandIn == BUS_INVALIDATE ||
																				snoopyControllerCommandInterface.commandIn == BUS_READ_EXCLUSIVE ? 1 : 0;
	
	logic cpuHold, snoopyHold;

	//assign cpuHold    = conflict == 1 && cpuMasterMemoryInterface.functionComplete == 0 ? 1 : 0;
	//assign snoopyHold = conflict == 1 && cpuMasterMemoryInterface.functionComplete == 1 ? 1 : 0;
	assign cpuHold    = conflict == 1 ? ~arbiterInterfaces[0].grant : 0;
	assign snoopyHold = conflict == 1 ? ~arbiterInterfaces[1].grant : 0;

	//memory interface assigns
	assign cpuMasterMemoryInterface.address      = cpuSlaveMemoryInterface.address;
	assign cpuMasterMemoryInterface.dataOut      = cpuSlaveMemoryInterface.dataOut;
	assign cpuMasterMemoryInterface.readEnabled  = cpuHold == 0 ? cpuSlaveMemoryInterface.readEnabled : 0;
	assign cpuMasterMemoryInterface.writeEnabled = cpuHold == 0 ? cpuSlaveMemoryInterface.writeEnabled : 0;
	
	assign cpuSlaveMemoryInterface.dataIn           = cpuMasterMemoryInterface.dataIn;
	assign cpuSlaveMemoryInterface.functionComplete = cpuMasterMemoryInterface.functionComplete;

	//cpu command interface assigns
	assign cpuControllerCommandInterface.commandOut = cpuBusCommandInterface.commandOut;

	assign cpuBusCommandInterface.isInvalidated = cpuControllerCommandInterface.isInvalidated;

	//cpu arbiter interface
	assign cpuDeviceArbiterInterface.request = cpuArbiterArbiterInterface.request;

	assign cpuArbiterArbiterInterface.grant = cpuDeviceArbiterInterface.grant;

	//snoopy command interface
	assign snoopyControllerCommandInterface.isInvalidated = busInvalidateLoop == 0 ? snoopyBusCommandInterface.isInvalidated : 1;
	
	assign snoopyBusCommandInterface.commandIn = snoopyHold == 0 && busInvalidateLoop == 0 ? snoopyControllerCommandInterface.commandIn : NONE;

	//snoopy arbiter interface
	assign snoopyDeviceArbiterInterface.request = snoopyControllerCommandInterface.commandIn != BUS_WRITEBACK  ? snoopyArbiterArbiterInterface.request : 0;

	assign snoopyArbiterArbiterInterface.grant = snoopyDeviceArbiterInterface.grant;

	//snoopy read memory interface
	assign snoopyMasterReadMemoryInterface.address     = snoopySlaveReadMemoryInterface.address;
	assign snoopyMasterReadMemoryInterface.readEnabled = snoopyHold == 0 ? snoopySlaveReadMemoryInterface.readEnabled : 1;

	assign snoopySlaveReadMemoryInterface.dataIn           = snoopyMasterReadMemoryInterface.dataIn;
	assign snoopySlaveReadMemoryInterface.functionComplete = snoopyMasterReadMemoryInterface.functionComplete;

endmodule : ConcurrencyLock
