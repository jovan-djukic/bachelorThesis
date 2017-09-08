package commands;
	typedef enum logic[2 : 0] {
		NONE,
		BUS_READ,
		BUS_READ_EXCLUSIVE,
		BUS_INVALIDATE,
		BUS_WRITEBACK
	} Command;
endpackage : commands
