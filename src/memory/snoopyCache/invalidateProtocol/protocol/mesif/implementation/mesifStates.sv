package MESIFStates;
	typedef enum logic[2 : 0] {
		MODIFIED,
		EXCLUSIVE,
		SHARED,
		INVALID,
		FORWARD
	} CacheLineState;
endpackage : MESIFStates
