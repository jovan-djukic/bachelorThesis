module TestBenchTop;
  import lruVerification::*;
  import replacementAlgorithmVerification::*;
  import uvm_pkg::*;

  bit clock;
  always #5 clock = ~clock;

  ReplacementAlgorithm#(.NUMBER_OF_CACHE_LINES(NUMBER_OF_CACHE_LINES)) replacementAlgorithmInterface(.clock(clock));  
    
  LRU lru (
    .replacementAlgorithm(replacementAlgorithmInterface)
  );

  initial begin
    uvm_config_db#(virtual ReplacementAlgorithm#(NUMBER_OF_CACHE_LINES))::set(uvm_root::get(), "*", "ReplacementAlgorithm", replacementAlgorithmInterface);
    run_test("LRUTest");
  end
endmodule
