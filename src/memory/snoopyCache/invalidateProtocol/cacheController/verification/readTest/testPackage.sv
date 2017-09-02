package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import busCommands::*;

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
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
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
			CPUControllerSequenceItem sequenceItem;
			$cast(sequenceItem, req);

			testInterface.cpuSlaveInterface.address = sequenceItem.address;
	
			@(posedge testInterface.clock);

			testInterface.cpuSlaveInterface.readEnabled  = sequenceItem.isRead;
			testInterface.cpuSlaveInterface.writeEnabled = ~sequenceItem.isRead;
			testInterface.cpuSlaveInterface.dataOut      = sequenceItem.writeData;

			do begin
				@(posedge testInterface.clock);

				if (testInterface.cpuSlaveInterface.functionComplete == 1) begin
					break;
				end

				testInterface.cpuArbiterInterface.grant	= testInterface.cpuArbiterInterface.request;

				if (testInterface.cpuMasterInterface.readEnabled == 1) begin
					testInterface.cpuMasterInterface.dataIn = sequenceItem.ramData;
					@(posedge testInterface.clock);
					testInterface.cpuMasterInterface.functionComplete = 1;
					wait (testInterface.cpuMasterInterface.readEnabled == 0);
					testInterface.cpuMasterInterface.functionComplete = 0;
					sequenceItem.ramData++;
				end

				if (testInterface.cpuMasterInterface.writeEnabled == 1) begin
					testInterface.cpuMasterInterface.functionComplete = 1;
					wait (testInterface.cpuMasterInterface.writeEnabled == 0);
					testInterface.cpuMasterInterface.functionComplete = 0;
				end

				if (testInterface.busInterface.cpuCommandOut == BUS_INVALIDATE) begin
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						if (i != CACHE_ID) begin
							testInterface.busInterface.cpuCommandIn  = BUS_INVALIDATE;
							testInterface.busInterface.cacheNumberIn = i;

							repeat (2) begin
								@(posedge testInterface.clock);
							end
						end
					end

					testInterface.busInterface.cpuCommandIn  = NONE;
					testInterface.busInterface.cacheNumberIn = 0;
				end
			end while (1);

			testInterface.cpuSlaveInterface.readEnabled       = 0;
			testInterface.cpuSlaveInterface.writeEnabled      = 0;
			testInterface.cpuArbiterInterface.grant           = 0;
			//while (testInterface.cpuSlaveInterface.functionComplete == 1) begin
			//	@(posedge testInterface.clock);
			//end
			wait (testInterface.cpuSlaveInterface.functionComplete == 0);
		endtask : drive
	endclass : CPUControllerDriver

	class CPUControllerCollectedItem extends BasicCollectedItem;
		//if is hit we only nead readData and cachedData
		bit[ADDRESS_WIDTH - 1 : 0] cpuSlaveAddress;
		bit[DATA_WIDTH - 1    : 0] readData, cachedData;
		bit[TAG_WIDTH - 1     : 0] slaveTagIn;
		bit[INDEX_WIDTH - 1   : 0] slaveIndexIn;
		bit[OFFSET_WIDTH - 1  : 0] slaveOffset;
		bit												 cpuHit;

		//if it is not hit we need readRamLine and readCacheLine
		bit[ADDRESS_WIDTH - 1 : 0] cpuMasterAddress;
		bit[TAG_WIDTH - 1     : 0] masterTag;
		bit[INDEX_WIDTH - 1   : 0] masterIndex;
		bit[DATA_WIDTH - 1    : 0] readRamLine[NUMBER_OF_WORDS_PER_LINE], readCacheLine[NUMBER_OF_WORDS_PER_LINE];
		STATE_TYPE 								 protocolStateOut, cpuStateIn;

		//if the cached line needs to be writen back
		bit[ADDRESS_WIDTH - 1 : 0] writeBackAddress;
		bit[DATA_WIDTH - 1    : 0] writeBackCacheLine[NUMBER_OF_WORDS_PER_LINE], writeBackRamLine[NUMBER_OF_WORDS_PER_LINE];
		bit[TAG_WIDTH - 1     : 0] writeBackTag;
		bit[INDEX_WIDTH - 1   : 0] writeBackIndex;
		bit												 writeBackRequired;

		//if operation is write
		bit[DATA_WIDTH - 1       : 0] slaveWriteData, cacheWriteData;
		bit[NUMBER_OF_CACHES - 1 : 0] invalidated;
		bit 												  isWrite, invalidateRequired;
		STATE_TYPE                    protocolWriteState, cacheWriteState;

		`uvm_object_utils_begin(CPUControllerCollectedItem)
			`uvm_field_int(cpuSlaveAddress, UVM_ALL_ON)
			`uvm_field_int(readData, UVM_ALL_ON)
			`uvm_field_int(cachedData, UVM_ALL_ON)
			`uvm_field_int(slaveTagIn, UVM_ALL_ON)
			`uvm_field_int(slaveIndexIn, UVM_ALL_ON)
			`uvm_field_int(cpuHit, UVM_ALL_ON)

			`uvm_field_int(cpuMasterAddress, UVM_ALL_ON)
			`uvm_field_int(masterTag, UVM_ALL_ON)
			`uvm_field_int(masterIndex, UVM_ALL_ON)
			`uvm_field_sarray_int(readRamLine, UVM_ALL_ON)
			`uvm_field_sarray_int(readCacheLine, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cpuStateIn, UVM_ALL_ON)

			`uvm_field_sarray_int(writeBackCacheLine, UVM_ALL_ON)
			`uvm_field_sarray_int(writeBackRamLine, UVM_ALL_ON)
			`uvm_field_int(writeBackTag, UVM_ALL_ON)
			`uvm_field_int(writeBackIndex, UVM_ALL_ON)
			`uvm_field_int(writeBackRequired, UVM_ALL_ON)

			`uvm_field_int(slaveWriteData, UVM_ALL_ON)
			`uvm_field_int(cacheWriteData, UVM_ALL_ON)
			`uvm_field_int(invalidated, UVM_ALL_ON)
			`uvm_field_int(isWrite, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, protocolStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cpuStateIn, UVM_ALL_ON)
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
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
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
			CPUControllerCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);
			
			collectedItem.invalidated        = 0;
			collectedItem.invalidateRequired = 0;

			@(posedge testInterface.clock);

			collectedItem.cpuSlaveAddress   = testInterface.cpuSlaveInterface.address;
			collectedItem.slaveTagIn        = testInterface.cacheInterface.cpuTagIn;
			collectedItem.slaveIndexIn      = testInterface.cacheInterface.cpuIndex;
			collectedItem.writeBackRequired = testInterface.protocolInterface.writeBackRequired;
			collectedItem.cpuHit            = testInterface.cacheInterface.cpuHit;

			do begin
				@(posedge testInterface.clock);

				collectedItem.isWrite = testInterface.cpuSlaveInterface.writeEnabled;

				if (testInterface.cpuSlaveInterface.functionComplete == 1) begin
					break;
				end

				//testInterface.cpuArbiterInterface.grant = testInterface.cpuArbiterInterface.request;

				if (testInterface.cpuMasterInterface.readEnabled == 1) begin
					//testInterface.cpuMasterInterface.dataIn = sequenceItem.ramData;
					collectedItem.cpuMasterAddress = testInterface.cpuMasterInterface.address;
					collectedItem.masterTag        = testInterface.cacheInterface.cpuTagIn;
					collectedItem.masterIndex      = testInterface.cacheInterface.cpuIndex;
					@(posedge testInterface.clock);
					//testInterface.cpuMasterInterface.functionComplete = 1;
					collectedItem.readRamLine[testInterface.cpuMasterInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.cpuMasterInterface.dataIn;	
					wait (testInterface.cacheInterface.cpuWriteData == 1);
					collectedItem.readCacheLine[testInterface.cacheInterface.cpuOffset] = testInterface.cacheInterface.cpuDataIn;
					wait (testInterface.cpuMasterInterface.readEnabled == 0);

					if (testInterface.cacheInterface.cpuWriteState) begin
						collectedItem.protocolStateOut = testInterface.protocolInterface.cpuStateIn;
						collectedItem.cpuStateIn       = testInterface.cacheInterface.cpuStateIn;
					end
					//testInterface.cpuMasterInterface.functionComplete = 0;
					//sequenceItem.ramData++;
				end

				if (testInterface.cpuMasterInterface.writeEnabled == 1) begin
					//testInterface.cpuMasterInterface.functionComplete = 1;
					collectedItem.writeBackAddress                                                                 = testInterface.cpuMasterInterface.address;
					collectedItem.writeBackTag                                                                     = testInterface.cacheInterface.cpuTagOut;
					collectedItem.writeBackIndex                                                                   = testInterface.cacheInterface.cpuIndex;
					collectedItem.writeBackCacheLine[testInterface.cacheInterface.cpuOffset]                       = testInterface.cacheInterface.cpuDataOut;
					collectedItem.writeBackRamLine[testInterface.cpuMasterInterface.address[OFFSET_WIDTH - 1 : 0]] = testInterface.cpuMasterInterface.dataOut;
					wait (testInterface.cpuMasterInterface.writeEnabled == 0);
				end

				if (testInterface.busInterface.cpuCommandOut == BUS_INVALIDATE) begin
					collectedItem.invalidateRequired = 1;
					for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
						if (i != CACHE_ID) begin
							repeat (2) begin
								@(posedge testInterface.clock);
							end
						end
						collectedItem.invalidated[i] = 1;
					end
				end

				if (testInterface.cacheInterface.cpuWriteData == 1) begin
					collectedItem.cacheWriteData = testInterface.cacheInterface.cpuDataIn;
				end

				if (testInterface.cacheInterface.cpuWriteState == 1) begin
					collectedItem.protocolWriteState = testInterface.protocolInterface.cpuStateIn;
					collectedItem.cacheWriteState    = testInterface.cacheInterface.cpuStateIn;
				end
			end while (1);

			//testInterface.cpuSlaveInterface.readEnabled = 0;
			collectedItem.slaveWriteData = testInterface.cpuSlaveInterface.dataOut;
			collectedItem.readData       = testInterface.cpuSlaveInterface.dataIn;
			collectedItem.cachedData     = testInterface.cacheInterface.cpuDataOut;
			collectedItem.slaveOffset    = testInterface.cacheInterface.cpuOffset;

			wait (testInterface.cpuSlaveInterface.functionComplete == 0);
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

			if (collectedItem.slaveTagIn != collectedItem.cpuSlaveAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
				int expected = collectedItem.slaveTagIn;
				int received = collectedItem.cpuSlaveAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
				`uvm_error("SLAVE_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
				errorCounter++;
			end
			
			if (collectedItem.slaveIndexIn != collectedItem.cpuSlaveAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
				int expected = collectedItem.slaveIndexIn;
				int received = collectedItem.cpuSlaveAddress[OFFSET_WIDTH +: INDEX_WIDTH];
				`uvm_error("SLAVE_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.slaveOffset != collectedItem.cpuSlaveAddress[OFFSET_WIDTH - 1 : 0]) begin
				int expected = collectedItem.slaveOffset;
				int received = collectedItem.cpuSlaveAddress[OFFSET_WIDTH - 1 : 0];
				`uvm_error("SLAVE_OFFSET_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.isWrite == 0) begin
				if (collectedItem.readData != collectedItem.cachedData) begin
					int expected = collectedItem.readData;
					int received = collectedItem.cachedData;
					`uvm_error("SLAVE_READ_DATA_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end
			end else begin
				if (collectedItem.slaveWriteData != collectedItem.cacheWriteData) begin
					int expected = collectedItem.slaveWriteData;
					int received = collectedItem.cacheWriteData;
					`uvm_error("SLAVE_WRITE_DATA_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.invalidateRequired == 1 && collectedItem.invalidated == 0) begin
					int expected = 0;
					int received = collectedItem.invalidated;
					`uvm_error("SLAVE_INVALIDATE_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.protocolWriteState != collectedItem.cacheWriteState) begin
					int expected = collectedItem.slaveWriteData;
					int received = collectedItem.cacheWriteData;
					`uvm_error("SLAVE_WRITE_STATE_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end
			end

			if (collectedItem.cpuHit == 0) begin
				if (collectedItem.masterTag != collectedItem.cpuMasterAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
					int expected = collectedItem.masterTag;
					int received = collectedItem.cpuMasterAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
					`uvm_error("MASTER_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.masterIndex != collectedItem.cpuMasterAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
					int expected = collectedItem.masterIndex;
					int received = collectedItem.cpuMasterAddress[OFFSET_WIDTH +: INDEX_WIDTH];
					`uvm_error("MASTER_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.protocolStateOut != collectedItem.cpuStateIn) begin
					int expected = collectedItem.protocolStateOut;
					int received = collectedItem.cpuStateIn;
					`uvm_error("MASTER_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					if (collectedItem.readRamLine[i] != collectedItem.readCacheLine[i]) begin
						int expected = collectedItem.readRamLine[i];
						int received = collectedItem.readCacheLine[i];
						`uvm_error("MASTER_DATA_ERROR", $sformatf("OFFSET=%d, EXPECTED=%d, RECEVIED=%d", i, expected, received))
						errorCounter++;
					end
				end
			end	

			if (collectedItem.writeBackRequired == 0) begin
				if (collectedItem.writeBackTag != collectedItem.writeBackAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH]) begin
					int expected = collectedItem.writeBackTag;
					int received = collectedItem.writeBackAddress[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
					`uvm_error("WRITE_BACK_TAG_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				if (collectedItem.writeBackIndex != collectedItem.writeBackAddress[OFFSET_WIDTH +: INDEX_WIDTH]) begin
					int expected = collectedItem.writeBackIndex;
					int received = collectedItem.writeBackAddress[OFFSET_WIDTH +: INDEX_WIDTH];
					`uvm_error("WRITE_BACK_INDEX_ERROR", $sformatf("EXPECTED=%d, RECEVIED=%d", expected, received))
					errorCounter++;
				end

				for (int i = 0; i < NUMBER_OF_WORDS_PER_LINE; i++) begin
					if (collectedItem.writeBackRamLine[i] != collectedItem.writeBackCacheLine[i]) begin
						int expected = collectedItem.writeBackRamLine[i];
						int received = collectedItem.writeBackCacheLine[i];
						`uvm_error("WRITE_BACK_DATA_ERROR", $sformatf("OFFSET=%d, EXPECTED=%d, RECEVIED=%d", i, expected, received))
						errorCounter++;
					end
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
