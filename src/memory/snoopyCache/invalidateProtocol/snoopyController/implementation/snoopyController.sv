module SnoopyController#(
	int OFFSET_WIDTH = 4,
	int INDEX_WIDTH  = 4,
	int TAG_WIDTH    = 8
)(
	ReadMemoryInterface.slave slaveInterface,
	SnoopyCacheInterface.controller cacheInterface,
	SnoopyProtocolInterface.controller protocolInterface,
	SnoopyCommandInterface.controller commandInterface,
	ArbiterInterface.device arbiterInterface,
	output logic invalidateEnable,
	input logic clock, reset
);
	import commands::*;

	assign cacheInterface.tagIn   = slaveInterface.address[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
	assign cacheInterface.index   = slaveInterface.address[OFFSET_WIDTH +: INDEX_WIDTH];
	assign cacheInterface.offset  = slaveInterface.address[OFFSET_WIDTH - 1 : 0];
	assign cacheInterface.stateIn = protocolInterface.stateIn;

	assign slaveInterface.dataIn = cacheInterface.dataOut;
		
	assign protocolInterface.stateOut  = cacheInterface.stateOut;
	assign protocolInterface.commandIn = commandInterface.commandIn;

	assign commandInterface.isInvalidated = cacheInterface.hit == 0 ? 1 : 0;

	assign arbiterInterface.request = protocolInterface.request == 1 && (commandInterface.commandIn == BUS_READ || commandInterface.commandIn == BUS_READ_EXCLUSIVE) ? 1 : 0;

	//snoopy controler
	always_ff @(posedge clock, reset) begin
		slaveInterface.functionComplete <= 0;
		cacheInterface.writeState       <= 0;
		invalidateEnable                <= 0;
		case (commandInterface.commandIn) 
			BUS_READ: begin
				if (cacheInterface.hit == 1) begin
					if (cacheInterface.stateOut != protocolInterface.stateIn) begin
						cacheInterface.writeState <= 1;
					end					

					if (arbiterInterface.grant == 1) begin
						if (slaveInterface.readEnabled == 1) begin
							slaveInterface.functionComplete <= 1;
						end 
					end
				end
			end

			BUS_INVALIDATE: begin
				if (commandInterface.isInvalidated == 0) begin
					cacheInterface.writeState <= 1;
					invalidateEnable          <= 1;
				end	
			end

			BUS_READ_EXCLUSIVE: begin
				if (cacheInterface.hit == 1) begin
					if (arbiterInterface.grant == 1) begin
						if (slaveInterface.readEnabled == 1) begin
							slaveInterface.functionComplete <= 1;
						end 
					end
				end
				if ((arbiterInterface.grant == 0 || (& slaveInterface.address[OFFSET_WIDTH - 1 : 0]) == 1) && commandInterface.isInvalidated == 0) begin
					cacheInterface.writeState <= 1;
					invalidateEnable          <= 1;
				end
			end
		endcase
	end
endmodule : SnoopyController
