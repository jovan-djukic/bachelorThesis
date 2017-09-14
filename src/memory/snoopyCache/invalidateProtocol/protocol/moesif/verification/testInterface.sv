interface TestInterface#(
	type STATE_TYPE = logic[1 : 0]
)();
	CPUProtocolInterface#(
		.STATE_TYPE(STATE_TYPE)
	) cpuProtocolInterface();

	SnoopyProtocolInterface#(
		.STATE_TYPE(STATE_TYPE)
	) snoopyProtocolInterface();
	
	MOESIFInterface moesifInterface();

	bit clock;

endinterface : TestInterface
