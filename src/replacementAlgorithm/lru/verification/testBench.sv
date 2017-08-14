module TestBenchTop;
  import lruVerification::*;
  import replacementAlgorithmVerification::*;
  import uvm_pkg::*;

	TestInterface#(.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)) testInterface();

  always #5 testInterface.clock = ~testInterface.clock;

    
  LRU lru (
    .replacementAlgorithmInterface(testInterface.replacementAlgorithmInterface),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
  );

  initial begin
    uvm_config_db#(virtual TestInterface#(.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)))::set(uvm_root::get(), "*", "TestInterface", testInterface);
    run_test("LRUTest");
  end
endmodule
