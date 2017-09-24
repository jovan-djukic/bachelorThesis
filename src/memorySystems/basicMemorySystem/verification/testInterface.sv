interface TestInterface#(
	int ADDRESS_WIDTH,
	int DATA_WIDTH,
	int NUMBER_OF_DEVICES
)();
	bit clock, reset;
	DUTInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) dutInterface[NUMBER_OF_DEVICES](
		.clock(clock),
		.reset(reset)
	);

	bit testDone;
	int clockCounter;

	initial clockCounter = 0;

	always @(posedge clock) begin
		if (testDone == 0) begin
			clockCounter++;
		end
	end 
endinterface : TestInterface
