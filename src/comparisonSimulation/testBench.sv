module TestBench();
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import testPackage::*;

	genvar i;

	//BASIC_BEGIN
		TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) basicTestInterface();

		always #5 basicTestInterface.clock = ~basicTestInterface.clock;

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) basicMemoryInterface[NUMBER_OF_DEVICES]();

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) basicRamMemoryInterface();

		generate
			for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
				assign basicMemoryInterface[i].address      = basicTestInterface.dutInterface[i].memoryInterface.address;
				assign basicMemoryInterface[i].dataOut      = basicTestInterface.dutInterface[i].memoryInterface.dataOut;
				assign basicMemoryInterface[i].readEnabled  = basicTestInterface.dutInterface[i].memoryInterface.readEnabled;
				assign basicMemoryInterface[i].writeEnabled = basicTestInterface.dutInterface[i].memoryInterface.writeEnabled;

				assign basicTestInterface.dutInterface[i].memoryInterface.dataIn           = basicMemoryInterface[i].dataIn;
				assign basicTestInterface.dutInterface[i].memoryInterface.functionComplete = basicMemoryInterface[i].functionComplete;
			end
		endgenerate

		BasicMemorySystem#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) basicMemorySystem(
			.deviceMemoryInterface(basicMemoryInterface),
			.ramMemoryInterface(basicRamMemoryInterface),
			.clock(basicTestInterface.clock),
			.reset(basicTestInterface.reset)
		);

		//ram memory
		RAM#(
			.DATA_WIDTH(DATA_WIDTH),
			.SIZE_IN_WORDS(SIZE_IN_WORDS),
			.DELAY(RAM_DELAY)
		) basicRam(
			.memoryInterface(basicRamMemoryInterface),
			.clock(basicTestInterface.clock)
		);
	//BASIC_END

	//WRITE_BACK_INVALIDATE_BEGIN
		TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) writeBackInvalidateTestInterface();

		always #5 writeBackInvalidateTestInterface.clock = ~writeBackInvalidateTestInterface.clock;

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) writeBackInvalidateMemoryInterface[NUMBER_OF_DEVICES]();

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) writeBackInvalidateRamMemoryInterface();

		generate
			for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
				assign writeBackInvalidateMemoryInterface[i].address      = writeBackInvalidateTestInterface.dutInterface[i].memoryInterface.address;
				assign writeBackInvalidateMemoryInterface[i].dataOut      = writeBackInvalidateTestInterface.dutInterface[i].memoryInterface.dataOut;
				assign writeBackInvalidateMemoryInterface[i].readEnabled  = writeBackInvalidateTestInterface.dutInterface[i].memoryInterface.readEnabled;
				assign writeBackInvalidateMemoryInterface[i].writeEnabled = writeBackInvalidateTestInterface.dutInterface[i].memoryInterface.writeEnabled;

				assign writeBackInvalidateTestInterface.dutInterface[i].memoryInterface.dataIn           = writeBackInvalidateMemoryInterface[i].dataIn;
				assign writeBackInvalidateTestInterface.dutInterface[i].memoryInterface.functionComplete = writeBackInvalidateMemoryInterface[i].functionComplete;
			end
		endgenerate

		WriteBackInvalidateCacheSystem#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) writeBackInvalidateCacheSystem(
			.deviceMemoryInterface(writeBackInvalidateMemoryInterface),
			.ramMemoryInterface(writeBackInvalidateRamMemoryInterface),
			.clock(writeBackInvalidateTestInterface.clock),
			.reset(writeBackInvalidateTestInterface.reset)
		);

		//ram memory
		RAM#(
			.DATA_WIDTH(DATA_WIDTH),
			.SIZE_IN_WORDS(SIZE_IN_WORDS),
			.DELAY(RAM_DELAY)
		) writeBackInvalidateRam(
			.memoryInterface(writeBackInvalidateRamMemoryInterface),
			.clock(writeBackInvalidateTestInterface.clock)
		);
	//WRITE_BACK_INVALIDATE_END

	//MESI_BEGIN
		TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) mesiTestInterface();

		always #5 mesiTestInterface.clock = ~mesiTestInterface.clock;

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) mesiMemoryInterface[NUMBER_OF_DEVICES]();

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) mesiRamMemoryInterface();

		generate
			for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
				assign mesiMemoryInterface[i].address      = mesiTestInterface.dutInterface[i].memoryInterface.address;
				assign mesiMemoryInterface[i].dataOut      = mesiTestInterface.dutInterface[i].memoryInterface.dataOut;
				assign mesiMemoryInterface[i].readEnabled  = mesiTestInterface.dutInterface[i].memoryInterface.readEnabled;
				assign mesiMemoryInterface[i].writeEnabled = mesiTestInterface.dutInterface[i].memoryInterface.writeEnabled;

				assign mesiTestInterface.dutInterface[i].memoryInterface.dataIn           = mesiMemoryInterface[i].dataIn;
				assign mesiTestInterface.dutInterface[i].memoryInterface.functionComplete = mesiMemoryInterface[i].functionComplete;
			end
		endgenerate

		MESICacheSystem#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) mesiCacheSystem(
			.deviceMemoryInterface(mesiMemoryInterface),
			.ramMemoryInterface(mesiRamMemoryInterface),
			.clock(mesiTestInterface.clock),
			.reset(mesiTestInterface.reset)
		);

		//ram memory
		RAM#(
			.DATA_WIDTH(DATA_WIDTH),
			.SIZE_IN_WORDS(SIZE_IN_WORDS),
			.DELAY(RAM_DELAY)
		) mesiRam(
			.memoryInterface(mesiRamMemoryInterface),
			.clock(mesiTestInterface.clock)
		);
	//MESI_END

	//MOESIF_BEGIN
		TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) moesifTestInterface();

		always #5 moesifTestInterface.clock = ~moesifTestInterface.clock;

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) moesifMemoryInterface[NUMBER_OF_DEVICES]();

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) moesifRamMemoryInterface();

		generate
			for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
				assign moesifMemoryInterface[i].address      = moesifTestInterface.dutInterface[i].memoryInterface.address;
				assign moesifMemoryInterface[i].dataOut      = moesifTestInterface.dutInterface[i].memoryInterface.dataOut;
				assign moesifMemoryInterface[i].readEnabled  = moesifTestInterface.dutInterface[i].memoryInterface.readEnabled;
				assign moesifMemoryInterface[i].writeEnabled = moesifTestInterface.dutInterface[i].memoryInterface.writeEnabled;

				assign moesifTestInterface.dutInterface[i].memoryInterface.dataIn           = moesifMemoryInterface[i].dataIn;
				assign moesifTestInterface.dutInterface[i].memoryInterface.functionComplete = moesifMemoryInterface[i].functionComplete;
			end
		endgenerate

		MOESIFCacheSystem#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) moesifCacheSystem(
			.deviceMemoryInterface(moesifMemoryInterface),
			.ramMemoryInterface(moesifRamMemoryInterface),
			.clock(moesifTestInterface.clock),
			.reset(moesifTestInterface.reset)
		);

		//ram memory
		RAM#(
			.DATA_WIDTH(DATA_WIDTH),
			.SIZE_IN_WORDS(SIZE_IN_WORDS),
			.DELAY(RAM_DELAY)
		) moesifRam(
			.memoryInterface(moesifRamMemoryInterface),
			.clock(moesifTestInterface.clock)
		);
	//MOESIF_END

	initial begin
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", BASIC, basicTestInterface);

		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", WBI, writeBackInvalidateTestInterface);

		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", MESI, mesiTestInterface);

		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", MOESIF, moesifTestInterface);

		run_test("MemoryTest");
	end
endmodule : TestBench
