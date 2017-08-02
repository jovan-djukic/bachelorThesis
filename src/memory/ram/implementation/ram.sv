module RAM#(
	int 		SIZE = 1024,
	string	INIT_FILE = ""
)(
	MemoryInterface.slave memoryInterface
);

	logic [memoryInterface.DATA_WIDTH - 1	: 0] memory[SIZE];
	
	initial begin
		if (INIT_FILE != "") begin
			$readmemh(INIT_FILE, memory);
		end
	end
	
	always_ff@(posedge memoryInterface.clock) begin
		if (memoryInterface.address < SIZE) begin
			if (memoryInterface.writeEnabled == 1) begin
				memory[memoryInterface.address] <= memoryInterface.dataOut;	
			end else if (memoryInterface.readEnabled  == 1) begin
				memoryInterface.dataIn <= memory[memoryInterface.address];		
			end
		end		
	end 

endmodule
