package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import commands::*;

	typedef enum logic[1 : 0] {
		INVALID,
		VALID,
		DIRTY
	} CacheLineState;

	localparam ADDRESS_WIDTH            = 16;
	localparam DATA_WIDTH               = 16;
	localparam TAG_WIDTH                = 8;
	localparam INDEX_WIDTH              = 4;
	localparam OFFSET_WIDTH             = 4;
	localparam SET_ASSOCIATIVITY        = 2;
	localparam NUMBER_OF_CACHES         = 4;
	localparam CACHE_NUMBER_WIDTH       = $clog2(NUMBER_OF_CACHES);
	localparam CACHE_ID								  = 5;
	localparam type STATE_TYPE          = CacheLineState;
	localparam STATE_TYPE INVALID_STATE = INVALID;
	localparam SEQUENCE_ITEM_COUNT      = 1000;
	localparam TEST_INTERFACE           = "TestInterface";

	localparam NUMBER_OF_WORDS_PER_LINE                           = 1 << OFFSET_WIDTH;
	localparam CACHE_STATE_SET_LENGTH                             = 2;
	localparam STATE_TYPE CACHE_STATE_SET[CACHE_STATE_SET_LENGTH] = {VALID, DIRTY};
	localparam BUS_COMMAND_SET_LENGTH                             = 2;
	localparam Command BUS_COMMAND_SET[BUS_COMMAND_SET_LENGTH]    = {BUS_READ, BUS_INVALIDATE};

	class SnoopyControllerSequenceItem extends BasicSequenceItem;
		bit[TAG_WIDTH - 1   : 0] tag;
		bit[INDEX_WIDTH - 1 : 0] index;
		bit[DATA_WIDTH - 1  : 0] cacheData;
		STATE_TYPE							 cacheState;
		Command							 		 busCommand;

		`uvm_object_utils_begin(SnoopyControllerSequenceItem)
			`uvm_field_int(tag, UVM_ALL_ON)
			`uvm_field_int(index, UVM_ALL_ON)
			`uvm_field_int(cacheData, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cacheState, UVM_ALL_ON)
			`uvm_field_enum(Command, busCommand, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SnoopyControllerSequenceItem");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			tag        = $urandom();
			index      = $urandom();
			cacheData  = $urandom();
			cacheState = CACHE_STATE_SET[$urandom() % CACHE_STATE_SET_LENGTH];
			busCommand = BUS_COMMAND_SET[$urandom() % BUS_COMMAND_SET_LENGTH];
		endfunction : myRandomize
	endclass : SnoopyControllerSequenceItem

	class SnoopyControllerDriver extends BasicDriver;
		`uvm_component_utils(SnoopyControllerDriver)

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

		function new(string name = "SnoopyControllerDriver", uvm_component parent);
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
			SnoopyControllerSequenceItem sequenceItem;
			$cast(sequenceItem, req);

			testInterface.snoopySlaveInterface.address     = {sequenceItem.tag, sequenceItem.index, {OFFSET_WIDTH{1'b0}}};
			testInterface.commandInterface.snoopyCommandIn = sequenceItem.busCommand;
			@(posedge testInterface.clock);

			//if not hit write data to cache
			if (testInterface.cacheInterface.snoopyHit == 0 && testInterface.commandInterface.snoopyCommandIn == BUS_READ) begin
				testInterface.cacheInterface.cpuTagIn   = sequenceItem.tag;
				testInterface.cacheInterface.cpuIndex   = sequenceItem.index;
				testInterface.cacheInterface.cpuStateIn = sequenceItem.cacheState;

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					testInterface.cacheInterface.cpuOffset    = i;
					testInterface.cacheInterface.cpuDataIn    = sequenceItem.cacheData;
					testInterface.cacheInterface.cpuWriteData = 1;
					sequenceItem.cacheData++;

					repeat (2) begin
						@(posedge testInterface.clock);
					end

					testInterface.cacheInterface.cpuOffset    = {OFFSET_WIDTH{1'bz}};
					testInterface.cacheInterface.cpuDataIn    = {DATA_WIDTH{1'bz}};
					testInterface.cacheInterface.cpuWriteData = 1'bz;
				end

				testInterface.cacheInterface.cpuWriteState = 1;
				testInterface.cacheInterface.cpuWriteTag   = 1;
				testInterface.accessEnable                 = 1;

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				testInterface.cacheInterface.cpuWriteState = 1'bz;
				testInterface.cacheInterface.cpuWriteTag   = 1'bz;
				testInterface.accessEnable                 = 1'bz;
				testInterface.cacheInterface.cpuWriteData  = 1'bz;
				testInterface.cacheInterface.cpuTagIn      = {TAG_WIDTH{1'bz}};
				testInterface.cacheInterface.cpuIndex      = {INDEX_WIDTH{1'bz}};
			end

			@(posedge testInterface.clock);

			case (sequenceItem.busCommand) 
				BUS_READ: begin
					wait (testInterface.snoopyArbiterInterface.request == 1);
					testInterface.snoopyArbiterInterface.grant = 1;	

					for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						testInterface.snoopySlaveInterface.readEnabled = 1;
						wait (testInterface.snoopySlaveInterface.functionComplete == 1);
						testInterface.snoopySlaveInterface.readEnabled = 0;
						wait (testInterface.snoopySlaveInterface.functionComplete == 0);
						testInterface.snoopySlaveInterface.address++;
					end

					testInterface.snoopyArbiterInterface.grant = 0;
					testInterface.commandInterface.snoopyCommandIn = NONE;
				end

				BUS_INVALIDATE: begin

					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					testInterface.snoopyArbiterInterface.grant = 1;
					wait (testInterface.snoopyArbiterInterface.request == 0);
					testInterface.snoopyArbiterInterface.grant = 0;
					
					testInterface.commandInterface.snoopyCommandIn = NONE;
				end
			endcase

			testInterface.snoopySlaveInterface.address = {ADDRESS_WIDTH{1'bz}};
			@(posedge testInterface.clock);
		endtask : drive
	endclass : SnoopyControllerDriver

	class SnoopyControllerCollectedItem extends BasicCollectedItem;
		bit[DATA_WIDTH - 1 : 0] readData[NUMBER_OF_WORDS_PER_LINE], cachedData[NUMBER_OF_WORDS_PER_LINE];
		Command              		busCommand, protocolCommand;
		STATE_TYPE              snoopyStateOut, snoopyStateIn, protocolStateOut, protocolStateIn;
		int											cacheNumber;
		bit 										invalidateEnable;

		`uvm_object_utils_begin(SnoopyControllerCollectedItem)
			`uvm_field_sarray_int(readData, UVM_ALL_ON)
			`uvm_field_sarray_int(cachedData, UVM_ALL_ON)
			`uvm_field_enum(Command, busCommand, UVM_ALL_ON)
			`uvm_field_enum(Command, protocolCommand, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateIn, UVM_ALL_ON)
			`uvm_field_int(cacheNumber, UVM_ALL_ON)
		`uvm_object_utils_end
	endclass : SnoopyControllerCollectedItem

	class SnoopyControllerMonitor extends BasicMonitor;
		`uvm_component_utils(SnoopyControllerMonitor)

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

		function new(string name = "SnoopyControllerMonitor", uvm_component parent);
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
			SnoopyControllerCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);
			
			//testInterface.snoopySlaveInterface.address = {sequenceItem.tag, sequenceItem.index, {OFFSET_WIDTH{1'b0}}};

			@(posedge testInterface.clock);

			//if not hit write data to cache
			if (testInterface.cacheInterface.snoopyHit == 0 && testInterface.commandInterface.snoopyCommandIn == BUS_READ) begin
				//testInterface.cacheInterface.cpuTagIn    = sequenceItem.tag;
				//testInterface.cacheInterface.cpuIndex    = sequenceItem.index;
				//testInterface.cacheInterface.cpusStateIn = sequenceItem.cacheState;

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					//testInterface.cacheInterface.cpuOffset    = i;
					//testInterface.cacheInterface.cpuDataIn    = sequenceItem.cacheData;
					//testInterface.cacheInterface.cpuWritedata = 1;
					//sequenceItem.cacheData++;

					repeat (2) begin
						@(posedge testInterface.clock);
					end

					//testInterface.cacheInterface.cpuOffset    = {OFFSET_WIDTH{1'bz}};
					//testInterface.cacheInterface.cpuDataIn    = {DATA_WIDTH{1'bz}};
					//testInterface.cacheInterface.cpuWriteData = 1'bz;
				end

				//testInterface.cacheInterface.cpuWriteState = 1;
				//testInterface.cacheInterface.cpuWriteTag   = 1;
				//testInterface.cacheInterface.accessEnable  = 1;

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				//testInterface.cacheInterface.cpuWriteState = 1'bz;
				//testInterface.cacheInterface.cpuWriteTag   = 1'bz;
				//testInterface.cacheInterface.accessEnable  = 1'bz;
				//testInterface.cacheInterface.cpuWriteData  = 1'bz;
				//testInterface.cacheInterface.cpuTagIn      = {TAG_WIDTH{1'bz}};
				//testInterface.cacheInterface.cpuIndex      = {INDEX_WIDTH{1'bz}};
			end

			//testInterface.commandInterface.snoopyCommandIn = sequenceItem.busCommand;
			@(posedge testInterface.clock);

			collectedItem.busCommand      = testInterface.commandInterface.snoopyCommandIn;
			collectedItem.protocolCommand = testInterface.protocolInterface.snoopyCommandIn;

			collectedItem.snoopyStateOut   = testInterface.cacheInterface.snoopyStateOut;
			collectedItem.snoopyStateIn    = testInterface.cacheInterface.snoopyStateIn;
			collectedItem.protocolStateOut = testInterface.protocolInterface.snoopyStateOut;
			collectedItem.protocolStateIn  = testInterface.protocolInterface.snoopyStateIn;

			case (testInterface.commandInterface.snoopyCommandIn) 
				BUS_READ: begin
					wait (testInterface.snoopyArbiterInterface.request == 1);
					//testInterface.snoopyArbiterInterface.grant = 1;	

					for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						//testInterface.snoopySlaveInterface.readEnabled = 1;
						wait (testInterface.snoopySlaveInterface.functionComplete == 1);
						//testInterface.snoopySlaveInterface.readEnabled = 0;
						collectedItem.cachedData[testInterface.cacheInterface.snoopyOffset]                      = testInterface.cacheInterface.snoopyDataOut;
						collectedItem.readData[testInterface.snoopySlaveInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.snoopySlaveInterface.dataIn;

						wait (testInterface.snoopySlaveInterface.functionComplete == 0);
						//testInterface.snoopySlaveInterface.address++;
					end

					//testInterface.snoopyArbiterInterface.grant = 0;
					//testInterface.commandInterface.snoopyCommandIn = NONE;
				end

				BUS_INVALIDATE: begin
					wait (testInterface.commandInterface.snoopyCommandOut == BUS_INVALIDATE);
					//testInterface.snoopyArbiterInterface.grant = 1;
					collectedItem.cacheNumber = testInterface.commandInterface.cacheNumberOut;
					wait (testInterface.cacheInterface.snoopyWriteState == 1);

					collectedItem.invalidateEnable = testInterface.invalidateEnable;

					wait (testInterface.snoopyArbiterInterface.request == 0);
					//testInterface.snoopyArbiterInterface.grant = 0;

					//testInterface.commandInterface.snoopyCommandIn = NONE;
				end
			endcase

			//testInterface.snoopySlaveInterface.address = {ADDRESS_WIDTH{1'bz}};
			@(posedge testInterface.clock);
		endtask : collect
	endclass : SnoopyControllerMonitor

	class SnoopyControllerScoreboard extends BasicScoreboard;
		`uvm_component_utils(SnoopyControllerScoreboard)

		function new(string name = "SnoopyControllerScoreaboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void checkBehaviour();
			int errorCounter = 0;	
			SnoopyControllerCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);

			if (collectedItem.busCommand != collectedItem.protocolCommand) begin
				int expected = collectedItem.busCommand;
				int received = collectedItem.protocolCommand;
				`uvm_error("COMMAND_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.snoopyStateOut != collectedItem.protocolStateOut) begin
				int expected = collectedItem.snoopyStateOut;
				int received = collectedItem.protocolStateOut;
				`uvm_error("STATE_OUT_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end
			
			if (collectedItem.snoopyStateIn != collectedItem.protocolStateIn) begin
				int expected = collectedItem.snoopyStateIn;
				int received = collectedItem.protocolStateIn;
				`uvm_error("STATE_IN_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.busCommand == BUS_READ) begin
				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						if (collectedItem.readData[i] != collectedItem.cachedData[i]) begin
							int expected = collectedItem.readData[i];
							int received = collectedItem.cachedData[i];
							`uvm_error("DATA_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
							errorCounter++;
						end
				end
			end else begin
				if (collectedItem.cacheNumber != CACHE_ID) begin
					int expected = collectedItem.cacheNumber;
					int received = CACHE_ID;
					`uvm_error("CACHE_NUMBER_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.invalidateEnable != 1) begin
					int expected = collectedItem.invalidateEnable;
					int received = 1;
					`uvm_error("INVALIDATE_ENABLE_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
					errorCounter++;
				end
			end

			if (errorCounter == 0) begin
				`uvm_info(collectedItem.busCommand.name(), "TEST_OK", UVM_LOW)
			end
		endfunction : checkBehaviour 
	endclass : SnoopyControllerScoreboard

	class SnoopyControllerTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		`uvm_component_utils(SnoopyControllerTest)

		function new(string name = "SnoopyControllerTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(SnoopyControllerSequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(SnoopyControllerDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(SnoopyControllerCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(SnoopyControllerMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(SnoopyControllerScoreboard::get_type(), 1);
		endfunction : registerReplacements
	endclass : SnoopyControllerTest
endpackage : testPackage 
