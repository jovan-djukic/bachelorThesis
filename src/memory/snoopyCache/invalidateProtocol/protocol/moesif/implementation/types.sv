package types;
	typedef enum logic[2 : 0] {
		MODIFIED,
		OWNDED,
		EXCLUSIVE,
		SHARED,
		FORWARD,
		INVALID
	} CacheLineState;

	typedef enum logic[1 : 0] {
		NONE,
		BUS_READ	
	} BusCommand;
endpackage : types  
