package types;
	import commands::*;

	localparam ADDRESS_WIDTH    = 8;
	localparam DATA_WIDTH       = 8;
	localparam NUMBER_OF_CACHES = 4;

	typedef struct {
		bit[ADDRESS_WIDTH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] dataOut;
		bit 											 readEnabled, writeEnabled;	
	} MemoryTransaction;

	typedef struct {
		bit[ADDRESS_WIDTH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] dataOut, dataIn;
		bit 											 readEnabled, writeEnabled, functionComplete;	
	} MemoryCollectedItem;

	typedef struct {
		Command commandOut;
	} CPUCommandTransaction;

	typedef struct {
		Command commandOut;
		logic isInvalidated;	
	} CPUCommandCollectedItem;

	typedef struct {
		bit[DATA_WIDTH - 1    : 0] dataIn;
		bit 											 functionComplete;	
	} ReadMemoryTransaction;

	typedef struct {
		bit[ADDRESS_WIDTH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] dataIn;
		bit 											 readEnabled, functionComplete;	
	} ReadMemoryCollectedItem;

	typedef struct {
		logic isInvalidated;	
	} SnoopyCommandTransaction;

	typedef struct {
		Command commandIn;
		logic isInvalidated;	
	} SnoopyCommandCollectedItem;
endpackage : types
