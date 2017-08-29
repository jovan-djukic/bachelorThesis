package types;
	typedef enum logic[2 : 0] {
		MODIFIED,
		OWNED,
		EXCLUSIVE,
		SHARED,
		FORWARD,
		INVALID
	} CacheLineState;

	typedef enum logic[1 : 0] {
		NONE,
		BUS_READ,
		BUS_INVALIDATE
	} BusCommand;
endpackage : types  
