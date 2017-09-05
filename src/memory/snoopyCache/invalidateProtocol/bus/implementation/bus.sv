module SnoopyBus#(
	int NUMBER_OF_CACHES = 4
)(
	MemoryInterface.slave cpuMasterInterface[NUMBER_OF_CACHES],
	ReadMemoryInterface.master snoopySlaveInterface[NUMBER_OF_CACHES],
	CommandInterface.bus commandInterface[NUMBER_OF_CACHES],
	input logic[NUMBER_OF_CACHES - 1 : 0] masterGrants, slaveGrants,
	MemoryInterface.master masterInterface
);
endmodule : SnoopyBus
