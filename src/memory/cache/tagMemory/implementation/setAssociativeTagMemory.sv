module SetAssociativeTagMemory#(
	type STATE_TYPE = logic[1 : 0],
	STATE_TYPE INVALID_STATE = 0,
	int SET_ASSOCIATIVITY = 4
)(
	TagUnitInterface.slave tagUnitInterface,
	input logic clock, reset,
	//select signal for demultiplexers
	input logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumberIn,
	//select signal for out use i.e. replacement algorithm
	output logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumberOut
);

	localparam NUMBER_OF_SMALL_CACHES = 1 << SET_ASSOCIATIVITY;

	//instansiate interfaces and modules
	TagUnitInterface#(
		.STATE_TYPE(STATE_TYPE),
		.TAG_WIDTH(tagUnitInterface.TAG_WIDTH),
		.INDEX_WIDTH(tagUnitInterface.INDEX_WIDTH)
	)	tagUnitInterfaces[NUMBER_OF_SMALL_CACHES]();

	TagUnit#(
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	)	tagUnits[NUMBER_OF_SMALL_CACHES] (
		.tagUnitInterface(tagUnitInterfaces),
		.clock(clock),
		.reset(reset)
	);
	
	//TAG_INPUTS_BEGIN

	//these always have the same value, hence the generate block
	generate
		genvar i;
		for (i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			assign tagUnitInterfaces[i].index 	= tagUnitInterface.index;
			assign tagUnitInterfaces[i].tagIn 	= tagUnitInterface.tagIn;
			assign tagUnitInterfaces[i].stateIn	= tagUnitInterface.stateIn;
		end
	endgenerate	
	//these ones depend on the selected cache, hence demultiplexers

	//writeTag demultiplexer
	logic writeTags[NUMBER_OF_SMALL_CACHES];
	generate
		for (i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			assign tagUnitInterfaces[i].writeTag = writeTags[i];
		end
	endgenerate
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			writeTags[i] = 0;
		end
		writeTags[cacheNumberIn] = tagUnitInterface.writeTag;
	end

	//writeState demultiplexer
	logic writeStates[NUMBER_OF_SMALL_CACHES];
	generate
		for (i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			assign tagUnitInterfaces[i].writeState = writeStates[i];
		end
	endgenerate
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			writeStates[i] = 0;
		end
		writeStates[cacheNumberIn] = tagUnitInterface.writeState;
	end

	//TAG_INPUTS_END

	//TAG_OUTPUTS_BEGIN

	//this one depends on all of the hit signals
	logic[NUMBER_OF_SMALL_CACHES -1 : 0] individualTagHit;
	generate
		for (i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			assign individualTagHit[i] = tagUnitInterfaces[i].hit;
		end
	endgenerate
	assign tagUnitInterface.hit = (| individualTagHit);

	//tag memory number that generated hit signal
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			if (individualTagHit[i] == 1) begin
				cacheNumberOut = i;
			end
		end
	end		

	//tagOut multiplexer
	logic[tagUnitInterface.TAG_WIDTH - 1 : 0] tagOuts[NUMBER_OF_SMALL_CACHES];
	generate
		for (i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			assign tagOuts[i] = tagUnitInterfaces[i].tagOut;
		end
	endgenerate
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			if (cacheNumberOut == i) begin
				tagUnitInterface.tagOut = tagOuts[i];
			end
		end
	end	

	//stateOut multiplexer
	STATE_TYPE stateOuts[NUMBER_OF_SMALL_CACHES];
	generate
		for (i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			assign stateOuts[i] = tagUnitInterfaces[i].stateOut;
		end
	endgenerate
	always_comb begin
		for (int i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
			if (cacheNumberOut == i) begin
				tagUnitInterface.stateOut = stateOuts[i];
			end
		end
	end

	//TAG_OUTPUTS_END

endmodule : SetAssociativeTagMemory
