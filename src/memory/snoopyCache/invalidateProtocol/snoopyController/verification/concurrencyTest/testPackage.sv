package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import commands::*;
	import cases::*;

	typedef enum logic[1 : 0] {
		INVALID,
		VALID,
		DIRTY
	} CacheLineState;

	localparam ADDRESS_WIDTH            = 32;
	localparam DATA_WIDTH               = 32;
	localparam TAG_WIDTH                = 16;
	localparam INDEX_WIDTH              = 8;
	localparam OFFSET_WIDTH             = 8;
	localparam SET_ASSOCIATIVITY        = 4;
	localparam NUMBER_OF_CACHES         = 8;
	localparam CACHE_NUMBER_WIDTH       = $clog2(NUMBER_OF_CACHES);
	localparam CACHE_ID								  = 0;
	localparam type STATE_TYPE          = CacheLineState;
	localparam STATE_TYPE INVALID_STATE = INVALID;
	localparam SEQUENCE_ITEM_COUNT      = 1000;
	localparam TEST_INTERFACE           = "TestInterface";

	localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

	localparam CONCURRENCY_CASE_SET_LENGTH = 6;
	localparam ConcurrencyCase CONCURRENCY_CASE_SET[CONCURRENCY_CASE_SET_LENGTH] = {
																																			READ_BUS_INVALIDATE,
																																			WRITE_BUS_READ_NO_INVALIDATE,
																																			WRITE_BUS_READ_INVALIDATE,
																																			WRITE_BUS_INVALIDATE,
																																			WRITE_BACK_BUS_READ,
																																			WRITE_BACK_BUS_INVALIDATE
																																		};

	class ConcurrencySequenceItem extends BasicSequenceItem;
		bit[ADDRESS_WIDTH - 1 : 0] address;
		ConcurrencyCase						 concurrencyCase;

		`uvm_object_utils_begin(ConcurrencySequenceItem)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_enum(ConcurrencyCase, concurrencyCase, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "ConcurrencySequenceItem");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			address         = $urandom();
			concurrencyCase = CONCURRENCY_CASE_SET[$urandom() % CONCURRENCY_CASE_SET_LENGTH];
		endfunction : myRandomize
	endclass : ConcurrencySequenceItem

	class ConcurrencyDriver extends BasicDriver;
		`uvm_component_utils(ConcurrencyDriver)

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)
		) testInterface;

		function new(string name = "ConcurrencyDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.INVALID_STATE(INVALID_STATE)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
			testInterface.cpuSlaveInterface.readEnabled  = 0;
			testInterface.cpuSlaveInterface.writeEnabled = 0;

			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
		endtask : resetDUT

		virtual task drive();
			ConcurrencySequenceItem sequenceItem;
			$cast(sequenceItem, req);

			testInterface.cpuSlaveInterface.address    = sequenceItem.address;
			testInterface.snoopySlaveInterface.address = sequenceItem.address;
			
			testInterface.concurrencyCase = sequenceItem.concurrencyCase;
			@(posedge testInterface.clock);

			case (testInterface.concurrencyCase)
				READ_BUS_INVALIDATE: begin
					testInterface.cacheInterface.cpuHit         = 1;
					testInterface.cpuSlaveInterface.readEnabled = 1;

					@(posedge testInterface.clock);

					testInterface.cacheInterface.snoopyHit         = 1;
					testInterface.commandInterface.snoopyCommandIn = BUS_INVALIDATE;
					testInterface.snoopyArbiterInterface.grant     = 1;

					wait (testInterface.accessEnable                       == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);

					testInterface.cpuSlaveInterface.readEnabled = 0;

					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					wait (testInterface.cacheInterface.snoopyWriteState   == 1);
					wait (testInterface.invalidateEnable                  == 1);

					testInterface.commandInterface.snoopyCommandIn = NONE;
					testInterface.snoopyArbiterInterface.grant     = 1;

					testInterface.cacheInterface.cpuHit        = 1'bz;
					testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BUS_READ_NO_INVALIDATE: begin
					testInterface.cacheInterface.cpuHit                = 1;
					testInterface.protocolInterface.invalidateRequired = 0;
					testInterface.cpuSlaveInterface.writeEnabled       = 1;

					@(posedge testInterface.clock);

					testInterface.cacheInterface.snoopyHit         = 1;
					testInterface.commandInterface.snoopyCommandIn = BUS_READ;
					testInterface.snoopySlaveInterface.readEnabled = 1;
					testInterface.snoopyArbiterInterface.grant     = 1;
					testInterface.protocolInterface.snoopyStateIn  = VALID;
					testInterface.cacheInterface.snoopyStateOut    = DIRTY;

					wait (testInterface.cacheInterface.cpuWriteData        == 1);
					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.accessEnable                       == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);

					testInterface.cpuSlaveInterface.writeEnabled = 0;

					wait (testInterface.cacheInterface.snoopyWriteState       == 1);
					wait (testInterface.snoopySlaveInterface.functionComplete == 1);

					testInterface.commandInterface.snoopyCommandIn = NONE;
					testInterface.snoopySlaveInterface.readEnabled = 0;
					testInterface.snoopyArbiterInterface.grant     = 0;
					testInterface.protocolInterface.snoopyStateIn  = INVALID;
					testInterface.cacheInterface.snoopyStateOut    = INVALID;
					
					testInterface.cacheInterface.cpuHit        = 1'bz;
					testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BUS_READ_INVALIDATE: begin
					testInterface.cacheInterface.cpuHit                = 1;
					testInterface.protocolInterface.invalidateRequired = 1;
					testInterface.cpuSlaveInterface.writeEnabled       = 1;

					@(posedge testInterface.clock);

					testInterface.cacheInterface.snoopyHit         = 1;
					testInterface.commandInterface.snoopyCommandIn = BUS_READ;
					testInterface.snoopySlaveInterface.readEnabled = 1;
					testInterface.snoopyArbiterInterface.grant     = 1;
					testInterface.protocolInterface.snoopyStateIn  = VALID;
					testInterface.cacheInterface.snoopyStateOut    = DIRTY;

					wait (testInterface.cacheInterface.snoopyWriteState       == 1);
					wait (testInterface.snoopySlaveInterface.functionComplete == 1);

					testInterface.cacheInterface.snoopyHit         = 0;
					testInterface.commandInterface.snoopyCommandIn = NONE;
					testInterface.snoopySlaveInterface.readEnabled = 0;
					testInterface.snoopyArbiterInterface.grant     = 0;
					testInterface.protocolInterface.snoopyStateIn  = INVALID;
					testInterface.cacheInterface.snoopyStateOut    = INVALID;

					testInterface.cpuArbiterInterface.grant = 1;
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						testInterface.commandInterface.cpuCommandIn = BUS_INVALIDATE;
						testInterface.commandInterface.cacheNumberIn = i;

						repeat (2) begin
							@(posedge testInterface.clock);
						end
					end
					testInterface.cpuArbiterInterface.grant = 0;

					testInterface.commandInterface.cpuCommandIn        = NONE;
					testInterface.commandInterface.cacheNumberIn       = 0;
					testInterface.protocolInterface.invalidateRequired = 0;

					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.cacheInterface.cpuWriteData        == 1);
					wait (testInterface.accessEnable                       == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);

					testInterface.cpuSlaveInterface.writeEnabled = 0;

					testInterface.cacheInterface.cpuHit        = 1'bz;
					testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BUS_INVALIDATE: begin
					testInterface.cacheInterface.cpuHit                = 1;
					testInterface.protocolInterface.invalidateRequired = 1;
					testInterface.cpuSlaveInterface.writeEnabled       = 1;

					@(posedge testInterface.clock);

					testInterface.cacheInterface.snoopyHit         = 1;
					testInterface.commandInterface.snoopyCommandIn = BUS_INVALIDATE;
					testInterface.snoopyArbiterInterface.grant     = 1;

					wait (testInterface.cacheInterface.snoopyWriteState   == 1);
					wait (testInterface.invalidateEnable                  == 1);
					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					wait (testInterface.commandInterface.cacheNumberOut   == CACHE_ID);

					testInterface.cacheInterface.snoopyHit         = 0;
					testInterface.cacheInterface.cpuHit		         = 0;
					testInterface.commandInterface.snoopyCommandIn = NONE;
					testInterface.snoopyArbiterInterface.grant     = 0;
					
					testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.readEnabled == 1);

						testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cacheInterface.cpuWriteData    == 1);
						wait (testInterface.cpuMasterInterface.readEnabled == 0);

						testInterface.cpuMasterInterface.functionComplete = 0;
					end
					testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					wait (testInterface.cacheInterface.cpuWriteTag   == 1);

					testInterface.cacheInterface.cpuHit     = 1;
					testInterface.cpuArbiterInterface.grant = 1;
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						testInterface.commandInterface.cpuCommandIn = BUS_INVALIDATE;
						testInterface.commandInterface.cacheNumberIn = i;

						repeat (2) begin
							@(posedge testInterface.clock);
						end
					end
					testInterface.cpuArbiterInterface.grant = 0;

					testInterface.protocolInterface.invalidateRequired = 0;
					testInterface.commandInterface.cpuCommandIn        = NONE;
					testInterface.commandInterface.cacheNumberIn       = 0;

					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.cacheInterface.cpuWriteData        == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);
					wait (testInterface.accessEnable                       == 1);
					
					testInterface.cpuSlaveInterface.writeEnabled = 0;

					testInterface.cacheInterface.cpuHit        = 1'bz;
					testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BACK_BUS_READ: begin
					testInterface.cacheInterface.cpuHit               = 0;
					testInterface.protocolInterface.writeBackRequired = 1;
					testInterface.cpuSlaveInterface.readEnabled       = 1;

					@(posedge testInterface.clock);

					testInterface.cacheInterface.snoopyHit         = 1;
					testInterface.commandInterface.snoopyCommandIn = BUS_READ;
					testInterface.snoopySlaveInterface.readEnabled = 1;
					testInterface.snoopyArbiterInterface.grant     = 1;
					testInterface.cacheInterface.snoopyStateOut    = DIRTY;
					testInterface.protocolInterface.snoopyStateIn  = VALID;

					wait (testInterface.cacheInterface.snoopyWriteState       == 1);
					wait (testInterface.snoopySlaveInterface.functionComplete == 1);

					testInterface.cacheInterface.snoopyHit         = 0;
					testInterface.commandInterface.snoopyCommandIn = NONE;
					testInterface.snoopySlaveInterface.readEnabled = 0;
					testInterface.snoopyArbiterInterface.grant     = 0;
					testInterface.cacheInterface.snoopyStateOut    = INVALID;
					testInterface.protocolInterface.snoopyStateIn  = INVALID;
					
					testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.writeEnabled == 1);

						testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cpuMasterInterface.writeEnabled == 0);

						testInterface.cpuMasterInterface.functionComplete = 0;
					end
					testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					testInterface.protocolInterface.writeBackRequired = 0;

					testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.readEnabled == 1);

						testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cpuMasterInterface.readEnabled == 0);

						testInterface.cpuMasterInterface.functionComplete = 0;
					end
					testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					wait (testInterface.cacheInterface.cpuWriteTag   == 1);

					testInterface.cacheInterface.cpuHit = 1;

					wait (testInterface.cpuSlaveInterface.functionComplete == 1);
					wait (testInterface.accessEnable                       == 1);
					
					testInterface.cpuSlaveInterface.readEnabled = 0;

					testInterface.cacheInterface.cpuHit        = 1'bz;
					testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BACK_BUS_INVALIDATE: begin
					testInterface.cacheInterface.cpuHit               = 0;
					testInterface.protocolInterface.writeBackRequired = 1;
					testInterface.cpuSlaveInterface.readEnabled       = 1;

					testInterface.cacheInterface.cpuTagOut = testInterface.cpuSlaveInterface.address[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];

					@(posedge testInterface.clock);

					testInterface.cacheInterface.snoopyHit         = 1;
					testInterface.commandInterface.snoopyCommandIn = BUS_INVALIDATE;
					testInterface.snoopyArbiterInterface.grant     = 1;

					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					wait (testInterface.commandInterface.cacheNumberOut   == CACHE_ID);
					wait (testInterface.cacheInterface.snoopyWriteState   == 1);
					wait (testInterface.invalidateEnable                  == 1);

					testInterface.cacheInterface.snoopyHit         = 0;
					testInterface.commandInterface.snoopyCommandIn = NONE;
					testInterface.snoopyArbiterInterface.grant     = 0;
					
					testInterface.protocolInterface.writeBackRequired = 0;

					testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.readEnabled == 1);

						testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cpuMasterInterface.readEnabled == 0);

						testInterface.cpuMasterInterface.functionComplete = 0;
					end
					testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					wait (testInterface.cacheInterface.cpuWriteTag   == 1);

					testInterface.cacheInterface.cpuHit = 1;

					wait (testInterface.cpuSlaveInterface.functionComplete == 1);
					wait (testInterface.accessEnable                       == 1);
					
					testInterface.cpuSlaveInterface.readEnabled = 0;

					testInterface.cacheInterface.cpuHit        = 1'bz;
					testInterface.cacheInterface.snoopyHit     = 1'bz;
				end
			endcase

			testInterface.cpuSlaveInterface.address    = {ADDRESS_WIDTH{1'bz}};
			testInterface.snoopySlaveInterface.address = {ADDRESS_WIDTH{1'bz}};
			@(posedge testInterface.clock);
		endtask : drive
	endclass : ConcurrencyDriver

	class ConcurrencyCollectedItem extends BasicCollectedItem;
		ConcurrencyCase concurrencyCase;

		`uvm_object_utils_begin(ConcurrencyCollectedItem)
			`uvm_field_enum(ConcurrencyCase, concurrencyCase, UVM_ALL_ON)
		`uvm_object_utils_end
	endclass : ConcurrencyCollectedItem

	class ConcurrencyMonitor extends BasicMonitor;
		`uvm_component_utils(ConcurrencyMonitor)

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)
		) testInterface;

		function new(string name = "ConcurrencyMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
				.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.INVALID_STATE(INVALID_STATE)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
			repeat (2) begin
				@(posedge testInterface.clock);
			end
		endtask : resetDUT

		virtual task collect();
			ConcurrencyCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);
			//testInterface.cpuSlaveInterface.address    = sequenceItem.address;
			//testInterface.snoopySlaveInterface.address = sequenceItem.address;

			//testInterface.concurrencyCase = sequenceItem.concurrencyCase;
			@(posedge testInterface.clock);

			collectedItem.concurrencyCase = testInterface.concurrencyCase;
			case (collectedItem.concurrencyCase)
				READ_BUS_INVALIDATE: begin
					//testInterface.cacheInterface.cpuHit         = 1;
					//testInterface.cpuSlaveInterface.readEnabled = 1;

					@(posedge testInterface.clock);

					//testInterface.cacheInterface.snoopyHit         = 1;
					//testInterface.commandInterface.snoopyCommandIn = BUS_INVALIDATE;
					//testInterface.snoopyArbiterInterface.grant     = 1;

					wait (testInterface.accessEnable                       == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);

					//testInterface.cpuSlaveInterface.readEnabled = 0;

					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					wait (testInterface.cacheInterface.snoopyWriteState   == 1);
					wait (testInterface.invalidateEnable                  == 1);

					//testInterface.commandInterface.snoopyCommandIn = NONE;
					//testInterface.snoopyArbiterInterface.grant     = 1;

					//testInterface.cacheInterface.cpuHit        = 1'bz;
					//testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BUS_READ_NO_INVALIDATE: begin
					//testInterface.cacheInterface.cpuHit                = 1;
					//testInterface.protocolInterface.invalidateRequired = 0;
					//testInterface.cpuSlaveInterface.writeEnabled       = 1;

					@(posedge testInterface.clock);

					//testInterface.cacheInterface.snoopyHit         = 1;
					//testInterface.commandInterface.snoopyCommandIn = BUS_READ;
					//testInterface.snoopySlaveInterface.readEnabled = 1;
					//testInterface.snoopyArbiterInterface.grant     = 1;
					//testInterface.protocolInterface.snoopyStateIn  = VALID;
					//testInterface.cacheInterface.snoopyStateOut    = DIRTY;

					wait (testInterface.cacheInterface.cpuWriteData        == 1);
					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.accessEnable                       == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);

					//testInterface.cpuSlaveInterface.writeEnabled = 0;

					wait (testInterface.cacheInterface.snoopyWriteState       == 1);
					wait (testInterface.snoopySlaveInterface.functionComplete == 1);

					//testInterface.commandInterface.snoopyCommandIn = NONE;
					//testInterface.snoopySlaveInterface.readEnabled = 0;
					//testInterface.snoopyArbiterInterface.grant     = 0;
					//testInterface.protocolInterface.snoopyStateIn  = INVALID;
					//testInterface.cacheInterface.snoopyStateOut    = INVALID;
					
					//testInterface.cacheInterface.cpuHit        = 1'bz;
					//testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BUS_READ_INVALIDATE: begin
					//testInterface.cacheInterface.cpuHit                = 1;
					//testInterface.protocolInterface.invalidateRequired = 1;
					//testInterface.cpuSlaveInterface.writeEnabled       = 1;

					@(posedge testInterface.clock);

					//testInterface.cacheInterface.snoopyHit         = 1;
					//testInterface.commandInterface.snoopyCommandIn = BUS_READ;
					//testInterface.snoopySlaveInterface.readEnabled = 1;
					//testInterface.snoopyArbiterInterface.grant     = 1;
					//testInterface.protocolInterface.snoopyStateIn  = VALID;
					//testInterface.cacheInterface.snoopyStateOut    = DIRTY;

					wait (testInterface.cacheInterface.snoopyWriteState       == 1);
					wait (testInterface.snoopySlaveInterface.functionComplete == 1);

					//testInterface.cacheInterface.snoopyHit         = 0;
					//testInterface.commandInterface.snoopyCommandIn = NONE;
					//testInterface.snoopySlaveInterface.readEnabled = 0;
					//testInterface.snoopyArbiterInterface.grant     = 0;
					//testInterface.protocolInterface.snoopyStateIn  = INVALID;
					//testInterface.cacheInterface.snoopyStateOut    = INVALID;

					//testInterface.cpuArbiterInterface.grant = 1;
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						//testInterface.commandInterface.cpuCommandIn = BUS_INVALIDATE;
						//testInterface.commandInterface.cacheNumberIn = i;

						repeat (2) begin
							@(posedge testInterface.clock);
						end
					end
					//testInterface.cpuArbiterInterface.grant = 0;

					//testInterface.commandInterface.cpuCommandIn  = NONE;
					//testInterface.commandInterface.cacheNumberIn = 0;
					//testInterface.protocolInterface.invalidateRequired = 0;

					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.cacheInterface.cpuWriteData        == 1);
					wait (testInterface.accessEnable                       == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);

					//testInterface.cpuSlaveInterface.writeEnabled = 0;

					//testInterface.cacheInterface.cpuHit        = 1'bz;
					//testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BUS_INVALIDATE: begin
					//testInterface.cacheInterface.cpuHit                = 1;
					//testInterface.protocolInterface.invalidateRequired = 1;
					//testInterface.cpuSlaveInterface.writeEnabled       = 1;

					@(posedge testInterface.clock);

					//testInterface.cacheInterface.snoopyHit         = 1;
					//testInterface.commandInterface.snoopyCommandIn = BUS_INVALIDATE;
					//testInterface.snoopyArbiterInterface.grant     = 1;

					wait (testInterface.cacheInterface.snoopyWriteState   == 1);
					wait (testInterface.invalidateEnable                  == 1);
					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					wait (testInterface.commandInterface.cacheNumberOut   == CACHE_ID);

					//testInterface.cacheInterface.snoopyHit         = 0;
					//testInterface.cacheInterface.cpuHit            = 0;
					//testInterface.commandInterface.snoopyCommandIn = NONE;
					//testInterface.snoopyArbiterInterface.grant     = 0;
					
					//testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.readEnabled == 1);

						//testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cacheInterface.cpuWriteData    == 1);
						wait (testInterface.cpuMasterInterface.readEnabled == 0);

						//testInterface.cpuMasterInterface.functionComplete = 0;
					end
					//testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					wait (testInterface.cacheInterface.cpuWriteTag   == 1);

					//testInterface.cpuArbiterInterface.grant  = 1;
					//testInterface.cpuArbiterInterface.cpuHit = 1;
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						//testInterface.commandInterface.cpuCommandIn = BUS_INVALIDATE;
						//testInterface.commandInterface.cacheNumberIn = i;

						repeat (2) begin
							@(posedge testInterface.clock);
						end
					end
					//testInterface.cpuArbiterInterface.grant = 0;

					//testInterface.protocolInterface.invalidateRequired = 0;
					//testInterface.commandInterface.cpuCommandIn        = NONE;
					//testInterface.commandInterface.cacheNumberIn       = 0;

					wait (testInterface.cacheInterface.cpuWriteState       == 1);
					wait (testInterface.cacheInterface.cpuWriteData        == 1);
					wait (testInterface.cpuSlaveInterface.functionComplete == 1);
					wait (testInterface.accessEnable                       == 1);
					
					//testInterface.cpuSlaveInterface.writeEnabled = 0;

					//testInterface.cacheInterface.cpuHit        = 1'bz;
					//testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BACK_BUS_READ: begin
					//testInterface.cacheInterface.cpuHit               = 0;
					//testInterface.protocolInterface.writeBackRequired = 1;
					//testInterface.cpuSlaveInterface.readEnabled       = 1;

					@(posedge testInterface.clock);

					//testInterface.cacheInterface.snoopyHit         = 1;
					//testInterface.commandInterface.snoopyCommandIn = BUS_READ;
					//testInterface.snoopySlaveInterface.readEnabled = 1;
					//testInterface.snoopyArbiterInterface.grant     = 1;
					//testInterface.cacheInterface.snoopyStateOut    = DIRTY;
					//testInterface.protocolInterface.snoopyStateIn  = VALID;

					wait (testInterface.cacheInterface.snoopyWriteState       == 1);
					wait (testInterface.snoopySlaveInterface.functionComplete == 1);

					//testInterface.cacheInterface.snoopyHit         = 0;
					//testInterface.commandInterface.snoopyCommandIn = NONE;
					//testInterface.snoopySlaveInterface.readEnabled = 0;
					//testInterface.snoopyArbiterInterface.grant     = 0;
					//testInterface.cacheInterface.snoopyStateOut    = INVALID;
					//testInterface.protocolInterface.snoopyStateIn  = INVALID;
					
					//testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.writeEnabled == 1);

						//testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cpuMasterInterface.writeEnabled == 0);

						//testInterface.cpuMasterInterface.functionComplete = 0;
					end
					//testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					//testInterface.protocolInterface.writeBackRequired = 0;

					//testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.readEnabled == 1);

						//testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cpuMasterInterface.readEnabled == 0);

						//testInterface.cpuMasterInterface.functionComplete = 0;
					end
					//testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					wait (testInterface.cacheInterface.cpuWriteTag   == 1);

					//testInterface.cacheInterface.cpuHit = 1;

					wait (testInterface.cpuSlaveInterface.functionComplete == 1);
					wait (testInterface.accessEnable                       == 1);
					
					//testInterface.cpuSlaveInterface.readEnabled = 0;

					//testInterface.cacheInterface.cpuHit        = 1'bz;
					//testInterface.cacheInterface.snoopyHit     = 1'bz;
				end

				WRITE_BACK_BUS_INVALIDATE: begin
					//testInterface.cacheInterface.cpuHit               = 0;
					//testInterface.protocolInterface.writeBackRequired = 1;
					//testInterface.cpuSlaveInterface.readEnabled       = 1;

					//testInterface.cacheInterface.cpuTagOut = testInterface.cpuSlaveInterface.address[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];

					@(posedge testInterface.clock);

					//testInterface.cacheInterface.snoopyHit         = 1;
					//testInterface.commandInterface.snoopyCommandIn = BUS_INVALIDATE;
					//testInterface.snoopyArbiterInterface.grant     = 1;

					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					wait (testInterface.commandInterface.cacheNumberOut   == CACHE_ID);
					wait (testInterface.cacheInterface.snoopyWriteState   == 1);
					wait (testInterface.invalidateEnable                  == 1);

					//testInterface.cacheInterface.snoopyHit         = 0;
					//testInterface.commandInterface.snoopyCommandIn = NONE;
					//testInterface.snoopyArbiterInterface.grant     = 0;
					
					//testInterface.protocolInterface.writeBackRequired = 0;

					//testInterface.cpuArbiterInterface.grant = 1;
					for (int  i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.cpuMasterInterface.readEnabled == 1);

						//testInterface.cpuMasterInterface.functionComplete = 1;

						wait (testInterface.cpuMasterInterface.readEnabled == 0);

						//testInterface.cpuMasterInterface.functionComplete = 0;
					end
					//testInterface.cpuArbiterInterface.grant = 0;

					wait (testInterface.cacheInterface.cpuWriteState == 1);
					wait (testInterface.cacheInterface.cpuWriteTag   == 1);

					//testInterface.cacheInterface.cpuHit = 1;

					wait (testInterface.cpuSlaveInterface.functionComplete == 1);
					wait (testInterface.accessEnable                       == 1);
					
					//testInterface.cpuSlaveInterface.readEnabled = 0;

					//testInterface.cacheInterface.cpuHit        = 1'bz;
					//testInterface.cacheInterface.snoopyHit     = 1'bz;
				end
			endcase

			//testInterface.cpuSlaveInterface.address    = {ADDRESS_WIDTH{1'bz}};
			//testInterface.snoopySlaveInterface.address = {ADDRESS_WIDTH{1'bz}};
			@(posedge testInterface.clock);
		endtask : collect
	endclass : ConcurrencyMonitor

	class ConcurrencyScoreboard extends BasicScoreboard;
		`uvm_component_utils(ConcurrencyScoreboard)

		function new(string name = "ConcurrencyScoreaboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void checkBehaviour();
			ConcurrencyCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);

			`uvm_info(collectedItem.concurrencyCase.name(), "TEST OK", UVM_LOW)
		endfunction : checkBehaviour 
	endclass : ConcurrencyScoreboard

	class ConcurrencyTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		`uvm_component_utils(ConcurrencyTest)

		function new(string name = "ConcurrencyTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(ConcurrencySequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(ConcurrencyDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(ConcurrencyCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(ConcurrencyMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(ConcurrencyScoreboard::get_type(), 1);
		endfunction : registerReplacements
	endclass : ConcurrencyTest
endpackage : testPackage 
