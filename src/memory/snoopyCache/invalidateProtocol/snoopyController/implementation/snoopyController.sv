module SnoopyController#(
	int OFFSET_WIDTH,
	int INDEX_WIDTH,
	int TAG_WIDTH,
	type STATE_TYPE,
	STATE_TYPE INVALID_STATE
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
		
	assign protocolInterface.stateOut  = cacheInterface.hit == 1 ? cacheInterface.stateOut : INVALID_STATE;
	assign protocolInterface.commandIn = commandInterface.commandIn;

	assign commandInterface.isInvalidated = cacheInterface.hit == 0 ? 1 : 0;

	assign arbiterInterface.request = protocolInterface.request == 1 ? 1 : 0;

	//snoopy controler
	always_ff @(posedge clock, reset) begin
		slaveInterface.functionComplete <= 0;
		cacheInterface.writeState       <= 0;
		invalidateEnable                <= 0;
		case (commandInterface.commandIn) 
			BUS_READ: begin
				if (cacheInterface.hit == 1) begin
					if (arbiterInterface.grant == 0) begin
						if (protocolInterface.stateIn != cacheInterface.stateOut) begin
							cacheInterface.writeState <= 1;
						end
					end else begin
						if (slaveInterface.readEnabled == 1) begin
							slaveInterface.functionComplete <= 1;
						end else if (slaveInterface.functionComplete == 1 && slaveInterface.address[OFFSET_WIDTH - 1 : 0] == 0) begin
							cacheInterface.writeState <= 1;
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
					if (arbiterInterface.grant == 0) begin
						cacheInterface.writeState <= 1;
						invalidateEnable          <= 1;
					end else begin
						if (slaveInterface.readEnabled == 1) begin
							slaveInterface.functionComplete <= 1;
						end else if (slaveInterface.functionComplete == 1 && slaveInterface.address[OFFSET_WIDTH - 1 : 0] == 0) begin
							cacheInterface.writeState <= 1;
							invalidateEnable          <= 1;
						end
					end
				end
			end
		endcase
	end
endmodule : SnoopyController
