module CacheController#(
	int CACHE_ID = 0
)(
	MemoryInterface.slave cpuSlaveInterface,
	MemoryInterface.master cpuMasterInterface,
	ReadMemoryInterface.slave snoopySlaveInterface,
	CacheInterface.controller cacheInterface,
	ProtocolInterface.controller protocolInterface,
	CommandInterface.controller commandInterface,
	ArbiterInterface.device cpuArbiterInterface,
	ArbiterInterface.device snoopyArbiterInterface,
	output logic accessEnable, invalidateEnable,
	input logic clock, reset
);
	import commands::*;

	//lock variable for conflict detection
	logic lock;
	always_comb begin
		lock = 0;
		if (cacheInterface.cpuTagIn == cacheInterface.snoopyTagIn && cacheInterface.cpuIndex == cacheInterface.snoopyIndex &&
				cacheInterface.cpuHit == 1 && cacheInterface.snoopyHit == 1 &&
				(cpuSlaveInterface.writeEnabled == 1 || commandInterface.snoopyCommandIn == BUS_INVALIDATE)) begin
			lock = 1;
		end
	end

	//cpu controller variables
	logic[cacheInterface.OFFSET_WIDTH - 1 : 0] wordCounter;
	logic[cacheInterface.TAG_WIDTH - 1    : 0] masterTag;
	assign masterTag = protocolInterface.writeBackRequired == 1 ? cacheInterface.cpuTagOut : cacheInterface.cpuTagIn;

	//cpu controller assigns and varibles
	assign cpuSlaveInterface.dataIn   = cacheInterface.cpuDataOut;

	//cpu controller cache interface assings
	assign cacheInterface.cpuTagIn  = cpuSlaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.cpuIndex  = cpuSlaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.cpuOffset = cacheInterface.cpuHit == 1 ? cpuSlaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0] : wordCounter;
	assign cacheInterface.cpuDataIn = cacheInterface.cpuHit == 1 ? cpuSlaveInterface.dataOut : cpuMasterInterface.dataIn;

	//cpu controller arbiter assigns
	assign cpuArbiterInterface.request = commandInterface.cpuCommandOut != NONE ? 1 : 0;

	//cpu controller master interface assigns
	assign cpuMasterInterface.address = {masterTag , cacheInterface.cpuIndex, wordCounter};
	assign cpuMasterInterface.dataOut = cacheInterface.cpuDataOut;

	//protocol asigns
	assign protocolInterface.cpuStateOut = cacheInterface.cpuStateOut;
	assign protocolInterface.cpuRead     = cpuSlaveInterface.readEnabled;
	assign protocolInterface.cpuWrite    = cpuSlaveInterface.writeEnabled;

	typedef enum logic[2 : 0] {
		WAITING_FOR_REQUEST,
		WRITING_BACK,
		READING_BLOCK,
		WRITING_BUS_INVALIDATE,
		WRITE_DELAY,
		SERVE_REQUEST_FINISH
	} CpuControllerState;
	CpuControllerState cpuControllerState;

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
				if (cpuArbiterInterface.grant == 1) begin
					cpuMasterInterface.readEnabled <= 1;
					readingBlockState              <= READ_WAITING_FOR_FUNCTION_COMPLETE;
				end
			end	
			
			READ_WAITING_FOR_FUNCTION_COMPLETE: begin
				if (cpuMasterInterface.functionComplete == 1) begin
					cacheInterface.cpuWriteData    <= 1;
					readingBlockState              <= READ_WRITING_DATA_TO_CACHE;
				end
			end

			READ_WRITING_DATA_TO_CACHE: begin
				cacheInterface.cpuWriteData    <= 0;
				cpuMasterInterface.readEnabled <= 0;
				wordCounter                    <= wordCounter + 1;

				if ((& wordCounter) == 1) begin
					cacheInterface.cpuStateIn <= protocolInterface.cpuStateIn;

					cacheInterface.cpuWriteTag   <= 1;
					cacheInterface.cpuWriteState <= 1;

					readingBlockState <= READ_WRITING_TAG_AND_STATE_TO_CACHE;
				end else begin
					readingBlockState <= READ_BUS_GRANT_WAIT;
				end
			end

			READ_WRITING_TAG_AND_STATE_TO_CACHE: begin
				cacheInterface.cpuWriteTag   <= 0;
				cacheInterface.cpuWriteState <= 0;

				readingBlockState  <= READ_BUS_GRANT_WAIT;
				cpuControllerState <= WAITING_FOR_REQUEST;
			end
		endcase	
	endtask : readBlock;

	//command invalidate task
	logic[commandInterface.NUMBER_OF_CACHES - 1 : 0] invalidated;
	typedef enum logic {
		INVALIDATE_WAITING_FOR_INVALIDATES_ACKNOWLEDGEMENTS,
		INVALIDATE_WRITING_STATE
	} BusInvalidateState;
	BusInvalidateState invalidatingState;

	task invalidating();
		case (invalidatingState)
			INVALIDATE_WAITING_FOR_INVALIDATES_ACKNOWLEDGEMENTS: begin
				if (cpuArbiterInterface.grant == 1) begin
					if (commandInterface.cpuCommandIn == BUS_INVALIDATE) begin
						invalidated[commandInterface.cacheNumberIn] <= 1;
					end
				end

				if ((& invalidated) == 1) begin
					cacheInterface.cpuStateIn    <= protocolInterface.cpuStateIn;
					cacheInterface.cpuWriteState <= 1;
					invalidatingState            <= INVALIDATE_WRITING_STATE;
				end
			end

			INVALIDATE_WRITING_STATE: begin
				invalidated                  <= 1 << CACHE_ID;
				cacheInterface.cpuWriteState <= 0;
				invalidatingState            <= INVALIDATE_WAITING_FOR_INVALIDATES_ACKNOWLEDGEMENTS;
				cpuControllerState           <= WAITING_FOR_REQUEST;
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
				if (cpuArbiterInterface.grant == 1) begin
					cpuMasterInterface.writeEnabled <= 1;
					writeBackState                  <= WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE;
				end
			end	
			
			WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE: begin
				if (cpuMasterInterface.functionComplete == 1) begin
					cpuMasterInterface.writeEnabled <= 0;
					wordCounter                     <= wordCounter + 1;

					if ((& wordCounter) == 1) begin
						cacheInterface.cpuStateIn    <= cacheInterface.INVALID_STATE;
						cacheInterface.cpuWriteState <= 1;

						writeBackState <= WRITE_BACK_WRITING_STATE_TO_CACHE;
					end else begin
						writeBackState <= WRITE_BACK_BUS_GRANT_WAIT;
					end
				end
			end

			WRITE_BACK_WRITING_STATE_TO_CACHE: begin
				cacheInterface.cpuWriteState <= 0;

				writeBackState     <= WRITE_BACK_BUS_GRANT_WAIT;
				cpuControllerState <= WAITING_FOR_REQUEST;
			end
		endcase	
	endtask : writeBack;

	//reset task
	task cpuControllerReset();
			cpuControllerState             <= WAITING_FOR_REQUEST;
			commandInterface.cpuCommandOut <= NONE;
			readingBlockState              <= READ_BUS_GRANT_WAIT;
			wordCounter                    <= 0;
			invalidated                    <= 1 << CACHE_ID;
			invalidatingState              <= INVALIDATE_WAITING_FOR_INVALIDATES_ACKNOWLEDGEMENTS;
			writeBackState                 <= WRITE_BACK_BUS_GRANT_WAIT;
	endtask : cpuControllerReset

	//cpu controller 
	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			cpuControllerReset();
		end else if (lock != 1) begin
			case (cpuControllerState)
				//waiting for read or write request
				WAITING_FOR_REQUEST: begin
					commandInterface.cpuCommandOut <= NONE;
					//if request present
					if (cpuSlaveInterface.readEnabled == 1 || cpuSlaveInterface.writeEnabled == 1) begin
						//if hit serve request, else read block
						if (cacheInterface.cpuHit == 1) begin
							if (cpuSlaveInterface.writeEnabled == 1) begin
								if (protocolInterface.invalidateRequired == 1) begin
									//invalidate on the command
									cpuControllerState             <= WRITING_BUS_INVALIDATE;
									commandInterface.cpuCommandOut <= BUS_INVALIDATE;
								end else begin
									//write MODIFIED even if it is MODIFIED already, no harm
									cacheInterface.cpuStateIn          <= protocolInterface.cpuStateIn;
									cacheInterface.cpuWriteState       <= 1;
									cacheInterface.cpuWriteData        <= 1;
									cpuControllerState                 <= WRITE_DELAY;
								end	
							end	else begin
								cpuSlaveInterface.functionComplete <= 1;
								cpuControllerState                 <= SERVE_REQUEST_FINISH;
								accessEnable                       <= 1;
							end
						end else begin
							if (protocolInterface.writeBackRequired == 1) begin
								cpuControllerState             <= WRITING_BACK;
								commandInterface.cpuCommandOut <= BUS_WRITEBACK;
							end else begin
								cpuControllerState             <= READING_BLOCK;
								commandInterface.cpuCommandOut <= BUS_READ;
							end
						end
					end	
				end
				
				WRITING_BACK: begin
					writeBack();
				end

				//reading block if not hit
				READING_BLOCK: begin
					readBlock();
				end	

				//invalidating block if state is not EXCLUSIVE or MODIFIED
				WRITING_BUS_INVALIDATE: begin
					invalidating();
				end

				WRITE_DELAY: begin
					cpuSlaveInterface.functionComplete <= 1;
					accessEnable                       <= 1;
					cacheInterface.cpuWriteState       <= 0;
					cacheInterface.cpuWriteData        <= 0;
					cpuControllerState 								 <= SERVE_REQUEST_FINISH;
				end

				SERVE_REQUEST_FINISH: begin
					if (cpuSlaveInterface.readEnabled == 0 && cpuSlaveInterface.writeEnabled == 0) begin
						//disable these always
						cpuSlaveInterface.functionComplete <= 0;
						accessEnable                       <= 0;
						cpuControllerState                 <= WAITING_FOR_REQUEST;
					end
				end
			endcase
		end
	end
	//CPU_CONTROLLER_END

	//SNOPY_CONTROLLER_BEGIN
	assign cacheInterface.snoopyTagIn   = snoopySlaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.snoopyIndex   = snoopySlaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.snoopyOffset  = snoopySlaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0];
	assign cacheInterface.snoopyStateIn = protocolInterface.snoopyStateIn;

	assign snoopyArbiterInterface.request = cacheInterface.snoopyHit;

	assign snoopySlaveInterface.dataIn = cacheInterface.snoopyDataOut;
		
	assign protocolInterface.snoopyStateOut  = cacheInterface.snoopyStateOut;
	assign protocolInterface.snoopyCommandIn = commandInterface.snoopyCommandIn;

	//snoopy controler
	always_ff @(posedge clock, reset) begin
		commandInterface.snoopyCommandOut         <= NONE;
		snoopySlaveInterface.functionComplete <= 0;
		cacheInterface.snoopyWriteState       <= 0;
		invalidateEnable                      <= 0;
		case (commandInterface.snoopyCommandIn) 
			BUS_READ: begin
				if (lock != 1 || cpuControllerState == WAITING_FOR_REQUEST || cpuControllerState == WRITING_BUS_INVALIDATE) begin
					if (cacheInterface.snoopyHit == 1) begin
						if (cacheInterface.snoopyStateOut != protocolInterface.snoopyStateIn) begin
							cacheInterface.snoopyWriteState <= 1;
						end					

						if (snoopyArbiterInterface.grant == 1) begin
							if (snoopySlaveInterface.readEnabled == 1) begin
								snoopySlaveInterface.functionComplete <= 1;
							end 
						end
					end
				end
			end

			BUS_INVALIDATE: begin
				if (lock != 1 || cpuControllerState == WAITING_FOR_REQUEST) begin
					commandInterface.snoopyCommandOut <= BUS_INVALIDATE;
					commandInterface.cacheNumberOut   <= CACHE_ID;

					if (snoopyArbiterInterface.grant == 1) begin
						cacheInterface.snoopyWriteState <= 1;
						invalidateEnable                <= 1;
					end 
				end else if (lock == 1) begin
					if (cpuControllerState == WRITING_BUS_INVALIDATE || cpuControllerState == WRITING_BACK) begin
						cpuControllerState <= WAITING_FOR_REQUEST;
					end
				end
			end
		endcase
	end
	//SNOPY_CONTROLLER_END
endmodule : CacheController
