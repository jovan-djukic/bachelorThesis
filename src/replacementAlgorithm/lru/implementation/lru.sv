module LRU(
  ReplacementAlgorithm replacementAlgorithm
);

  logic [replacementAlgorithm.COUNTER_WIDTH - 1 : 0] counters[replacementAlgorithm.NUMBER_OF_CACHE_LINES];

  always_ff @(posedge replacementAlgorithm.clock or posedge replacementAlgorithm.reset) begin
      if (replacementAlgorithm.reset == 1) begin
          for (int i = replacementAlgorithm.NUMBER_OF_CACHE_LINES - 1; i >= 0; i--) begin
            counters[i] <= i;
          end    
      end else begin
          if (replacementAlgorithm.enable == 1) begin
              for (int i = 0; i < replacementAlgorithm.NUMBER_OF_CACHE_LINES; i++) begin
                 if (counters[i] < counters[replacementAlgorithm.lastAccessedCacheLine]) begin
                   counters[i] <= counters[i] + 1;
                 end
              end              

              counters[replacementAlgorithm.lastAccessedCacheLine] <= 0;
          end     
      end
  end;

  always_comb begin
    for (int i = 0; i < replacementAlgorithm.NUMBER_OF_CACHE_LINES; i++) begin
      if (counters[i] == replacementAlgorithm.NUMBER_OF_CACHE_LINES - 1) begin
        replacementAlgorithm.replacementCacheLine = i;
      end
    end   
  end  	

endmodule
