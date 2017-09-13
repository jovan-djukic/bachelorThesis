package setAssociativeLRUClassImplementationPackage;
	//class representing lru algorithm, used for verification
	class SetAssociativeLRUClassImplementation#(
		int INDEX_WIDTH,
		int SET_ASSOCIATIVITY
	);
		
		localparam NUMBER_OF_LRUS        = 1 << INDEX_WIDTH;
		localparam NUMBER_OF_CACHE_LINES = 1 << SET_ASSOCIATIVITY;

		int counters[NUMBER_OF_LRUS][NUMBER_OF_CACHE_LINES];

		function new();
			for (int i = 0; i < NUMBER_OF_LRUS; i++) begin
				for (int j = 0; j < NUMBER_OF_CACHE_LINES; j++) begin
					counters[i][j] = j;
				end
			end
		endfunction : new

		function void access(logic[INDEX_WIDTH - 1 : 0] index, logic[SET_ASSOCIATIVITY - 1 : 0] line);
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				if (counters[index][i] < counters[index][line]) begin
					counters[index][i]++;
				end
			end

			counters[index][line] = 0;
		endfunction : access

		function void invalidate(logic[INDEX_WIDTH - 1 : 0] index, logic[SET_ASSOCIATIVITY - 1 : 0] line);
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				if (counters[index][i] > counters[index][line]) begin
					counters[index][i]--;
				end
			end

			counters[index][line] = NUMBER_OF_CACHE_LINES - 1;
		endfunction : invalidate

		function void accessAndInvalidate(logic[INDEX_WIDTH - 1 : 0] cpuIndex, snoopyIndex, logic[SET_ASSOCIATIVITY - 1 : 0] cpuLine, snoopyLine);
			this.access(.index(cpuIndex), .line(cpuLine));
			this.invalidate(.index(snoopyIndex), .line(snoopyLine));
		endfunction : accessAndInvalidate

		function logic[SET_ASSOCIATIVITY - 1 : 0] getReplacementCacheLine(logic[INDEX_WIDTH - 1 : 0] index);
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				if (counters[index][i] == (NUMBER_OF_CACHE_LINES - 1)) begin
					return i;
				end
			end	
		endfunction : getReplacementCacheLine

	endclass : SetAssociativeLRUClassImplementation
endpackage : setAssociativeLRUClassImplementationPackage
