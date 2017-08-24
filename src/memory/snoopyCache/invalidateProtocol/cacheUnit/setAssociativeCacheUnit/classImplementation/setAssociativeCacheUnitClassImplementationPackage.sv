package setAssociativeCacheUnitClassImplementationPackage;
	//class implementation	
	class SetAssociativeCacheUnitClassImplementation#(
		int TAG_WIDTH            = 8,
		int INDEX_WIDTH          = 4,
		int OFFSET_WIDTH         = 4,
		int SET_ASSOCIATIVITY    = 2,
		int DATA_WIDTH           = 16,
		type STATE_TYPE          = logic[1 : 0],
		STATE_TYPE INVALID_STATE = 2'b0
	);

		localparam NUMBER_OF_SMALLER_CACHES = 1 << SET_ASSOCIATIVITY;
		localparam NUMBER_OF_CACHE_LINES    = 1 << INDEX_WIDTH;
		localparam NUMBER_OF_WORDS_PER_LINE	= 1 << OFFSET_WIDTH;

		setAssociativeLRUClassImplementationPackage::SetAssociativeLRUClassImplementation#(
			.INDEX_WIDTH(INDEX_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) setAssociativeLRU;

		STATE_TYPE states[NUMBER_OF_SMALLER_CACHES][NUMBER_OF_CACHE_LINES];
		logic[TAG_WIDTH - 1  : 0] tags[NUMBER_OF_SMALLER_CACHES][NUMBER_OF_CACHE_LINES];
		logic[DATA_WIDTH - 1 : 0] data[NUMBER_OF_SMALLER_CACHES][NUMBER_OF_CACHE_LINES][NUMBER_OF_WORDS_PER_LINE];

		function new();
			setAssociativeLRU = new();	
			for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
				for (int j = 0; j < NUMBER_OF_CACHE_LINES; j++) begin
					states[i][j] = INVALID_STATE;
				end
			end
		endfunction : new

		virtual function logic isHit(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag);
			for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
				if (tags[i][index] == tag && states[i][index] != INVALID_STATE) begin
					return 1;
				end
			end
			return 0;
		endfunction : isHit

		virtual function logic[SET_ASSOCIATIVITY - 1 : 0] getCacheNumber(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag);
			for (int i = 0; i < NUMBER_OF_SMALLER_CACHES; i++) begin
				if (tags[i][index] == tag && states[i][index] != INVALID_STATE) begin
					return i;
				end
			end
			return setAssociativeLRU.getReplacementCacheLine(.index(index));
		endfunction : getCacheNumber

		virtual function void writeTag(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag);
			logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber = this.getCacheNumber(.index(index), .tag({TAG_WIDTH{1'bx}}));
			tags[cacheNumber][index] = tag;
		endfunction : writeTag

		virtual function void writeState(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag = {TAG_WIDTH{1'bx}}, STATE_TYPE state);
			logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber = this.getCacheNumber(.index(index), .tag(tag));
			states[cacheNumber][index] = state;
		endfunction : writeState

		virtual function void writeData(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag, logic[OFFSET_WIDTH - 1 : 0] offset, logic[DATA_WIDTH - 1 : 0] data);
			logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber = this.getCacheNumber(.index(index), .tag(tag));
			this.data[cacheNumber][index][offset] = data;
		endfunction : writeData	

		virtual function void writeDataToWholeLine(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag, logic[DATA_WIDTH - 1 : 0] data);
			for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
				this.writeData(.index(index), .tag(tag), .offset(i), .data(data));
			end
		endfunction : writeDataToWholeLine

		virtual function void access(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag);
			logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber = this.getCacheNumber(.index(index), .tag(tag));
			setAssociativeLRU.access(.index(index), .line(cacheNumber));
		endfunction : access

		virtual function logic[TAG_WIDTH - 1 : 0] getTag(logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber, logic[INDEX_WIDTH - 1 : 0] index);
			return tags[cacheNumber][index];
		endfunction : getTag

		virtual function STATE_TYPE getState(logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber, logic[INDEX_WIDTH - 1 : 0] index);
			return states[cacheNumber][index];
		endfunction : getState

		virtual function logic[DATA_WIDTH - 1 : 0] getData(logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber, logic[INDEX_WIDTH - 1 : 0] index, logic[OFFSET_WIDTH - 1 : 0] offset = (NUMBER_OF_WORDS_PER_LINE - 1));
			return data[cacheNumber][index][offset];
		endfunction : getData 

		virtual function void invalidate(logic[INDEX_WIDTH - 1 : 0] index, logic[TAG_WIDTH - 1 : 0] tag);
			logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber = this.getCacheNumber(.index(index), .tag(tag));
			setAssociativeLRU.invalidate(.index(index), .line(cacheNumber));
		endfunction : invalidate
	endclass : SetAssociativeCacheUnitClassImplementation

endpackage : setAssociativeCacheUnitClassImplementationPackage
