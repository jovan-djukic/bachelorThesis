package types;

	typedef enum logic[2 : 0] {
		MODIFIED,
		OWNED,
		EXCLUSIVE,
		SHARED,
		INVALID,
		FORWARD	
	} State;

endpackage : types
