/*
	when reading replace line lru must not be edited, this is why we need to have a lock for such things, but this wont happen since we occupy the bus while reading it
*/
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
				if (!(replacementAlgorithmInterface.accessEnable == 1 && replacementAlgorithmInterface.invalidateEnable == 1 && 
					replacementAlgorithmInterface.lastAccessedCacheLine == replacementAlgorithmInterface.invalidatedCacheLine)) begin

					for (int i = 0; i < replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES; i++) begin
						if (replacementAlgorithmInterface.accessEnable == 1 && replacementAlgorithmInterface.invalidateEnable == 1) begin
							if (i != replacementAlgorithmInterface.lastAccessedCacheLine && i != replacementAlgorithmInterface.invalidatedCacheLine) begin
								if (counters[i] < counters[replacementAlgorithmInterface.invalidatedCacheLine] && 
									counters[i] < counters[replacementAlgorithmInterface.lastAccessedCacheLine]) begin
									
									counters[i] <= counters[i] + 1;

								end else if (counters[i] > counters[replacementAlgorithmInterface.invalidatedCacheLine] &&
														 counters[i] > counters[replacementAlgorithmInterface.lastAccessedCacheLine]) begin
									
									counters[i] <= counters[i] - 1;

								end
							end
						end else if (replacementAlgorithmInterface.accessEnable == 1) begin
							if (counters[i] < counters[replacementAlgorithmInterface.lastAccessedCacheLine]) begin
								counters[i] <= counters[i] + 1;
							end
						end else if (replacementAlgorithmInterface.invalidateEnable == 1) begin
							if (counters[i] > counters[replacementAlgorithmInterface.invalidatedCacheLine]) begin
								counters[i] <= counters[i] - 1;
							end
						end
					end
				end

				if (replacementAlgorithmInterface.accessEnable == 1) begin
					counters[replacementAlgorithmInterface.lastAccessedCacheLine] <= 0;
				end 
				if (replacementAlgorithmInterface.invalidateEnable == 1) begin
					counters[replacementAlgorithmInterface.invalidatedCacheLine] <= replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES - 1;
				end
      end
  end;

  always_comb begin
		replacementAlgorithmInterface.replacementCacheLine = 0;
    for (int i = 0; i < replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES; i++) begin
      if (counters[i] == replacementAlgorithmInterface.NUMBER_OF_CACHE_LINES - 1) begin
        replacementAlgorithmInterface.replacementCacheLine = i;
      end
    end   
  end  	
 endmodule
