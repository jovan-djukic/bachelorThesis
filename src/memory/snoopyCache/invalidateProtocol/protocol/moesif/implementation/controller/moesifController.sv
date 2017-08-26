module MOESIFController(
	MemoryInterface.slave slaveInterface,
	MemoryInterface.master masterInterface,
	CacheInterface.controller cacheInterface,
	BusInterface.controller busInterface,
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

	assign slaveInterface.dataIn = cacheInterface.cpuDataOut;

	assign masterInterface.address = {cacheInterface.cpuTagIn, cacheInterface.cpuIndex, wordCounter};

	assign cacheInterface.cpuTagIn  = slaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.cpuIndex  = slaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.cpuOffset = cacheInterface.cpuHit == 1 ? slaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0] : wordCounter;
	assign cacheInterface.cpuDataIn = masterInterface.dataIn;

	//read block task
	typedef enum logic[1 : 0] {
		REQUEST_ISSUING,
		WAITING_FOR_FUNCTION_COMPLETE,
		WRITING_DATA_TO_CACHE,
		WRITING_TAG_AND_STATE_TO_CACHE
	} ReadingBlockState;
	ReadingBlockState readingBlockState;
	 
	task readBlock();
		if (readingBlockState == REQUEST_ISSUING) begin
			masterInterface.readEnabled <= 1;
			readingBlockState           <= WAITING_FOR_FUNCTION_COMPLETE;
		end	else if (readingBlockState == WAITING_FOR_FUNCTION_COMPLETE) begin
			if (masterInterface.functionComplete == 1) begin
				cacheInterface.cpuWriteData <= 1;
				masterInterface.readEnabled <= 0;
				readingBlockState           <= WRITING_DATA_TO_CACHE;
			end
		end else if (readingBlockState == WRITING_DATA_TO_CACHE) begin
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

				readingBlockState <= WRITING_TAG_AND_STATE_TO_CACHE;
			end else begin
				readingBlockState <= REQUEST_ISSUING;
			end
		end else if (readingBlockState == WRITING_TAG_AND_STATE_TO_CACHE) begin
			cacheInterface.cpuWriteTag   <= 0;
			cacheInterface.cpuWriteState <= 0;

			readingBlockState  <= REQUEST_ISSUING;
			cpuControllerState <= WAITING_FOR_REQUEST;
		end
	endtask : readBlock;

	//reset task
	task cpuControllerReset();
			cpuControllerState <= WAITING_FOR_REQUEST;
			readingBlockState  <= REQUEST_ISSUING;
			wordCounter        <= 0;
	endtask : cpuControllerReset

	//cpu controller 
	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			cpuControllerReset();
		end else begin
			case (cpuControllerState)
				//waiting for read or write request
				WAITING_FOR_REQUEST: begin
					if (slaveInterface.readEnabled == 1 || slaveInterface.writeEnabled == 1) begin
						if (cacheInterface.cpuHit == 1) begin
							slaveInterface.functionComplete <= 1;
							cpuControllerState              <= SERVE_REQUEST_FINISH;
							accessEnable                    <= 1;
						end else begin
							cpuControllerState <= READING_BLOCK;
						end
					end	
				end

				//reading block if not hit
				READING_BLOCK: begin
					readBlock();
				end	

				SERVE_REQUEST_FINISH: begin
					slaveInterface.functionComplete <=  0;
					cpuControllerState              <=  WAITING_FOR_REQUEST;
					accessEnable                    <=  0;
				end
			endcase
		end
	end
	//CPU_CONTROLLER_END
endmodule : MOESIFController
