module CPUController(
	MemoryInterface.slave slaveInterface,
	MemoryInterface.master masterInterface,
	CPUCacheInterface.controller cacheInterface,
	CPUProtocolInterface.controller protocolInterface,
	CPUCommandInterface.controller commandInterface,
	ArbiterInterface.device arbiterInterface,
	output logic accessEnable,
	input logic clock, reset
);
	import commands::*;

	//variables
	logic[cacheInterface.OFFSET_WIDTH - 1 : 0] wordCounter;
	logic[cacheInterface.TAG_WIDTH - 1    : 0] masterTag;
	assign masterTag = protocolInterface.writeBackRequired == 1 ? cacheInterface.tagOut : cacheInterface.tagIn;

	//slave interface assigns
	assign slaveInterface.dataIn  = cacheInterface.dataOut;

	//cache interface assings
	assign cacheInterface.tagIn   = slaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.index   = slaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.offset  = cacheInterface.hit == 1 ? slaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0] : wordCounter;
	assign cacheInterface.dataIn  = cacheInterface.hit == 1 ? slaveInterface.dataOut : masterInterface.dataIn;
	assign cacheInterface.stateIn = cacheInterface.hit == 0 && protocolInterface.writeBackRequired == 1 ? cacheInterface.INVALID_STATE : protocolInterface.stateIn;

	//arbiter interface assigns
	assign arbiterInterface.request = commandInterface.commandOut != NONE ? 1 : 0;

	//master interface assigns
	assign masterInterface.address = {masterTag , cacheInterface.index, wordCounter};
	assign masterInterface.dataOut = cacheInterface.dataOut;

	//protocol asigns
	assign protocolInterface.stateOut = cacheInterface.stateOut;
	assign protocolInterface.read     = slaveInterface.readEnabled;
	assign protocolInterface.write    = slaveInterface.writeEnabled;

	//read block task
	typedef enum logic[2 : 0] {
		READ_BUS_GRANT_WAIT,
		READ_WAITING_FOR_FUNCTION_COMPLETE,
		READ_WRITING_DATA_TO_CACHE,
		READ_WRITING_TAG_AND_STATE_TO_CACHE
	} ReadingBlockState;
	ReadingBlockState readingBlockState;
	 
	task readBlock();
		case (readingBlockState)
			READ_BUS_GRANT_WAIT: begin
				if (arbiterInterface.grant == 1) begin
					masterInterface.readEnabled <= 1;
					readingBlockState           <= READ_WAITING_FOR_FUNCTION_COMPLETE;
				end
			end	
			
			READ_WAITING_FOR_FUNCTION_COMPLETE: begin
				if (masterInterface.functionComplete == 1) begin
					cacheInterface.writeData <= 1;
					readingBlockState        <= READ_WRITING_DATA_TO_CACHE;
				end
			end

			READ_WRITING_DATA_TO_CACHE: begin
				cacheInterface.writeData    <= 0;
				masterInterface.readEnabled <= 0;
				wordCounter                 <= wordCounter + 1;

				if ((& wordCounter) == 1) begin
					cacheInterface.writeTag   <= 1;
					cacheInterface.writeState <= 1;

					readingBlockState <= READ_WRITING_TAG_AND_STATE_TO_CACHE;
				end else begin
					readingBlockState <= READ_BUS_GRANT_WAIT;
				end
			end

			READ_WRITING_TAG_AND_STATE_TO_CACHE: begin
				cacheInterface.writeTag   <= 0;
				cacheInterface.writeState <= 0;

				readingBlockState  <= READ_BUS_GRANT_WAIT;
			end
		endcase	
	endtask : readBlock;

	//command invalidate task
	typedef enum logic {
		INVALIDATE_WAITING_FOR_INVALIDATE_ACKNOWLEDGEMENTS,
		INVALIDATE_WRITING_STATE
	} BusInvalidateState;
	BusInvalidateState invalidatingState;

	task invalidating();
		case (invalidatingState)
			INVALIDATE_WAITING_FOR_INVALIDATE_ACKNOWLEDGEMENTS: begin
				if (arbiterInterface.grant == 1) begin
					if (commandInterface.isInvalidated == 1) begin
						cacheInterface.writeState <= 1;
						invalidatingState         <= INVALIDATE_WRITING_STATE;
					end
				end
			end

			INVALIDATE_WRITING_STATE: begin
				cacheInterface.writeState <= 0;
				invalidatingState         <= INVALIDATE_WAITING_FOR_INVALIDATE_ACKNOWLEDGEMENTS;
			end
		endcase
	endtask : invalidating

	//write back task
	typedef enum logic[1 : 0] {
		WRITE_BACK_BUS_GRANT_WAIT,
		WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE,
		WRITE_BACK_WRITING_STATE_TO_CACHE
	} WriteBackState;
	WriteBackState writeBackState;

	task writeBack();
		case (writeBackState)
			WRITE_BACK_BUS_GRANT_WAIT: begin
				if (arbiterInterface.grant == 1) begin
					masterInterface.writeEnabled <= 1;
					writeBackState               <= WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE;
				end
			end	
			
			WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE: begin
				if (masterInterface.functionComplete == 1) begin
					masterInterface.writeEnabled <= 0;
					wordCounter                  <= wordCounter + 1;

					if ((& wordCounter) == 1) begin
						cacheInterface.writeState <= 1;

						writeBackState <= WRITE_BACK_WRITING_STATE_TO_CACHE;
					end else begin
						writeBackState <= WRITE_BACK_BUS_GRANT_WAIT;
					end
				end
			end

			WRITE_BACK_WRITING_STATE_TO_CACHE: begin
				cacheInterface.writeState <= 0;
				writeBackState            <= WRITE_BACK_BUS_GRANT_WAIT;
			end
		endcase	
	endtask : writeBack;

	task serveRequest();
		slaveInterface.functionComplete <= 1;
		cacheInterface.writeState       <= slaveInterface.writeEnabled;
		cacheInterface.writeData        <= slaveInterface.writeEnabled;
		accessEnable                    <= 1;
	endtask : serveRequest

	//reset task
	task cpuControllerReset();
			readingBlockState <= READ_BUS_GRANT_WAIT;
			wordCounter       <= 0;
			invalidatingState <= INVALIDATE_WAITING_FOR_INVALIDATE_ACKNOWLEDGEMENTS;
			writeBackState    <= WRITE_BACK_BUS_GRANT_WAIT;
			accessEnable      <= 0;
	endtask : cpuControllerReset

	logic requestPresent;
	assign requestPresent = slaveInterface.readEnabled == 1 || slaveInterface.writeEnabled == 1 ? 1 : 0;

	//command out combo logic
	always_comb begin
		commandInterface.commandOut = NONE;
		if (requestPresent == 1) begin
			if (cacheInterface.hit == 1) begin
				if (protocolInterface.invalidateRequired == 1) begin
					commandInterface.commandOut = BUS_INVALIDATE;
				end
			end else if (protocolInterface.writeBackRequired == 1) begin
				commandInterface.commandOut = BUS_WRITEBACK;
			end else begin
				commandInterface.commandOut = BUS_READ;
			end
		end
	end

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			cpuControllerReset();
		end else begin
			if (requestPresent == 1) begin
				if (cacheInterface.hit == 1) begin
					if (protocolInterface.invalidateRequired == 1) begin
						invalidating();	
					end else begin
						serveRequest();
					end		
				end else if (protocolInterface.writeBackRequired == 1) begin
					writeBack();
				end else begin
					readBlock();
				end		
			end else begin
				slaveInterface.functionComplete <= 0;
				cacheInterface.writeState       <= 0;
				cacheInterface.writeData        <= 0;
				accessEnable                    <= 0;
			end
		end
	end
endmodule : CPUController
