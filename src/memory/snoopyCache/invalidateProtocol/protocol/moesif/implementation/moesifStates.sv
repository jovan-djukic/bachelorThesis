package MOESIFStates;
	typedef enum logic[2 : 0] {
		MODIFIED,
		OWNED,
		EXCLUSIVE,
		SHARED,
		INVALID,
		FORWARD	
	} CacheLineState;
endpackage : MOESIFStates
