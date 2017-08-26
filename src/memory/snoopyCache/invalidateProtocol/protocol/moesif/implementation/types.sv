package types;
	typedef enum logic[2 : 0] {
		MODIFIED,
		OWNDED,
		EXCLUSIVE,
		SHARED,
		FORWARD,
		INVALID
	} CacheLineState;
endpackage : types  
