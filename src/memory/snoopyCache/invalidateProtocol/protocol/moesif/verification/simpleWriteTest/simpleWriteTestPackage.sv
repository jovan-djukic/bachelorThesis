package simpleWriteTestPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import baseTestPackage::*;
	import types::*;

	localparam ADDRESS_WITDH       = 32;
	localparam DATA_WIDTH          = 32;
	localparam TAG_WIDTH           = 16;
	localparam INDEX_WIDTH         = 8;
	localparam OFFSET_WIDTH        = 8;
	localparam SET_ASSOCIATIVITY   = 4;
	localparam CACHE_ID            = 0;
	localparam NUMBER_OF_CACHES    = 8;
	localparam CACHE_NUMBER_WIDTH  = $clog2(NUMBER_OF_CACHES);
	localparam TEST_INTERFACE_NAME = "TestInterface";
	localparam TEST_FACTORY_NAME   = "TestFactory";
	localparam SEQUENCE_COUNT      = 1;

	class SimpleCacheWriteTransaction extends BaseCacheAccessTransaction#(
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

		`uvm_object_utils_begin(SimpleCacheWriteTransaction)
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

				//send invalidate acknowledgement messages if invalidate requested
				if (testInterface.busInterface.cpuCommandOut == BUS_INVALIDATE) begin
					testInterface.busInterface.cpuCommandIn = BUS_INVALIDATE;
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						testInterface.busInterface.cacheNumberIn = i; 	
						repeat (2) begin
							@(posedge testInterface.clock);
						end
					end
					testInterface.cpuArbiterInterface.grant = 0;
				end
			end

			testInterface.cpuSlaveInterface.writeEnabled = 0;

			while (testInterface.cpuSlaveInterface.functionComplete != 0) begin
				@(posedge testInterface.clock);
			end
		endtask : drive
	endclass : SimpleCacheWriteTransaction

	class SimpleCacheWriteCollectedTransaction extends BaseCollectedCacheTransaction#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH)
	);
		bit[NUMBER_OF_CACHES - 1 : 0] invalidated;
		bit[DATA_WIDTH - 1       : 0] writeData, cacheData;
		CacheLineState 								stateIn, stateOut;

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
			invalidated = 1 << CACHE_ID;
			do begin
				@(posedge testInterface.clock);

				//collect state, if cache is not present this if will be executed twice
				if (testInterface.cacheInterface.cpuWriteState == 1) begin
					stateIn  = testInterface.cacheInterface.cpuStateIn;
					stateOut = testInterface.cacheInterface.cpuStateOut;
				end

				if (testInterface.cpuSlaveInterface.functionComplete == 1) begin
					break;
				end
				
				//collect all invalidate messages
				if (testInterface.busInterface.cpuCommandOut == BUS_INVALIDATE) begin
					if (testInterface.busInterface.cpuCommandIn == BUS_INVALIDATE) begin
						invalidated[testInterface.cpuMasterInterface.dataIn[CACHE_NUMBER_WIDTH - 1 : 0]] = 1;
					end
				end

			end while (1);
			
			writeData = testInterface.cpuSlaveInterface.dataOut;
			cacheData = testInterface.cacheInterface.cpuDataOut;

			while (testInterface.cpuSlaveInterface.functionComplete != 0) begin
				@(posedge testInterface.clock);
			end
		endtask : collect

	endclass : SimpleCacheWriteCollectedTransaction

	class SimpleCacheWriteTestModel extends BaseTestModel#(
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
			SimpleCacheWriteCollectedTransaction collectedTransaction;

			$cast(collectedTransaction, transaction);
			
			if ((collectedTransaction.stateOut == EXCLUSIVE || collectedTransaction.stateOut == MODIFIED) && collectedTransaction.invalidated != (1 << CACHE_ID)) begin
				`uvm_error("UNNECESSARY_INVALIDATE_MESSAGES","")
				errorCounter++;
			end
			
			if ((collectedTransaction.stateOut != EXCLUSIVE && collectedTransaction.stateOut != MODIFIED) && collectedTransaction.invalidated == (1 << CACHE_ID)) begin
				`uvm_error("NO_INVALIDATE_MESSAGES", "")
				errorCounter++;
			end

			if (collectedTransaction.stateIn != MODIFIED) begin
				`uvm_error("MODIFIED_STATE_MISMATCH", "");
				errorCounter++;
			end
			
			if (collectedTransaction.writeData != collectedTransaction.cacheData) begin
				`uvm_error("DATA_MISMATCH", "")
				errorCounter++;
			end
			if (errorCounter == 0) begin
				`uvm_info("SIMPLE_CACHE_WRITE_TEST_MODEL::TEST_OK", "", UVM_LOW)
			end

		endfunction : compare 
	endclass : SimpleCacheWriteTestModel

	class SimpleCacheWriteTestItemFactory extends BaseTestItemFactory#(
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

			return SimpleCacheWriteTransaction::type_id::create(.name("simpleCacheReadTransaction"));
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
			SimpleCacheWriteCollectedTransaction collectedCacheTransaction = new();

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
			SimpleCacheWriteTestModel testModel = new();

			return testModel;
		endfunction : createTestModel
	endclass : SimpleCacheWriteTestItemFactory

	class SimpleCacheWriteTest extends uvm_test;
		`uvm_component_utils(SimpleCacheWriteTest)

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

		function new(string name = "SimpleCacheReadTest", uvm_component parent = null);
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

	endclass : SimpleCacheWriteTest
endpackage : simpleWriteTestPackage
