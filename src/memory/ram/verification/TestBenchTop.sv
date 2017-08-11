module TestBench();
	import uvm_pkg::*;
	import ramAgentPackage::*;
	import ramTestPackage::*;

	bit clock;

	always #5 clock = ~clock;

	MemoryInterface#(ADDRESS_WIDTH, DATA_WIDTH) memoryInterface(
		.clock(clock)
	);

	RAM#(
		.NUMBER_OF_BLOCKS(NUMBER_OF_BLOCKS),
		.WORDS_PER_BLOCK(WORDS_PER_BLOCK)
	) ram(
		.memoryInterface(memoryInterface)
	);

	initial begin
		uvm_config_db#(virtual MemoryInterface#(ADDRESS_WIDTH, DATA_WIDTH))::set(uvm_root::get(), "*", "MemoryInterface", memoryInterface);
		run_test("MemoryTest");
	end
endmodule : TestBench
