package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import commands::*;
	import writeBackInvalidateStates::*;

	localparam ADDRESS_WIDTH            = 8;
	localparam DATA_WIDTH               = 8;
	localparam TAG_WIDTH                = 4;
	localparam INDEX_WIDTH              = 2;
	localparam OFFSET_WIDTH             = 2;
	localparam SET_ASSOCIATIVITY        = 1;
	localparam type STATE_TYPE          = CacheLineState;
	localparam STATE_TYPE INVALID_STATE = INVALID;
	localparam STATE_TYPE OWNED_STATE		= DIRTY;
	localparam SEQUENCE_ITEM_COUNT      = 4000;
	localparam TEST_INTERFACE           = "TestInterface";

	localparam NUMBER_OF_WORDS_PER_LINE                        = 1 << OFFSET_WIDTH;
	localparam BUS_COMMAND_SET_LENGTH                          = 3;
	localparam Command BUS_COMMAND_SET[BUS_COMMAND_SET_LENGTH] = {BUS_READ, BUS_INVALIDATE, BUS_READ_EXCLUSIVE};

	class SnoopyControllerSequenceItem extends BasicSequenceItem;
		bit[TAG_WIDTH - 1   : 0] tag;
		bit[INDEX_WIDTH - 1 : 0] index;
		bit[DATA_WIDTH - 1  : 0] data;
		bit											 supply;
		STATE_TYPE							 state;
		Command							 		 command;

		`uvm_object_utils_begin(SnoopyControllerSequenceItem)
			`uvm_field_int(tag, UVM_ALL_ON)
			`uvm_field_int(index, UVM_ALL_ON)
			`uvm_field_int(data, UVM_ALL_ON)
			`uvm_field_int(supply, UVM_ALL_ON)
			`uvm_field_enum(Command, command, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SnoopyControllerSequenceItem");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			tag     = $urandom();
			index   = $urandom();
			data    = $urandom();
			supply  = $urandom();
			command = BUS_COMMAND_SET[$urandom() % BUS_COMMAND_SET_LENGTH];
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
				.STATE_TYPE(STATE_TYPE),
				.INVALID_STATE(INVALID_STATE)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
			testInterface.slaveInterface.readEnabled  = 0;

			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;

			wait (testInterface.invalidateEnable                == 0);
			testInterface.accessEnable = 0;
			wait (testInterface.cacheInterface.writeState       == 0);
			wait (testInterface.slaveInterface.functionComplete == 0);
		endtask : resetDUT

		virtual task drive();
			SnoopyControllerSequenceItem sequenceItem;
			$cast(sequenceItem, req);

			testInterface.cpuCacheInterface.tagIn = sequenceItem.tag;
			testInterface.cpuCacheInterface.index = sequenceItem.index;
			testInterface.supply                  = sequenceItem.supply;

			@(posedge testInterface.clock);

			//if not hit and supply enabled write to cache
			if (testInterface.cpuCacheInterface.hit == 0 && testInterface.supply == 1) begin
				testInterface.cpuCacheInterface.stateIn = OWNED_STATE;

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					testInterface.cpuCacheInterface.offset    = i;
					testInterface.cpuCacheInterface.dataIn    = sequenceItem.data;
					testInterface.cpuCacheInterface.writeData = 1;
					sequenceItem.data++;

					repeat (2) begin
						@(posedge testInterface.clock);
					end

					testInterface.cpuCacheInterface.offset    = {OFFSET_WIDTH{1'bz}};
					testInterface.cpuCacheInterface.dataIn    = {DATA_WIDTH{1'bz}};
					testInterface.cpuCacheInterface.writeData = 1'bz;
				end

				testInterface.cpuCacheInterface.writeState = 1;
				testInterface.cpuCacheInterface.writeTag   = 1;
				testInterface.accessEnable                 = 1;

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				testInterface.cpuCacheInterface.writeState = 1'bz;
				testInterface.cpuCacheInterface.writeTag   = 1'bz;
				testInterface.accessEnable                 = 1'bz;
				testInterface.cpuCacheInterface.writeData  = 1'bz;
			
				@(posedge testInterface.clock);
			end else if (testInterface.cpuCacheInterface.hit == 1 && testInterface.cpuCacheInterface.stateOut != OWNED_STATE && testInterface.supply == 1) begin
				testInterface.cpuCacheInterface.stateIn    = OWNED_STATE;
				testInterface.cpuCacheInterface.writeState = 1;

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				testInterface.cpuCacheInterface.writeState = 1'bz;
				testInterface.cpuCacheInterface.stateIn    = INVALID_STATE;
				@(posedge testInterface.clock);
			end

			testInterface.cpuCacheInterface.tagIn      = {TAG_WIDTH{1'bz}};
			testInterface.cpuCacheInterface.index      = {INDEX_WIDTH{1'bz}};

			testInterface.slaveInterface.address     = {sequenceItem.tag, sequenceItem.index, {OFFSET_WIDTH{1'b0}}};
			testInterface.commandInterface.commandIn = sequenceItem.command;
			testInterface.arbiterInterface.grant     = sequenceItem.supply;

			@(posedge testInterface.clock);

			case (sequenceItem.command) 
				BUS_READ: begin
					if (testInterface.cacheInterface.hit == 1) begin
						if (testInterface.arbiterInterface.request == 1) begin
							for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
								wait (testInterface.slaveInterface.functionComplete == 0);
								testInterface.slaveInterface.readEnabled = 1;
								wait (testInterface.slaveInterface.functionComplete == 1);
								testInterface.slaveInterface.readEnabled = 0;
								testInterface.slaveInterface.address++;
							end

							testInterface.slaveInterface.address -= NUMBER_OF_WORDS_PER_LINE;
						end

						if (testInterface.cacheInterface.stateOut != testInterface.protocolInterface.stateIn) begin
							wait (testInterface.cacheInterface.writeState == 1);
							wait (testInterface.cacheInterface.writeState == 0);
						end
						
						testInterface.arbiterInterface.grant = 0;
					end
				end

				BUS_INVALIDATE: begin
					if (testInterface.commandInterface.isInvalidated == 0) begin
						wait (testInterface.cacheInterface.writeState == 1);
						wait (testInterface.invalidateEnable          == 1);
						wait (testInterface.cacheInterface.writeState == 0);
						wait (testInterface.invalidateEnable          == 0);
					end
					wait (testInterface.commandInterface.isInvalidated == 1);
				end

				BUS_READ_EXCLUSIVE: begin
					if (testInterface.cacheInterface.hit == 1) begin
						if (testInterface.arbiterInterface.request == 1) begin
							for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
								wait (testInterface.slaveInterface.functionComplete == 0);
								testInterface.slaveInterface.readEnabled = 1;
								wait (testInterface.slaveInterface.functionComplete == 1);
								testInterface.slaveInterface.readEnabled = 0;
								testInterface.slaveInterface.address++;
							end

							testInterface.slaveInterface.address -= NUMBER_OF_WORDS_PER_LINE;
						end

						wait (testInterface.cacheInterface.writeState == 1);
						wait (testInterface.invalidateEnable          == 1);
						wait (testInterface.cacheInterface.writeState == 0);
						wait (testInterface.invalidateEnable          == 0);
						
						testInterface.arbiterInterface.grant = 0;
					end
				end
			endcase

			@(posedge testInterface.clock);
			testInterface.slaveInterface.address     = {ADDRESS_WIDTH{1'bz}};
			testInterface.commandInterface.commandIn = NONE;
		endtask : drive
	endclass : SnoopyControllerDriver

	class SnoopyControllerCollectedItem extends BasicCollectedItem;
		bit[DATA_WIDTH - 1 : 0] slaveDataIns[NUMBER_OF_WORDS_PER_LINE], cacheDataOuts[NUMBER_OF_WORDS_PER_LINE];
		Command              		commandIn, protocolCommandIn;
		STATE_TYPE              snoopyStateOut, snoopyStateIn, protocolStateOut, protocolStateIn;

		`uvm_object_utils_begin(SnoopyControllerCollectedItem)
			`uvm_field_sarray_int(slaveDataIns, UVM_ALL_ON)
			`uvm_field_sarray_int(cacheDataOuts, UVM_ALL_ON)
			`uvm_field_enum(Command, commandIn, UVM_ALL_ON)
			`uvm_field_enum(Command, protocolCommandIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateIn, UVM_ALL_ON)
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
				.STATE_TYPE(STATE_TYPE),
				.INVALID_STATE(INVALID_STATE)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
			//testInterface.slaveInterface.readEnabled  = 0;

			//testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			//testInterface.reset = 0;

			wait (testInterface.invalidateEnable                == 0);
			//testInterface.accessEnable = 0;
			wait (testInterface.cacheInterface.writeState       == 0);
			wait (testInterface.slaveInterface.functionComplete == 0);
		endtask : resetDUT

		virtual task collect();
			SnoopyControllerCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);
			
			//testInterface.cpuCacheInterface.tagIn = sequenceItem.tag;
			//testInterface.cpuCacheInterface.index = sequenceItem.index;
			//testInterface.supply                  = sequenceItem.supply;

			@(posedge testInterface.clock);

			//if not hit and supply enabled write to cache
			if (testInterface.cpuCacheInterface.hit == 0 && testInterface.supply == 1) begin
				//testInterface.cpuCacheInterface.stateIn = OWNED_STATE;

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					//testInterface.cpuCacheInterface.offset    = i;
					//testInterface.cpuCacheInterface.dataIn    = sequenceItem.data;
					//testInterface.cpuCacheInterface.writeData = 1;
					//sequenceItem.data++;

					repeat (2) begin
						@(posedge testInterface.clock);
					end

					//testInterface.cpuCacheInterface.offset    = {OFFSET_WIDTH{1'bz}};
					//testInterface.cpuCacheInterface.dataIn    = {DATA_WIDTH{1'bz}};
					//testInterface.cpuCacheInterface.writeData = 1'bz;
				end

				//testInterface.cpuCacheInterface.writeState = 1;
				//testInterface.cpuCacheInterface.writeTag   = 1;
				//testInterface.accessEnable                 = 1;

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				//testInterface.cpuCacheInterface.writeState = 1'bz;
				//testInterface.cpuCacheInterface.writeTag   = 1'bz;
				//testInterface.accessEnable                 = 1'bz;
				//testInterface.cpuCacheInterface.writeData  = 1'bz;
			
				@(posedge testInterface.clock);
			end else if (testInterface.cpuCacheInterface.hit == 1 && testInterface.cpuCacheInterface.stateOut != OWNED_STATE && testInterface.supply == 1) begin
				//testInterface.cpuCacheInterface.stateIn    = OWNED_STATE;
				//testInterface.cpuCacheInterface.writeState = 1;

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				//testInterface.cpuCacheInterface.writeState = 1'bz;
				//testInterface.cpuCacheInterface.stateIn    = INVALID_STATE;
				@(posedge testInterface.clock);
			end

			//testInterface.cpuCacheInterface.tagIn      = {TAG_WIDTH{1'bz}};
			//testInterface.cpuCacheInterface.index      = {INDEX_WIDTH{1'bz}};

			//testInterface.slaveInterface.address     = {sequenceItem.tag, sequenceItem.index, {OFFSET_WIDTH{1'b0}}};
			//testInterface.commandInterface.commandIn = sequenceItem.command;

			@(posedge testInterface.clock);

			collectedItem.commandIn         = testInterface.commandInterface.commandIn;
			collectedItem.protocolCommandIn = testInterface.protocolInterface.commandIn;

			case (collectedItem.commandIn) 
				BUS_READ: begin
					if (testInterface.cacheInterface.hit == 1) begin
						if (testInterface.arbiterInterface.request == 1) begin
							for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
								wait (testInterface.slaveInterface.functionComplete == 0);
								//testInterface.slaveInterface.readEnabled = 1;
								wait (testInterface.slaveInterface.functionComplete == 1);
								//testInterface.slaveInterface.readEnabled = 0;

								collectedItem.slaveDataIns[testInterface.slaveInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.slaveInterface.dataIn;
								collectedItem.cacheDataOuts[testInterface.cacheInterface.offset]                       = testInterface.cacheInterface.dataOut;

								//testInterface.slaveInterface.address++;
							end

							//testInterface.slaveInterface.address -= NUMBER_OF_WORDS_PER_LINE;
						end


						if (testInterface.cacheInterface.stateOut != testInterface.protocolInterface.stateIn) begin
							wait (testInterface.cacheInterface.writeState == 1);

							collectedItem.snoopyStateOut   = testInterface.cacheInterface.stateOut;
							collectedItem.snoopyStateIn    = testInterface.cacheInterface.stateIn;
							collectedItem.protocolStateOut = testInterface.protocolInterface.stateOut;
							collectedItem.protocolStateIn  = testInterface.protocolInterface.stateIn;

							wait (testInterface.cacheInterface.writeState == 0);
						end
						
						//testInterface.arbiterInterface.grant = 0;
					end
				end

				BUS_INVALIDATE: begin
					if (testInterface.commandInterface.isInvalidated == 0) begin
						wait (testInterface.cacheInterface.writeState == 1);

						collectedItem.snoopyStateOut   = testInterface.cacheInterface.stateOut;
						collectedItem.snoopyStateIn    = testInterface.cacheInterface.stateIn;
						collectedItem.protocolStateOut = testInterface.protocolInterface.stateOut;
						collectedItem.protocolStateIn  = testInterface.protocolInterface.stateIn;

						wait (testInterface.invalidateEnable          == 1);
						wait (testInterface.cacheInterface.writeState == 0);
						wait (testInterface.invalidateEnable          == 0);
					end
					wait (testInterface.commandInterface.isInvalidated == 1);
				end

				BUS_READ_EXCLUSIVE: begin
					if (testInterface.cacheInterface.hit == 1) begin
						if (testInterface.arbiterInterface.request == 1) begin
							for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
								wait (testInterface.slaveInterface.functionComplete == 0);
								//testInterface.slaveInterface.readEnabled = 1;
								wait (testInterface.slaveInterface.functionComplete == 1);
								//testInterface.slaveInterface.readEnabled = 0;

								collectedItem.slaveDataIns[testInterface.slaveInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.slaveInterface.dataIn;
								collectedItem.cacheDataOuts[testInterface.cacheInterface.offset]                       = testInterface.cacheInterface.dataOut;

								//testInterface.slaveInterface.address++;
							end

							//testInterface.slaveInterface.address -= NUMBER_OF_WORDS_PER_LINE;
						end

						wait (testInterface.cacheInterface.writeState == 1);

						collectedItem.snoopyStateOut   = testInterface.cacheInterface.stateOut;
						collectedItem.snoopyStateIn    = testInterface.cacheInterface.stateIn;
						collectedItem.protocolStateOut = testInterface.protocolInterface.stateOut;
						collectedItem.protocolStateIn  = testInterface.protocolInterface.stateIn;

						wait (testInterface.invalidateEnable          == 1);
						wait (testInterface.cacheInterface.writeState == 0);
						wait (testInterface.invalidateEnable          == 0);
						
						//testInterface.arbiterInterface.grant = 0;
					end
				end
			endcase

			@(posedge testInterface.clock);
			//testInterface.slaveInterface.address     = {ADDRESS_WIDTH{1'bz}};
			//testInterface.commandInterface.commandIn = NONE;
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

			if (collectedItem.commandIn != collectedItem.protocolCommandIn) begin
				int expected = collectedItem.commandIn;
				int received = collectedItem.protocolCommandIn;
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

			if (collectedItem.commandIn == BUS_READ || collectedItem.commandIn == BUS_READ_EXCLUSIVE) begin
				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						if (collectedItem.slaveDataIns[i] != collectedItem.cacheDataOuts[i]) begin
							int expected = collectedItem.slaveDataIns[i];
							int received = collectedItem.cacheDataOuts[i];
							`uvm_error("DATA_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
							errorCounter++;
						end
				end
			end 

			if (errorCounter == 0) begin
				`uvm_info(collectedItem.commandIn.name(), "TEST_OK", UVM_LOW)
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
