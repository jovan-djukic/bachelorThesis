package commands;
	typedef enum logic[1 : 0] {
		NONE,
		BUS_READ,
		BUS_INVALIDATE,
		BUS_WRITEBACK
	} Command;
endpackage : commands
