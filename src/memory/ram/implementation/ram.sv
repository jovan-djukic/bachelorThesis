//DATA_WIDTH defines WORD size
module RAM#(
	int SIZE_IN_WORDS		 = 1024,
	int DELAY						 = 4,
	int COUNTER_WIDTH		 = DELAY < 2 ? 1 :
												 DELAY < 4 ? 2 :
												 DELAY < 8 ? 3 : 4,
	string	INIT_FILE 	 = ""
)(
	MemoryInterface.slave memoryInterface,
	input logic clock
);

	logic [memoryInterface.DATA_WIDTH - 1	: 0] memory[SIZE_IN_WORDS];

	//delay
	logic [COUNTER_WIDTH - 1 : 0] 					   counter;
	
	initial begin
		if (INIT_FILE != "") begin
			$readmemh(INIT_FILE, memory);
		end
	end

	assign memoryInterface.functionComplete = counter == 0 ? 1 : 0;
	
	always_ff@(posedge clock) begin
		counter	<= DELAY;
		if (memoryInterface.address < SIZE_IN_WORDS) begin
			if (memoryInterface.writeEnabled == 1) begin
				memory[memoryInterface.address] <= memoryInterface.dataOut;	
				if (counter != 0) begin
					counter <= counter - 1;
				end else begin
					counter <= 0;
				end
			end else if (memoryInterface.readEnabled  == 1) begin
				memoryInterface.dataIn <= memory[memoryInterface.address];		
				if (counter != 0) begin
					counter <= counter - 1;
				end else begin 
					counter <= 0;
				end 
			end
		end		
	end 

endmodule
