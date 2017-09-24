package MOESIStates;
	typedef enum logic[2 : 0] {
		MODIFIED,
		OWNED,
		EXCLUSIVE,
		SHARED,
		INVALID
	} CacheLineState;
endpackage : MOESIStates
