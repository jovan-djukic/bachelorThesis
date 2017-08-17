module LRU(
  ReplacementAlgorithmInterface.slave replacementAlgorithmInterface,
	input logic clock, reset
);

  logic [replacementAlgorithmInterface.COUNTER_WIDTH - 1 : 0] counters[replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES];

  always_ff @(posedge clock, reset) begin
      if (reset == 1) begin
          for (int i = replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES - 1; i >= 0; i--) begin
            counters[i] <= i;
          end    
      end else begin
          if (replacementAlgorithmInterface.accessEnable == 1) begin
              for (int i = 0; i < replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES; i++) begin
                 if (counters[i] < counters[replacementAlgorithmInterface.lastAccessedCacheLine]) begin
                   counters[i] <= counters[i] + 1;
                 end
              end              

              counters[replacementAlgorithmInterface.lastAccessedCacheLine] <= 0;
          end else if (replacementAlgorithmInterface.invalidateEnable == 1) begin
						for (int i = 0; i < replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES; i++) begin
							if (counters[i] > counters[replacementAlgorithmInterface.lastAccessedCacheLine]) begin
								counters[i] <= counters[i] - 1;
							end

							counters[replacementAlgorithmInterface.lastAccessedCacheLine] <= replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES - 1;
						end
					end    
      end
  end;

  always_comb begin
    for (int i = 0; i < replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES; i++) begin
      if (counters[i] == replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES - 1) begin
        replacementAlgorithmInterface.replacementCacheLine = i;
      end
    end   
  end  	

endmodule
