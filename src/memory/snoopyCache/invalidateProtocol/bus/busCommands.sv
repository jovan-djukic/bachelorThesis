package busCommands;
	typedef enum logic[1 : 0] {
		NONE,
		BUS_READ,
		BUS_INVALIDATE,
		BUS_WRITEBACK
	} BusCommand;
endpackage : busCommands
