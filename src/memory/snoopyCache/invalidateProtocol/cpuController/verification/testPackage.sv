package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import commands::*;
	import MSIStates::*;

	localparam ADDRESS_WIDTH            = 16;
	localparam DATA_WIDTH               = 16;
	localparam TAG_WIDTH                = 8;
	localparam INDEX_WIDTH              = 4;
	localparam OFFSET_WIDTH             = 4;
	localparam SET_ASSOCIATIVITY        = 2;
	localparam type STATE_TYPE          = CacheLineState;
	localparam STATE_TYPE INVALID_STATE = INVALID;
	localparam SEQUENCE_ITEM_COUNT      = 1000;
	localparam TEST_INTERFACE           = "TestInterface";

	localparam NUMBER_OF_WORDS_PER_LINE = 1 << OFFSET_WIDTH;

	class CPUControllerSequenceItem extends BasicSequenceItem;
		bit[ADDRESS_WIDTH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] ramData, writeData;
		bit 											 isRead;

		`uvm_object_utils_begin(CPUControllerSequenceItem)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(ramData, UVM_ALL_ON)
			`uvm_field_int(writeData, UVM_ALL_ON)
			`uvm_field_int(isRead, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "CPUControllerSequenceItem");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			address   = $urandom();
			ramData   = $urandom();
			writeData = $urandom();
			isRead    = $urandom();
		endfunction : myRandomize
	endclass : CPUControllerSequenceItem

	class CPUControllerDriver extends BasicDriver;
		`uvm_component_utils(CPUControllerDriver)

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

		function new(string name = "CPUControllerDriver", uvm_component parent);
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
			testInterface.slaveInterface.writeEnabled = 0;

			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;

			wait (testInterface.accessEnable                    == 0);
			testInterface.invalidateEnable = 0;
			wait (testInterface.commandInterface.commandOut     == NONE);
			wait (testInterface.arbiterInterface.request        == 0);
			wait (testInterface.slaveInterface.functionComplete == 0);
		endtask : resetDUT

		virtual task drive();
			CPUControllerSequenceItem sequenceItem;
			$cast(sequenceItem, req);

			testInterface.slaveInterface.address      = sequenceItem.address;
			testInterface.slaveInterface.dataOut      = sequenceItem.writeData;
			testInterface.slaveInterface.readEnabled  = sequenceItem.isRead;
			testInterface.slaveInterface.writeEnabled = ~sequenceItem.isRead;
	
			@(posedge testInterface.clock);

			if (testInterface.cacheInterface.hit == 0) begin
				wait (testInterface.protocolInterface.stateOut       == INVALID_STATE);
				wait (testInterface.protocolInterface.writeBackState == testInterface.cacheInterface.stateOut);
				if (testInterface.protocolInterface.writeBackRequired == 1) begin
					wait (testInterface.commandInterface.commandOut == BUS_WRITEBACK);
					wait (testInterface.arbiterInterface.request    == 1);
					
					testInterface.arbiterInterface.grant = 1;

					for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						wait (testInterface.masterInterface.writeEnabled == 1);
						testInterface.masterInterface.functionComplete = 1;
						wait (testInterface.masterInterface.writeEnabled == 0);
						testInterface.masterInterface.functionComplete = 0;
					end
					wait (testInterface.cacheInterface.writeState == 1);
					wait (testInterface.cacheInterface.writeState == 0);

					testInterface.arbiterInterface.grant = 0;
					//there is not NONE command since we immediatelly move to read
					
					//wait for data to sync in
					@(posedge testInterface.clock);
				end

				//bus read
				if (testInterface.protocolInterface.readExclusiveRequired == 1) begin
					wait (testInterface.commandInterface.commandOut == BUS_READ_EXCLUSIVE);
				end else begin
					wait (testInterface.commandInterface.commandOut == BUS_READ);
				end
				wait (testInterface.arbiterInterface.request == 1);

				testInterface.arbiterInterface.grant = 1;

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					wait (testInterface.masterInterface.readEnabled == 1);
					
					testInterface.masterInterface.dataIn           = sequenceItem.ramData;
					testInterface.masterInterface.functionComplete = 1;
					sequenceItem.ramData++;

					wait (testInterface.cacheInterface.writeData    == 1);
					wait (testInterface.masterInterface.readEnabled == 0);

					testInterface.masterInterface.functionComplete = 0;
				end		

				if (testInterface.protocolInterface.readExclusiveRequired == 1) begin
					testInterface.commandInterface.isInvalidated = 1;
				end

				wait (testInterface.cacheInterface.writeTag   == 1);
				wait (testInterface.cacheInterface.writeState == 1);
				wait (testInterface.cacheInterface.writeTag   == 0);
				wait (testInterface.cacheInterface.writeState == 0);
				
				if (testInterface.protocolInterface.readExclusiveRequired == 1) begin
					testInterface.commandInterface.isInvalidated = 0;
				end

				testInterface.arbiterInterface.grant = 0;

				//wait for tag and state to sync in
				@(posedge testInterface.clock);
			end

			//invalidate if necessary
			if (testInterface.protocolInterface.invalidateRequired == 1) begin
				wait (testInterface.commandInterface.commandOut == BUS_INVALIDATE);
				wait (testInterface.arbiterInterface.request    == 1);

				testInterface.arbiterInterface.grant         = 1;
				testInterface.commandInterface.isInvalidated = 1;

				wait (testInterface.cacheInterface.writeState == 1);
				wait (testInterface.cacheInterface.writeState == 0);
				
				testInterface.arbiterInterface.grant         = 0;
				testInterface.commandInterface.isInvalidated = 0;
			end

			wait (testInterface.commandInterface.commandOut == NONE);
			wait (testInterface.arbiterInterface.request    == 0);

			wait (testInterface.slaveInterface.functionComplete == 1);
			wait (testInterface.accessEnable                    == 1);

			testInterface.slaveInterface.readEnabled  = 0;
			testInterface.slaveInterface.writeEnabled = 0;

			wait (testInterface.slaveInterface.functionComplete == 0);
			wait (testInterface.accessEnable                    == 0);
		endtask : drive
	endclass : CPUControllerDriver

	class CPUControllerCollectedItem extends BasicCollectedItem;
		//if it is hit
		bit[ADDRESS_WIDTH - 1 : 0] slaveAddress;
		bit[DATA_WIDTH - 1    : 0] slaveDataIn, cacheDataOut, slaveDataOut, cacheDataIn;
		bit[TAG_WIDTH - 1     : 0] tagIn;
		bit[INDEX_WIDTH - 1   : 0] index;
		bit[OFFSET_WIDTH - 1  : 0] offset;
		bit												 hit, isRead;

		//if read is required
		bit[ADDRESS_WIDTH - 1 : 0] masterAddress;
		bit[DATA_WIDTH - 1    : 0] masterDataIns[NUMBER_OF_WORDS_PER_LINE], cacheDataIns[NUMBER_OF_WORDS_PER_LINE];
		STATE_TYPE              	 protocolStateIn, protocolStateOut, cacheStateIn, cacheStateOut;

		//if invalidate is needed
		bit[ADDRESS_WIDTH - 1 : 0] invalidateAddress;
		bit[INDEX_WIDTH - 1   : 0] invalidateIndex;
		bit[TAG_WIDTH - 1     : 0] invalidateTag;
		bit										 		 invalidateRequired;

		//if write back is required
		bit[ADDRESS_WIDTH - 1 : 0] writeBackAddress;
		bit[TAG_WIDTH - 1     : 0] tagOut;
		bit[DATA_WIDTH - 1    : 0] masterDataOuts[NUMBER_OF_WORDS_PER_LINE], cacheDataOuts[NUMBER_OF_WORDS_PER_LINE];
		STATE_TYPE 								 writeBackState;
		bit 											 writeBackRequired;

		`uvm_object_utils_begin(CPUControllerCollectedItem)
			`uvm_field_int(slaveAddress, UVM_ALL_ON)
			`uvm_field_int(slaveDataIn, UVM_ALL_ON)
			`uvm_field_int(slaveDataOut, UVM_ALL_ON)
			`uvm_field_int(cacheDataOut, UVM_ALL_ON)
			`uvm_field_int(cacheDataIn, UVM_ALL_ON)
			`uvm_field_int(tagIn, UVM_ALL_ON)
			`uvm_field_int(index, UVM_ALL_ON)
			`uvm_field_int(hit, UVM_ALL_ON)
			`uvm_field_int(isRead, UVM_ALL_ON)

			`uvm_field_int(masterAddress, UVM_ALL_ON)
			`uvm_field_sarray_int(masterDataIns, UVM_ALL_ON)
			`uvm_field_sarray_int(cacheDataIns, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cacheStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cacheStateOut, UVM_ALL_ON)

			`uvm_field_int(invalidateAddress, UVM_ALL_ON)
			`uvm_field_int(invalidateIndex, UVM_ALL_ON)
			`uvm_field_int(invalidateTag, UVM_ALL_ON)
			`uvm_field_int(invalidateRequired, UVM_ALL_ON)

			`uvm_field_int(writeBackAddress, UVM_ALL_ON)
			`uvm_field_int(tagOut, UVM_ALL_ON)
			`uvm_field_sarray_int(masterDataOuts, UVM_ALL_ON)
			`uvm_field_sarray_int(cacheDataOuts, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, writeBackState, UVM_ALL_ON)
			`uvm_field_int(writeBackRequired, UVM_ALL_ON)
		`uvm_object_utils_end
	endclass : CPUControllerCollectedItem

	class CPUControllerMonitor extends BasicMonitor;
		`uvm_component_utils(CPUControllerMonitor)

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

		function new(string name = "CPUControllerMonitor", uvm_component parent);
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
			//testInterface.cpuSlaveInterface.readEnabled  = 0;
			//testInterface.cpuSlaveInterface.writeEnabled = 0;

			//testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			//testInterface.reset = 0;

			wait (testInterface.accessEnable                    == 0);
			//testInterface.invalidateEnable = 0;
			wait (testInterface.commandInterface.commandOut     == NONE);
			wait (testInterface.arbiterInterface.request        == 0);
			wait (testInterface.slaveInterface.functionComplete == 0);
		endtask : resetDUT

		virtual task collect();
			CPUControllerCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);
			
			//testInterface.slaveInterface.address      = sequenceItem.address;
			//testInterface.slaveInterface.dataOut      = sequenceItem.writeData;
			//testInterface.slaveInterface.readEnabled  = sequenceItem.isRead;
			//testInterface.slaveInterface.writeEnabled = ~sequenceItem.isRead;
	
			@(posedge testInterface.clock);

			collectedItem.slaveAddress = testInterface.slaveInterface.address;
			collectedItem.tagIn        = testInterface.cacheInterface.tagIn;
			collectedItem.index        = testInterface.cacheInterface.index;
			collectedItem.hit          = testInterface.cacheInterface.hit;
			collectedItem.isRead			 = testInterface.slaveInterface.readEnabled;

			if (testInterface.cacheInterface.hit == 0) begin
				collectedItem.writeBackRequired = testInterface.protocolInterface.writeBackRequired;

				wait (testInterface.protocolInterface.stateOut       == INVALID_STATE);
				wait (testInterface.protocolInterface.writeBackState == testInterface.cacheInterface.stateOut);
				if (testInterface.protocolInterface.writeBackRequired == 1) begin
					wait (testInterface.commandInterface.commandOut == BUS_WRITEBACK);
					wait (testInterface.arbiterInterface.request    == 1);
					
					//testInterface.arbiterInterface.grant = 1;

					for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						collectedItem.writeBackAddress = testInterface.masterInterface.address;
						collectedItem.tagOut           = testInterface.cacheInterface.tagOut;

						wait (testInterface.masterInterface.writeEnabled == 1);
						//testInterface.masterInterface.functionComplete = 1;

						collectedItem.masterDataOuts[testInterface.masterInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.masterInterface.dataOut;
						collectedItem.cacheDataOuts[testInterface.cacheInterface.offset]                          = testInterface.cacheInterface.dataOut;

						wait (testInterface.masterInterface.writeEnabled == 0);
						//testInterface.masterInterface.functionComplete = 0;
					end
					wait (testInterface.cacheInterface.writeState == 1);

					collectedItem.writeBackState = testInterface.cacheInterface.stateIn;

					wait (testInterface.cacheInterface.writeState == 0);

					//testInterface.arbiterInterface.grant = 0;
					//there is not NONE command since we immediatelly move to read

					//wait for data to sync in
					@(posedge testInterface.clock);
				end

				//bus read
				if (testInterface.protocolInterface.readExclusiveRequired == 1) begin
					wait (testInterface.commandInterface.commandOut == BUS_READ_EXCLUSIVE);
				end else begin
					wait (testInterface.commandInterface.commandOut == BUS_READ);
				end
				wait (testInterface.arbiterInterface.request == 1);

				//testInterface.arbiterInterface.grant = 1;

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					wait (testInterface.masterInterface.readEnabled == 1);
					
					//testInterface.masterInterface.dataIn           = sequenceItem.ramData;
					//testInterface.masterInterface.functionComplete = 1;
					//sequenceItem.ramData++;
					collectedItem.masterAddress = testInterface.masterInterface.address;

					wait (testInterface.cacheInterface.writeData == 1);

					collectedItem.masterDataIns[testInterface.masterInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.masterInterface.dataIn;
					collectedItem.cacheDataIns[testInterface.cacheInterface.offset]                          = testInterface.cacheInterface.dataIn;

					wait (testInterface.masterInterface.readEnabled == 0);

					//testInterface.masterInterface.functionComplete = 0;
				end		
				
				//if (testInterface.protocolInterface.readExclusiveRequired == 1) begin
				//	testInterface.commandInterface.isInvalidated = 1;
				//end

				wait (testInterface.cacheInterface.writeTag   == 1);
				wait (testInterface.cacheInterface.writeState == 1);
				
				collectedItem.protocolStateIn = testInterface.protocolInterface.stateIn;
				collectedItem.cacheStateIn    = testInterface.cacheInterface.stateIn;

				wait (testInterface.cacheInterface.writeTag   == 0);
				wait (testInterface.cacheInterface.writeState == 0);
				
				//if (testInterface.protocolInterface.readExclusiveRequired == 1) begin
				//	testInterface.commandInterface.isInvalidated = 0;
				//end
				//testInterface.arbiterInterface.grant = 0;

				//wait for tag and state to sync in
				@(posedge testInterface.clock);
			end
			
			//invalidate if necessary
			collectedItem.invalidateRequired = testInterface.protocolInterface.invalidateRequired;
			if (testInterface.protocolInterface.invalidateRequired == 1) begin
				wait (testInterface.commandInterface.commandOut == BUS_INVALIDATE);
				wait (testInterface.arbiterInterface.request    == 1);

				//testInterface.arbiterInterface.grant         = 1;
				//testInterface.commandInterface.isInvalidated = 1;

				collectedItem.invalidateAddress = testInterface.masterInterface.address;
				collectedItem.invalidateTag     = testInterface.cacheInterface.tagOut;
				collectedItem.invalidateIndex   = testInterface.cacheInterface.index;

				wait (testInterface.cacheInterface.writeState == 1);
				wait (testInterface.cacheInterface.writeState == 0);
				
				//testInterface.arbiterInterface.grant         = 0;
				//testInterface.commandInterface.isInvalidated = 0;
			end

			wait (testInterface.commandInterface.commandOut == NONE);
			wait (testInterface.arbiterInterface.request    == 0);

			collectedItem.cacheStateOut    = testInterface.cacheInterface.stateOut;
			collectedItem.protocolStateOut = testInterface.protocolInterface.stateOut;

			wait (testInterface.slaveInterface.functionComplete == 1);
			wait (testInterface.accessEnable                    == 1);

			//testInterface.slaveInterface.readEnabled  = 0;
			//testInterface.slaveInterface.writeEnabled = 0;

			wait (testInterface.slaveInterface.functionComplete == 0);
			wait (testInterface.accessEnable                    == 0);

			collectedItem.offset       = testInterface.cacheInterface.offset;
			collectedItem.cacheDataIn  = testInterface.cacheInterface.dataIn;
			collectedItem.cacheDataOut = testInterface.cacheInterface.dataOut;
			collectedItem.slaveDataIn  = testInterface.slaveInterface.dataIn;
			collectedItem.slaveDataOut = testInterface.slaveInterface.dataOut;

		endtask : collect
	endclass : CPUControllerMonitor

	class CPUControllerScoreboard extends BasicScoreboard;
		`uvm_component_utils(CPUControllerScoreboard)

		function new(string name = "CPUControllerScoreaboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void checkBehaviour();
			int errorCounter = 0;	
			CPUControllerCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);

			if (collectedItem.tagIn != collectedItem.slaveAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
				int expected = collectedItem.tagIn;
				int received = collectedItem.slaveAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
				`uvm_error("SLAVE_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
				errorCounter++;
			end
			
			if (collectedItem.index != collectedItem.slaveAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
				int expected = collectedItem.index;
				int received = collectedItem.slaveAddress[OFFSET_WIDTH +: INDEX_WIDTH];
				`uvm_error("SLAVE_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.offset != collectedItem.slaveAddress[OFFSET_WIDTH - 1 : 0]) begin
				int expected = collectedItem.offset;
				int received = collectedItem.slaveAddress[OFFSET_WIDTH - 1 : 0];
				`uvm_error("SLAVE_OFFSET_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
				errorCounter++;
			end


			if (collectedItem.hit == 0) begin
				if (collectedItem.writeBackRequired == 1) begin
					if (collectedItem.tagOut != collectedItem.writeBackAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
						int expected = collectedItem.tagOut;
						int received = collectedItem.writeBackAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
						`uvm_error("WRITE_BACK_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
						errorCounter++;
					end

					if (collectedItem.index != collectedItem.writeBackAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
						int expected = collectedItem.index;
						int received = collectedItem.writeBackAddress[OFFSET_WIDTH +: INDEX_WIDTH];
						`uvm_error("WRITE_BACK_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
						errorCounter++;
					end
						
					for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
						if (collectedItem.masterDataOuts[i] != collectedItem.cacheDataOuts[i]) begin
							int expected = collectedItem.masterDataOuts[i];
							int received = collectedItem.cacheDataOuts[i];
							`uvm_error("WRITE_BACK_DATA_ERROR", $sformatf("OFFSET=%d, EXPECTED=%d, RECEVIED=%d", i, expected, received))
							errorCounter++;
						end
					end

					if (collectedItem.writeBackState != INVALID_STATE) begin
						int expected = collectedItem.writeBackState;
						int received = INVALID_STATE;
						`uvm_error("WRITE_BACK_STATE_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
						errorCounter++;
					end
				end

				if (collectedItem.tagIn != collectedItem.masterAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
					int expected = collectedItem.tagIn;
					int received = collectedItem.masterAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
					`uvm_error("MASTER_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.index != collectedItem.masterAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
					int expected = collectedItem.index;
					int received = collectedItem.masterAddress[OFFSET_WIDTH +: INDEX_WIDTH];
					`uvm_error("MASTER_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.protocolStateOut != collectedItem.cacheStateOut) begin
					int expected = collectedItem.protocolStateOut;
					int received = collectedItem.cacheStateOut;
					`uvm_error("MASTER_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					if (collectedItem.masterDataIns[i] != collectedItem.cacheDataIns[i]) begin
						int expected = collectedItem.masterDataIns[i];
						int received = collectedItem.cacheDataIns[i];
						`uvm_error("MASTER_READ_DATA_ERROR", $sformatf("OFFSET=%d, EXPECTED=%d, RECEVIED=%d", i, expected, received))
						errorCounter++;
					end
				end

				if (collectedItem.isRead == 1 && collectedItem.cacheDataOut != collectedItem.cacheDataIns[collectedItem.offset]) begin
						int expected = collectedItem.cacheDataOut;
						int received = collectedItem.cacheDataIns[collectedItem.offset];
						`uvm_error("MASTER_DATA_ERROR", $sformatf("OFFSET=%d, EXPECTED=%d, RECEVIED=%d", collectedItem.offset, expected, received))
						errorCounter++;
				end
			end	

			if (collectedItem.invalidateRequired == 1) begin
				if (collectedItem.invalidateTag != collectedItem.invalidateAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
					int expected = collectedItem.invalidateTag;
					int received = collectedItem.invalidateAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
					`uvm_error("INVALIDATE_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.invalidateIndex != collectedItem.invalidateAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
					int expected = collectedItem.invalidateIndex;
					int received = collectedItem.invalidateAddress[OFFSET_WIDTH +: INDEX_WIDTH];
					`uvm_error("INVALIDATE_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end
			end

			if (collectedItem.isRead == 1) begin
				if (collectedItem.slaveDataIn != collectedItem.cacheDataOut) begin
					int expected = collectedItem.slaveDataIn;
					int received = collectedItem.cacheDataOut;
					`uvm_error("SLAVE_READ_DATA_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end
			end else begin
				if (collectedItem.slaveDataOut != collectedItem.cacheDataOut) begin
					int expected = collectedItem.slaveDataOut;
					int received = collectedItem.cacheDataIn;
					`uvm_error("SLAVE_WRITE_DATA_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end
			end
			if (errorCounter == 0) begin
				`uvm_info("TEST_OK", "", UVM_LOW)
			end
		endfunction : checkBehaviour 
	endclass : CPUControllerScoreboard

	class CPUControllerTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		`uvm_component_utils(CPUControllerTest)

		function new(string name = "CPUControllerTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(CPUControllerSequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(CPUControllerDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(CPUControllerCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(CPUControllerMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(CPUControllerScoreboard::get_type(), 1);
		endfunction : registerReplacements
	endclass : CPUControllerTest
endpackage : testPackage 
