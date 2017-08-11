//DATA_WIDTH defines WORD size
module RAM#(
	int NUMBER_OF_BLOCKS = 128,
	int WORDS_PER_BLOCK	 = 8,
	int SIZE_IN_WORDS		 = NUMBER_OF_BLOCKS * WORDS_PER_BLOCK,
	string	INIT_FILE 	 = ""
)(
	MemoryInterface.slave memoryInterface
);

	logic [memoryInterface.DATA_WIDTH - 1	: 0] memory[SIZE_IN_WORDS];
	
	initial begin
		if (INIT_FILE != "") begin
			$readmemh(INIT_FILE, memory);
		end
	end
	
	always_ff@(posedge memoryInterface.clock) begin
		if (memoryInterface.address < SIZE_IN_WORDS) begin
			if (memoryInterface.writeEnabled == 1) begin
				memory[memoryInterface.address] <= memoryInterface.dataOut;	
			end else if (memoryInterface.readEnabled  == 1) begin
				memoryInterface.dataIn <= memory[memoryInterface.address];		
			end
		end		
	end 

endmodule
