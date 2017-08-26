package simpleReadTestPackage;
	
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import baseTestPackage::*;
	import types::*;

	localparam ADDRESS_WITDH     = 16;
	localparam DATA_WIDTH        = 16;
	localparam TAG_WIDTH         = 8;
	localparam INDEX_WIDTH       = 4;
	localparam OFFSET_WIDTH      = 4;
	localparam SET_ASSOCIATIVITY = 2;
	localparam SEQUENCE_COUNT    = 1000;

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
		
		function void myRandomize();
			address = $urandom();
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
			testInterface.slaveInterface.address     = address;
			testInterface.slaveInterface.readEnabled = 1;
			testInterface.busInterface.sharedIn      = isShared;
	
			do begin
				@(posedge testInterface.clock);

				if (testInterface.cacheInterface.cpuHit == 1) begin
					break;
				end else if (testInterface.masterInterface.readEnabled == 1) begin
					testInterface.masterInterface.dataIn = data;
					@(posedge testInterface.clock);
					testInterface.masterInterface.functionComplete = 1;
					@(posedge testInterface.clock);
					testInterface.masterInterface.functionComplete = 0;
				end
			end while (1);

			testInterface.slaveInterface.readEnabled = 0;
		endtask : drive
	endclass : SimpleCacheReadTrasaction

	class SimpleCacheReadSequence extends BaseCacheAccessSequence#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.SEQUENCE_COUNT(SEQUENCE_COUNT)
	);
		`uvm_object_utils(SimpleCacheReadSequence)

		function new(string name = "SimpleCacheReadSequence");
			super.new(.name(name));
		endfunction : new

		function SimpleCacheReadTrasaction createTransaction();
			return SimpleCacheReadTrasaction::type_id::create(.name("SimpleCacheReadTrasaction"));
		endfunction : createTransaction
	endclass : SimpleCacheReadSequence

	class SimpleCacheReadCollectedTransaction extends BaseCollectedCacheAccessTransaction#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

		logic[DATA_WIDTH - 1    : 0] cacheLine[NUMBER_OF_WORDS_PER_LINE], ramBlock[NUMBER_OF_WORDS_PER_LINE], readData;
		logic[ADDRESS_WITDH - 1 : 0] cpuAddress;
		logic[TAG_WIDTH - 1     : 0] tag;
		logic[INDEX_WIDTH - 1   : 0] index;
		logic 											 isShared, cpuHit;
		CacheLineState 						 	 state;

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

				if (testInterface.cacheInterface.cpuHit == 1) begin
					break;
				end else if (testInterface.masterInterface.readEnabled == 1 && testInterface.masterInterface.functionComplete == 1) begin
					ramBlock[testInterface.masterInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.masterInterface.dataIn;
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

			readData   = testInterface.slaveInterface.dataIn;
			cpuAddress = testInterface.slaveInterface.address;
		endtask : collect

	endclass : SimpleCacheReadCollectedTransaction

	class SimpleCacheReadMonitor extends BaseCacheAccessMonitor#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		
		`uvm_component_utils(SimpleCacheReadMonitor)

		function new(string name = "SimpleCacheReadMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new
		
		virtual function BaseCollectedCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createTransaction();
			SimpleCacheReadCollectedTransaction newTransaction = new();
			return newTransaction;
		endfunction : createTransaction
		
	endclass : SimpleCacheReadMonitor

	class SimpleCacheReadAgent extends BaseCacheAccessAgent#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		`uvm_component_utils(SimpleCacheReadAgent)

		function new(string name = "SimpleCacheReadAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function BaseCacheAccessMonitor#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createMonitor();
			return SimpleCacheReadMonitor::type_id::create(.name("monitor"), .parent(this));
		endfunction : createMonitor
	endclass : SimpleCacheReadAgent

	class SimpleCacheReadScoreboard extends BaseCacheAccessScoreboard#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		
		`uvm_component_utils(SimpleCacheReadScoreboard)

		localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

		function new(string name = "SimpleCacheReadScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void compare(
			BaseCollectedCacheAccessTransaction#(
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
						`uvm_error("SCOREBOARD::DATA_MISMATCH", "");
						errorCounter++;
					end
				end

				if (collectedTransaction.isShared == 1 && collectedTransaction.state != FORWARD) begin
					`uvm_error("SCOREBOARD::STATE_MISMATCH_FORWARD", "");
					errorCounter++;
				end

				if (collectedTransaction.isShared == 0 && collectedTransaction.state != EXCLUSIVE) begin
					`uvm_error("SCOREBOARD::STATE_MISMATCH_EXCLUSIVE", "");
					errorCounter++;
				end

				if (collectedTransaction.tag != collectedTransaction.cpuAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
					`uvm_error("SCOREBOARD::TAG_MISMATCH", "");
					errorCounter++;
				end

				if (collectedTransaction.index != collectedTransaction.cpuAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
					`uvm_error("SCOREBOARD::INDEX_MISMATCH", "");
					errorCounter++;
				end
			end	

			if (collectedTransaction.readData != collectedTransaction.ramBlock[collectedTransaction.cpuAddress[OFFSET_WIDTH - 1 : 0]]) begin
				`uvm_error("SCOREBOARD::DATA_MISMATCH", "")
				errorCounter++;
			end	

			if (errorCounter == 0) begin
				`uvm_info("SCOREBOARD::TEST_OK", "", UVM_LOW)
			end

		endfunction : compare 
	endclass : SimpleCacheReadScoreboard

	class SimpleCacheReadEnvironment extends BaseCacheAccessEnvironment#(
		.ADDRESS_WITDH(ADDRESS_WITDH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	);
		
		`uvm_component_utils(SimpleCacheReadEnvironment)

		function new(string name = "SimpleCacheReadEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function BaseCacheAccessScoreboard#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createScoreboard();
			return SimpleCacheReadScoreboard::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : createScoreboard

		virtual function BaseCacheAccessAgent#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createAgent();
			return SimpleCacheReadAgent::type_id::create(.name("agent"), .parent(this));
		endfunction : createAgent
	endclass : SimpleCacheReadEnvironment

	class SimpleCacheReadTest extends uvm_test;
		`uvm_component_utils(SimpleCacheReadTest)

		SimpleCacheReadEnvironment environment;

		function new(string name = "SimpleCacheReadTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			environment = SimpleCacheReadEnvironment::type_id::create(.name("environment"), .parent(this));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			SimpleCacheReadSequence testSequence = SimpleCacheReadSequence::type_id::create(.name("testSequence"));
			phase.raise_objection(this);
				testSequence.start(environment.agent.sequencer);	
			phase.drop_objection(this);
		endtask : run_phase

	endclass : SimpleCacheReadTest

endpackage : simpleReadTestPackage
