package simpleWriteBackTestPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import baseTestPackage::*;
	import types::*;

	localparam ADDRESS_WITDH       = 16;
	localparam DATA_WIDTH          = 16;
	localparam TAG_WIDTH           = 8;
	localparam INDEX_WIDTH         = 4;
	localparam OFFSET_WIDTH        = 4;
	localparam SET_ASSOCIATIVITY   = 2;
	localparam CACHE_ID            = 0;
	localparam NUMBER_OF_CACHES    = 4;
	localparam CACHE_NUMBER_WIDTH  = $clog2(NUMBER_OF_CACHES);
	localparam TEST_INTERFACE_NAME = "TestInterface";
	localparam TEST_FACTORY_NAME   = "TestFactory";
	localparam SEQUENCE_COUNT      = 1000;

	localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

	class SimpleCacheWriteBackTransaction extends BaseCacheAccessTransaction#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
	);
		bit[ADDRESS_WITDH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] ramData, writeData;
		bit 											 isShared;

		`uvm_object_utils_begin(SimpleCacheWriteBackTransaction)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(ramData, UVM_ALL_ON)
			`uvm_field_int(writeData, UVM_ALL_ON)
			`uvm_field_int(isShared, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SimpleCacheReadTrasaction");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			address   = $urandom();
			ramData   = $urandom();
			writeData = $urandom();
			isShared 	= $urandom();
		endfunction : myRandomize

		virtual task drive(
			virtual TestInterface#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
			) testInterface
		);
			testInterface.cpuSlaveInterface.address      = address;
			testInterface.cpuSlaveInterface.dataOut      = writeData;
			testInterface.cpuSlaveInterface.writeEnabled = 1;

			testInterface.busInterface.sharedIn = isShared;

			while (1) begin
				@(posedge testInterface.clock);
				testInterface.cpuArbiterInterface.grant = testInterface.cpuArbiterInterface.request;
				if (testInterface.cpuSlaveInterface.functionComplete == 1) begin
					break;
				end
				if (testInterface.cpuMasterInterface.readEnabled == 1) begin
					testInterface.cpuMasterInterface.dataIn = ramData;
					@(posedge testInterface.clock);
					testInterface.cpuMasterInterface.functionComplete = 1;
					@(posedge testInterface.clock);
					testInterface.cpuMasterInterface.functionComplete = 0;
					ramData++;
				end

				if (testInterface.cpuMasterInterface.writeEnabled == 1) begin
					testInterface.cpuMasterInterface.functionComplete = 1;
					while (testInterface.cpuMasterInterface.writeEnabled == 1) begin
						@(posedge testInterface.clock);
					end
					testInterface.cpuMasterInterface.functionComplete = 0;
				end

				//send invalidate acknowledgement messages if invalidate requested
				if (testInterface.busInterface.cpuCommandOut == BUS_INVALIDATE) begin
					testInterface.busInterface.cpuCommandIn = BUS_INVALIDATE;
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						testInterface.busInterface.cacheNumberIn = i; 	
						repeat (2) begin
							@(posedge testInterface.clock);
						end
					end
				end
			end

			testInterface.cpuSlaveInterface.writeEnabled = 0;
			testInterface.cpuArbiterInterface.grant      = 0;

			while (testInterface.cpuSlaveInterface.functionComplete != 0) begin
				@(posedge testInterface.clock);
			end
		endtask : drive
	endclass : SimpleCacheWriteBackTransaction

	class SimpleCacheWriteBackCollectedTransaction extends BaseCollectedCacheTransaction#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
	);
		bit[TAG_WIDTH - 1     : 0] writeBackTag;
		bit[INDEX_WIDTH - 1   : 0] writeBackIndex;
		bit[DATA_WIDTH - 1    : 0] writeBackData[NUMBER_OF_WORDS_PER_LINE], cacheData[NUMBER_OF_WORDS_PER_LINE];
		bit[ADDRESS_WITDH - 1 : 0] writeBackAddress;
		bit												 writeBackOccured;
		CacheLineState writeBackStateOut, writeBackStateIn;

		virtual task collect(
			virtual TestInterface#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
			) testInterface
		);
			do begin
				@(posedge testInterface.clock);

				if (testInterface.cpuSlaveInterface.functionComplete == 1) begin
					break;
				end

				if (testInterface.cacheInterface.cpuWriteState == 1 && testInterface.busInterface.cpuCommandOut == BUS_WRITEBACK) begin
					writeBackStateIn = testInterface.cacheInterface.cpuStateIn;
				end

				if (testInterface.cpuMasterInterface.writeEnabled == 1) begin
					writeBackStateOut = testInterface.cacheInterface.cpuStateOut;
					writeBackAddress  = testInterface.cpuMasterInterface.address;
					writeBackTag      = testInterface.cacheInterface.cpuTagOut;
					writeBackIndex    = testInterface.cacheInterface.cpuIndex;

					//collect data
					writeBackData[testInterface.cpuMasterInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.cpuMasterInterface.dataOut;
					cacheData[testInterface.cacheInterface.cpuOffset]                             = testInterface.cacheInterface.cpuDataOut;

					//set flag
					writeBackOccured = 1;
				end				
			end while (1);
			

			while (testInterface.cpuSlaveInterface.functionComplete != 0) begin
				@(posedge testInterface.clock);
			end
		endtask : collect

	endclass : SimpleCacheWriteBackCollectedTransaction

	class SimpleCacheWriteBackTestModel extends BaseTestModel#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
	);
		virtual function void compare(
			BaseCollectedCacheTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
			) transaction
		);
			int errorCounter = 0;	
			SimpleCacheWriteBackCollectedTransaction collectedTransaction;

			$cast(collectedTransaction, transaction);
			
			if (collectedTransaction.writeBackOccured == 0) begin
				return;
			end

			if (collectedTransaction.writeBackStateIn != INVALID) begin
				`uvm_error("INVALID_STATE_MISMATCH", "")
				errorCounter++;
			end

			if (collectedTransaction.writeBackStateOut != MODIFIED && collectedTransaction.writeBackStateOut != OWNED) begin
				`uvm_error("WRITE_BACK_STATE_MISMATCH", "")
				errorCounter++;
			end

			if (collectedTransaction.writeBackAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH] != collectedTransaction.writeBackTag) begin
				`uvm_error("TAG_MISMATCH", "")
				errorCounter++;
			end

			if (collectedTransaction.writeBackAddress[OFFSET_WIDTH +: INDEX_WIDTH] != collectedTransaction.writeBackIndex) begin
				`uvm_error("INDEX_MISMATCH", "")
				errorCounter++;
			end

			for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
				if (collectedTransaction.writeBackData[i] != collectedTransaction.cacheData[i]) begin
					`uvm_error("DATA_MISMATCH", "")
					errorCounter++;
				end
			end
			
			if (errorCounter == 0) begin
				`uvm_info("TEST_OK", "", UVM_LOW);
			end
		endfunction : compare 
	endclass : SimpleCacheWriteBackTestModel

	class SimpleCacheWriteBackTestItemFactory extends BaseTestItemFactory#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
	);
		virtual function BaseCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
		) createCacheAccessTransaction();

			return SimpleCacheWriteBackTransaction::type_id::create(.name("simpleCacheReadTransaction"));
		endfunction : createCacheAccessTransaction

		virtual function BaseCollectedCacheTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
		) createCollectedCacheTransaction();
			SimpleCacheWriteBackCollectedTransaction collectedCacheTransaction = new();

			return collectedCacheTransaction;
		endfunction : createCollectedCacheTransaction

		virtual function BaseTestModel#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
		) createTestModel();
			SimpleCacheWriteBackTestModel testModel = new();

			return testModel;
		endfunction : createTestModel
	endclass : SimpleCacheWriteBackTestItemFactory

	class SimpleCacheWriteBackTest extends uvm_test;
		`uvm_component_utils(SimpleCacheWriteBackTest)

		BaseCacheAccessEnvironment#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
			.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
			.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
		) environment;

		function new(string name = "SimpleCacheBackTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			environment = BaseCacheAccessEnvironment#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
				.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
			)::type_id::create(.name("environment"), .parent(this));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			BaseCacheAccessSequence#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME),
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			) testSequence = BaseCacheAccessSequence#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME),
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			)::type_id::create(.name("testSequence"));
			phase.raise_objection(this);
				testSequence.start(environment.agent.sequencer);	
			phase.drop_objection(this);
		endtask : run_phase

	endclass : SimpleCacheWriteBackTest
endpackage : simpleWriteBackTestPackage
