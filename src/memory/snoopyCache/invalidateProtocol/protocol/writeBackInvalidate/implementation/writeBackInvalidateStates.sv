package writeBackInvalidateStates;
	typedef enum logic[1 : 0] {
		INVALID,
		VALID,
		DIRTY
	} CacheLineState;
endpackage : writeBackInvalidateStates
