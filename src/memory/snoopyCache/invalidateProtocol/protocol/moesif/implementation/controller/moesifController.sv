module MOESIFController(
	MemoryInterface.slave cpuSlaveInterface,
	MemoryInterface.master cpuMasterInterface,
	ReadMemoryInterface.slave snoopySlaveInterface,
	CacheInterface.controller cacheInterface,
	BusInterface.controller busInterface,
	ArbiterInterface.device cpuArbiterInterface,
	ArbiterInterface.device snoopyArbiterInterface,
	output logic accessEnable, invalidateEnable,
	input logic clock, reset
);

	import types::*;

	//CPU_CONTROLLER_BEGIN
	//cpu controller states
	typedef enum logic[2 : 0] {
		WAITING_FOR_REQUEST,
		READING_BLOCK,
		SERVE_REQUEST_FINISH
	} CpuControllerState;

	CpuControllerState cpuControllerState;
	logic[cacheInterface.OFFSET_WIDTH - 1 : 0] wordCounter;
	
	assign cpuArbiterInterface.request = busInterface.cpuCommandOut != NONE ? 1 : 0;

	assign cpuSlaveInterface.dataIn   = cacheInterface.cpuDataOut;
	assign cpuMasterInterface.address = {cacheInterface.cpuTagIn, cacheInterface.cpuIndex, wordCounter};

	assign cacheInterface.cpuTagIn  = cpuSlaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.cpuIndex  = cpuSlaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.cpuOffset = cacheInterface.cpuHit == 1 ? cpuSlaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0] : wordCounter;
	assign cacheInterface.cpuDataIn = cpuMasterInterface.dataIn;

	//read block task
	typedef enum logic[1 : 0] {
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
					cpuMasterInterface.readEnabled <= 0;
					readingBlockState              <= READ_WRITING_DATA_TO_CACHE;
				end
			end

			READ_WRITING_DATA_TO_CACHE: begin
				cacheInterface.cpuWriteData <= 0;
				wordCounter                 <= wordCounter + 1;

				if ((& wordCounter) == 1) begin
					if (busInterface.sharedIn == 1) begin
						cacheInterface.cpuStateIn <= FORWARD;
					end else begin
						cacheInterface.cpuStateIn <= EXCLUSIVE;
					end

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

	//reset task
	task cpuControllerReset();
			cpuControllerState         <= WAITING_FOR_REQUEST;
			busInterface.cpuCommandOut <= NONE;
			readingBlockState          <= READ_BUS_GRANT_WAIT;
			wordCounter                <= 0;
	endtask : cpuControllerReset

	//cpu controller 
	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			cpuControllerReset();
		end else begin
			case (cpuControllerState)
				//waiting for read or write request
				WAITING_FOR_REQUEST: begin
					busInterface.cpuCommandOut <= NONE;
					if (cpuSlaveInterface.readEnabled == 1 || cpuSlaveInterface.writeEnabled == 1) begin
						if (cacheInterface.cpuHit == 1) begin
							cpuSlaveInterface.functionComplete <= 1;
							cpuControllerState                 <= SERVE_REQUEST_FINISH;
							accessEnable                       <= 1;
						end else begin
							cpuControllerState         <= READING_BLOCK;
							busInterface.cpuCommandOut <= BUS_READ;
						end
					end	
				end
				

				//reading block if not hit
				READING_BLOCK: begin
					readBlock();
				end	

				SERVE_REQUEST_FINISH: begin
					cpuSlaveInterface.functionComplete <= 0;
					cpuControllerState                 <= WAITING_FOR_REQUEST;
					accessEnable                       <= 0;
				end
			endcase
		end
	end
	//CPU_CONTROLLER_END

	//SNOPY_CONTROLLER_BEGIN
	assign busInterface.sharedOut          =  cacheInterface.snoopyStateOut != INVALID && busInterface.snoopyCommandIn != NONE ? 1 : 0;
	assign busInterface.forwardOut         =  cacheInterface.snoopyStateOut == FORWARD && busInterface.snoopyCommandIn != NONE ? 1 : 0;
	assign snoopyArbiterInterface.request  =  busInterface.sharedOut;
		
	assign cacheInterface.snoopyTagIn  = snoopySlaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.snoopyIndex  = snoopySlaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.snoopyOffset = snoopySlaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0];
	//snoopy controler
	always_ff @(posedge clock, reset) begin
		case (busInterface.snoopyCommandIn) 
			BUS_READ: begin
				if (cacheInterface.snoopyHit == 1) begin
					if (cacheInterface.snoopyStateOut != SHARED) begin
						cacheInterface.snoopyStateIn    <= SHARED;
						cacheInterface.snoopyWriteState <= 1;
					end else begin
						cacheInterface.snoopyWriteState <= 0;
					end
					
					if (snoopyArbiterInterface.grant == 1) begin
						if (snoopySlaveInterface.readEnabled == 1) begin
							snoopySlaveInterface.functionComplete <= 1;
						end else begin
							snoopySlaveInterface.functionComplete <= 0;
						end
					end
				end
			end
		endcase
	end
	//SNOPY_CONTROLLER_END
endmodule : MOESIFController
