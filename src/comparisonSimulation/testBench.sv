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
			.DELAY(RAM_DELAY),
			.IS_TEST(IS_TEST)
		) basicRam(
			.memoryInterface(basicRamMemoryInterface),
			.clock(basicTestInterface.clock)
		);
	//BASIC_END

	//MSI_BEGIN
		TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) msiTestInterface();

		always #5 msiTestInterface.clock = ~msiTestInterface.clock;

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) msiMemoryInterface[NUMBER_OF_DEVICES]();

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) msiRamMemoryInterface();

		generate
			for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
				assign msiMemoryInterface[i].address      = msiTestInterface.dutInterface[i].memoryInterface.address;
				assign msiMemoryInterface[i].dataOut      = msiTestInterface.dutInterface[i].memoryInterface.dataOut;
				assign msiMemoryInterface[i].readEnabled  = msiTestInterface.dutInterface[i].memoryInterface.readEnabled;
				assign msiMemoryInterface[i].writeEnabled = msiTestInterface.dutInterface[i].memoryInterface.writeEnabled;

				assign msiTestInterface.dutInterface[i].memoryInterface.dataIn           = msiMemoryInterface[i].dataIn;
				assign msiTestInterface.dutInterface[i].memoryInterface.functionComplete = msiMemoryInterface[i].functionComplete;
			end
		endgenerate

		MSICacheSystem#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) msiCacheSystem(
			.deviceMemoryInterface(msiMemoryInterface),
			.ramMemoryInterface(msiRamMemoryInterface),
			.clock(msiTestInterface.clock),
			.reset(msiTestInterface.reset)
		);

		//ram memory
		RAM#(
			.DATA_WIDTH(DATA_WIDTH),
			.SIZE_IN_WORDS(SIZE_IN_WORDS),
			.DELAY(RAM_DELAY),
			.IS_TEST(IS_TEST)
		) msiRam(
			.memoryInterface(msiRamMemoryInterface),
			.clock(msiTestInterface.clock)
		);
	//MSI_END

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
			.DELAY(RAM_DELAY),
			.IS_TEST(IS_TEST)
		) mesiRam(
			.memoryInterface(mesiRamMemoryInterface),
			.clock(mesiTestInterface.clock)
		);
	//MESI_END

	//MESIF_BEGIN
		TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) mesifTestInterface();

		always #5 mesifTestInterface.clock = ~mesifTestInterface.clock;

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) mesifMemoryInterface[NUMBER_OF_DEVICES]();

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) mesifRamMemoryInterface();

		generate
			for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
				assign mesifMemoryInterface[i].address      = mesifTestInterface.dutInterface[i].memoryInterface.address;
				assign mesifMemoryInterface[i].dataOut      = mesifTestInterface.dutInterface[i].memoryInterface.dataOut;
				assign mesifMemoryInterface[i].readEnabled  = mesifTestInterface.dutInterface[i].memoryInterface.readEnabled;
				assign mesifMemoryInterface[i].writeEnabled = mesifTestInterface.dutInterface[i].memoryInterface.writeEnabled;

				assign mesifTestInterface.dutInterface[i].memoryInterface.dataIn           = mesifMemoryInterface[i].dataIn;
				assign mesifTestInterface.dutInterface[i].memoryInterface.functionComplete = mesifMemoryInterface[i].functionComplete;
			end
		endgenerate

		MESIFCacheSystem#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) mesifCacheSystem(
			.deviceMemoryInterface(mesifMemoryInterface),
			.ramMemoryInterface(mesifRamMemoryInterface),
			.clock(mesifTestInterface.clock),
			.reset(mesifTestInterface.reset)
		);

		//ram memory
		RAM#(
			.DATA_WIDTH(DATA_WIDTH),
			.SIZE_IN_WORDS(SIZE_IN_WORDS),
			.DELAY(RAM_DELAY),
			.IS_TEST(IS_TEST)
		) mesifRam(
			.memoryInterface(mesifRamMemoryInterface),
			.clock(mesifTestInterface.clock)
		);
	//MESIF_END

	//MOESI_BEGIN
		TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) moesiTestInterface();

		always #5 moesiTestInterface.clock = ~moesiTestInterface.clock;

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) moesiMemoryInterface[NUMBER_OF_DEVICES]();

		MemoryInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) moesiRamMemoryInterface();

		generate
			for (i = 0; i < NUMBER_OF_DEVICES; i++) begin
				assign moesiMemoryInterface[i].address      = moesiTestInterface.dutInterface[i].memoryInterface.address;
				assign moesiMemoryInterface[i].dataOut      = moesiTestInterface.dutInterface[i].memoryInterface.dataOut;
				assign moesiMemoryInterface[i].readEnabled  = moesiTestInterface.dutInterface[i].memoryInterface.readEnabled;
				assign moesiMemoryInterface[i].writeEnabled = moesiTestInterface.dutInterface[i].memoryInterface.writeEnabled;

				assign moesiTestInterface.dutInterface[i].memoryInterface.dataIn           = moesiMemoryInterface[i].dataIn;
				assign moesiTestInterface.dutInterface[i].memoryInterface.functionComplete = moesiMemoryInterface[i].functionComplete;
			end
		endgenerate

		MOESICacheSystem#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) moesiCacheSystem(
			.deviceMemoryInterface(moesiMemoryInterface),
			.ramMemoryInterface(moesiRamMemoryInterface),
			.clock(moesiTestInterface.clock),
			.reset(moesiTestInterface.reset)
		);

		//ram memory
		RAM#(
			.DATA_WIDTH(DATA_WIDTH),
			.SIZE_IN_WORDS(SIZE_IN_WORDS),
			.DELAY(RAM_DELAY),
			.IS_TEST(IS_TEST)
		) moesiRam(
			.memoryInterface(moesiRamMemoryInterface),
			.clock(moesiTestInterface.clock)
		);
	//MOESI_END

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
			.DELAY(RAM_DELAY),
			.IS_TEST(IS_TEST)
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
		))::set(uvm_root::get(), "*", MSI, msiTestInterface);

		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", MESI, mesiTestInterface);

		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", MESIF, mesifTestInterface);

		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", MOESI, moesiTestInterface);

		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		))::set(uvm_root::get(), "*", MOESIF, moesifTestInterface);

		run_test("MemoryTest");
	end
endmodule : TestBench
