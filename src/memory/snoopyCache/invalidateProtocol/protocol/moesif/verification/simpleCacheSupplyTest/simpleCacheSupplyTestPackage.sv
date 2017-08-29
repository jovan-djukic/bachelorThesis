package simpleCacheSupplyTestPackage;
	
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import baseTestPackage::*;
	import simpleReadTestPackage::*;
	import types::*;
	
	class SimpleCacheSupplyTransaction extends SimpleCacheReadTrasaction;
		`uvm_object_utils(SimpleCacheSupplyTransaction)

		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		function new(string name = "SimpleCacheSupplyTransaction");
			super.new(.name(name));
		endfunction : new	

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
			bit[OFFSET_WIDTH - 1 : 0] wordCounter = 0;
			//first read the block
			super.drive(.testInterface(testInterface));

			testInterface.busInterface.snoopyCommandIn = BUS_READ;
			testInterface.snoopyArbiterInterface.grant = 1;

			for (int i = 0; i < NUMBER_OF_WORDS; i++) begin
				testInterface.snoopySlaveInterface.address     = {super.address[ADDRESS_WITDH - 1 : OFFSET_WIDTH], wordCounter};
				testInterface.snoopySlaveInterface.readEnabled = 1;
				while (1) begin
					if (testInterface.snoopySlaveInterface.functionComplete == 1) begin
						break;
					end
					@(posedge testInterface.clock);	
				end
				testInterface.snoopySlaveInterface.readEnabled = 0;
				wordCounter++;
				@(posedge testInterface.clock);
			end

			testInterface.busInterface.snoopyCommandIn = NONE;
			testInterface.snoopyArbiterInterface.grant = 0;
			@(posedge testInterface.clock);
		endtask : drive
	endclass : SimpleCacheSupplyTransaction

	class SimpleCollectedCacheSupplyTransaction extends SimpleCacheReadCollectedTransaction;
		
		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;
		bit[DATA_WIDTH - 1    : 0] suppliedData[NUMBER_OF_WORDS], cachedData[NUMBER_OF_WORDS];
		bit[TAG_WIDTH - 1     : 0] tag;
		bit[INDEX_WIDTH - 1   : 0] index;
		bit[ADDRESS_WITDH - 1 : 0] snoopyAddress;
		CacheLineState stateIn, stateOut;
		bit stateWriten;

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
			super.collect(.testInterface(testInterface));
			
			for (int i = 0; i < NUMBER_OF_WORDS; i++) begin
				while (1) begin
					if (testInterface.cacheInterface.snoopyWriteState == 1) begin
						stateIn     = testInterface.cacheInterface.snoopyStateIn;
						stateOut    = testInterface.cacheInterface.snoopyStateOut;
						stateWriten = 1;
					end
					if (testInterface.snoopySlaveInterface.functionComplete == 1) begin
						break;
					end 
					@(posedge testInterface.clock);	
				end
				suppliedData[testInterface.snoopySlaveInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.snoopySlaveInterface.dataIn;
				cachedData[testInterface.snoopySlaveInterface.address[OFFSET_WIDTH - 1 : 0]]   = testInterface.cacheInterface.snoopyDataOut;
				@(posedge testInterface.clock);
			end

			tag           = testInterface.cacheInterface.snoopyTagIn;
			index         = testInterface.cacheInterface.snoopyIndex;
			snoopyAddress = testInterface.snoopySlaveInterface.address;
			@(posedge testInterface.clock);
		endtask : collect
	endclass : SimpleCollectedCacheSupplyTransaction
	
	class SimpleCacheSupplyTestModel extends SimpleCacheReadTestModel;

		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

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
			int errorCount = 0;
			SimpleCollectedCacheSupplyTransaction collectedTransaction;
			super.compare(.transaction(transaction));

			$cast(collectedTransaction, transaction);
	
			for (int i = 0; i < NUMBER_OF_WORDS; i++) begin
				if (collectedTransaction.suppliedData[i] != collectedTransaction.cachedData[i]) begin
					`uvm_error("DATA_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", collectedTransaction.cachedData[i], collectedTransaction.suppliedData[i]));
					errorCount++;
				end
			end

			if (collectedTransaction.stateWriten == 1 && ((collectedTransaction.stateOut == MODIFIED && collectedTransaction.stateIn != OWNED) || collectedTransaction.stateIn != SHARED)) begin
				`uvm_error("STATE_MISMATCH", "")
				errorCount++;
			end

			if (collectedTransaction.tag != collectedTransaction.snoopyAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
				`uvm_error("TAG_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", collectedTransaction.tag, collectedTransaction.snoopyAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]))
				errorCount++;
			end

			if (collectedTransaction.index != collectedTransaction.snoopyAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
				`uvm_error("INDEX_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", collectedTransaction.index, collectedTransaction.snoopyAddress[OFFSET_WIDTH +: TAG_WIDTH]))
				errorCount++;
			end

			if (errorCount == 0) begin
				`uvm_info("SIMPLE_CACHE_SUPPLY_TEST_MODEL::TEST_OK", "", UVM_LOW)
			end
		endfunction : compare
	endclass : SimpleCacheSupplyTestModel

	class SimpleCacheSupplyTestFactory extends BaseTestItemFactory#(
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

			return SimpleCacheSupplyTransaction::type_id::create(.name("simpleCacheReadTransaction"));
		endfunction : createCacheAccessTransaction

		virtual function BaseCollectedCacheTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createCollectedCacheTransaction();
			SimpleCollectedCacheSupplyTransaction collectedCacheTransaction = new();

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
			SimpleCacheSupplyTestModel testModel = new();

			return testModel;
		endfunction : createTestModel
	endclass : SimpleCacheSupplyTestFactory

	class SimpleCacheSupplyTest extends uvm_test;
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

		function new(string name = "SimpleCacheSupplyTest", uvm_component parent = null);
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

	endclass : SimpleCacheSupplyTest

endpackage : simpleCacheSupplyTestPackage
