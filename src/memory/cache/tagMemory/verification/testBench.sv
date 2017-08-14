module TestBench();
	
	TagUnitInterface tif();		

	SetAssociativeTagMemory#(
		.INVALID_STATE(0)
	) mem(
		.tagUnitInterface(tif)
	);
endmodule : TestBench
