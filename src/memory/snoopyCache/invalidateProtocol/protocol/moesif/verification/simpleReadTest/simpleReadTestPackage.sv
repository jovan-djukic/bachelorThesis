package simpleReadTestPackage;
	
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
	localparam TEST_INTERFACE_NAME = "TestInterface";
	localparam TEST_FACTORY_NAME   = "TestFactory";
	localparam SEQUENCE_COUNT      = 1000;

	class SimpleCacheReadTrasaction extends BaseCacheAccessTransaction#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);

		bit[ADDRESS_WITDH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] data;
		bit 											 isShared;

		`uvm_object_utils_begin(SimpleCacheReadTrasaction)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(data, UVM_ALL_ON)
			`uvm_field_int(isShared, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SimpleCacheReadTrasaction");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			address  = $urandom();
			data     = $urandom();
			isShared = $urandom();
		endfunction : myRandomize

		virtual task drive(
			virtual TestInterface#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) testInterface
		);
			testInterface.cpuSlaveInterface.address     = address;
			testInterface.cpuSlaveInterface.readEnabled = 1;
			testInterface.busInterface.sharedIn         = isShared;
	
			do begin
				@(posedge testInterface.clock);

				if (testInterface.cpuSlaveInterface.functionComplete == 1) begin
					break;
				end

				testInterface.cpuArbiterInterface.grant = testInterface.cpuArbiterInterface.request;

				if (testInterface.cpuMasterInterface.readEnabled == 1) begin
					testInterface.cpuMasterInterface.dataIn = data;
					@(posedge testInterface.clock);
					testInterface.cpuMasterInterface.functionComplete = 1;
					while (testInterface.cpuMasterInterface.readEnabled != 0) begin
						@(posedge testInterface.clock);
					end
					testInterface.cpuMasterInterface.functionComplete = 0;
					data++;
				end
			end while (1);

			testInterface.cpuSlaveInterface.readEnabled = 0;
			@(posedge testInterface.clock);
		endtask : drive
	endclass : SimpleCacheReadTrasaction

	class SimpleCacheReadCollectedTransaction extends BaseCollectedCacheTransaction#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

		bit[DATA_WIDTH - 1    : 0] cacheLine[NUMBER_OF_WORDS_PER_LINE], ramBlock[NUMBER_OF_WORDS_PER_LINE], readData, cacheData;
		bit[ADDRESS_WITDH - 1 : 0] cpuAddress;
		bit[TAG_WIDTH - 1     : 0] tag;
		bit[INDEX_WIDTH - 1   : 0] index;
		bit 											 isShared, cpuHit;
		CacheLineState 						 state;

		virtual task collect(
			virtual TestInterface#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) testInterface
		);
			cpuHit = 1;	
			do begin
				@(posedge testInterface.clock);

				if (testInterface.cpuSlaveInterface.functionComplete == 1) begin
					break;
				end
				if (testInterface.cpuMasterInterface.functionComplete == 1) begin
					ramBlock[testInterface.cpuMasterInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.cpuMasterInterface.dataIn;
					cpuHit = 0;
				end
				if (testInterface.cacheInterface.cpuWriteData == 1) begin
					cacheLine[testInterface.cacheInterface.cpuOffset] = testInterface.cacheInterface.cpuDataIn;
				end
				if (testInterface.cacheInterface.cpuWriteState == 1) begin
					state    = testInterface.cacheInterface.cpuStateIn;
					isShared = testInterface.busInterface.sharedIn;
				end
				if (testInterface.cacheInterface.cpuWriteTag == 1) begin
					tag   = testInterface.cacheInterface.cpuTagIn;
					index = testInterface.cacheInterface.cpuIndex;
				end

			end while (1);

			cacheData  = testInterface.cacheInterface.cpuDataOut;
			readData   = testInterface.cpuSlaveInterface.dataIn;
			cpuAddress = testInterface.cpuSlaveInterface.address;
			@(posedge testInterface.clock);
		endtask : collect

	endclass : SimpleCacheReadCollectedTransaction

	class SimpleCacheReadTestModel extends BaseTestModel#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

		virtual function void compare(
			BaseCollectedCacheTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) transaction
		);
			int errorCounter = 0;	
			SimpleCacheReadCollectedTransaction collectedTransaction;

			$cast(collectedTransaction, transaction);
			
			if (collectedTransaction.cpuHit == 0) begin
				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					if (collectedTransaction.cacheLine[i] != collectedTransaction.ramBlock[i]) begin
						`uvm_error("SIMPLE_CACHE_READ_TEST_MODEL::RAM_DATA_MISMATCH", "");
						errorCounter++;
					end
				end

				if (collectedTransaction.isShared == 1 && collectedTransaction.state != FORWARD) begin
					`uvm_error("SIMPLE_CACHE_READ_TEST_MODEL::STATE_MISMATCH_FORWARD", "");
					errorCounter++;
				end

				if (collectedTransaction.isShared == 0 && collectedTransaction.state != EXCLUSIVE) begin
					`uvm_error("SIMPLE_CACHE_READ_TEST_MODEL::STATE_MISMATCH_EXCLUSIVE", "");
					errorCounter++;
				end

				if (collectedTransaction.tag != collectedTransaction.cpuAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
					`uvm_error("SIMPLE_CACHE_READ_TEST_MODEL::TAG_MISMATCH", "");
					errorCounter++;
				end

				if (collectedTransaction.index != collectedTransaction.cpuAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
					`uvm_error("SIMPLE_CACHE_READ_TEST_MODEL::INDEX_MISMATCH", "");
					errorCounter++;
				end
			end	

			if (collectedTransaction.readData != collectedTransaction.cacheData) begin
				`uvm_error("SIMPLE_CACHE_READ_TEST_MODEL::READ_DATA_MISMATCH", "")
				errorCounter++;
			end	

			if (errorCounter == 0) begin
				`uvm_info("SIMPLE_CACHE_READ_TEST_MODEL::TEST_OK", "", UVM_LOW)
			end

		endfunction : compare 
	endclass : SimpleCacheReadTestModel

	class SimpleCacheReadTestItemFactory extends BaseTestItemFactory#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		virtual function BaseCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createCacheAccessTransaction();

			return SimpleCacheReadTrasaction::type_id::create(.name("simpleCacheReadTransaction"));
		endfunction : createCacheAccessTransaction

		virtual function BaseCollectedCacheTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createCollectedCacheTransaction();
			SimpleCacheReadCollectedTransaction collectedCacheTransaction = new();

			return collectedCacheTransaction;
		endfunction : createCollectedCacheTransaction

		virtual function BaseTestModel#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createTestModel();
			SimpleCacheReadTestModel testModel = new();

			return testModel;
		endfunction : createTestModel
	endclass : SimpleCacheReadTestItemFactory

	class SimpleCacheReadTest extends uvm_test;
		`uvm_component_utils(SimpleCacheReadTest)

		BaseCacheAccessEnvironment#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
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
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME),
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			) testSequence = BaseCacheAccessSequence#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME),
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			)::type_id::create(.name("testSequence"));
			phase.raise_objection(this);
				testSequence.start(environment.agent.sequencer);	
			phase.drop_objection(this);
		endtask : run_phase

	endclass : SimpleCacheReadTest

endpackage : simpleReadTestPackage
