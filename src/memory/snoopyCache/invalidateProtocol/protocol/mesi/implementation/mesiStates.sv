package MESIStates;
	typedef enum logic[1 : 0] {
		MODIFIED,
		EXCLUSIVE,
		SHARED,
		INVALID
	} CacheLineState;
endpackage : MESIStates
