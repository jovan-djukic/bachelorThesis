package types;

	typedef enum logic[2 : 0] {
		INVALID,
		MODIFIED,
		OWNED,
		EXCLUSIVE,
		SHARED,
		FORWARD	
	} State;

endpackage : types
