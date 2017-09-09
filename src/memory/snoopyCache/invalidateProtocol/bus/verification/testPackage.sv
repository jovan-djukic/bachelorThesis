package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import commands::*;
	import types::*;

	localparam SEQUENCE_ITEM_COUNT = 3000;
	localparam TEST_INTERFACE      = "TestInterface";

	localparam COMMAND_SET_LENGTH = 5;
	localparam Command COMMAND_SET[COMMAND_SET_LENGTH] = {
																									NONE,
																									BUS_READ,
																									BUS_INVALIDATE,
																									BUS_READ_EXCLUSIVE,
																									BUS_WRITEBACK
																							};

	class BusSequenceItem extends BasicSequenceItem;
		bit[NUMBER_OF_CACHES - 1 : 0] cpuGrants, snoopyGrants;
		MemoryTransaction memoryTransactions[NUMBER_OF_CACHES];
		CPUCommandTransaction cpuCommandTransactions[NUMBER_OF_CACHES];
		ReadMemoryTransaction readMemoryTransactions[NUMBER_OF_CACHES];
		SnoopyCommandTransaction snoopyCommandTransactions[NUMBER_OF_CACHES];
		ReadMemoryTransaction ramMemoryTransaction;

		`uvm_object_utils_begin(BusSequenceItem)
			`uvm_field_int(cpuGrants, UVM_ALL_ON)
			`uvm_field_int(snoopyGrants, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "BusSequenceItem");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			cpuGrants    = 1 << $urandom_range(NUMBER_OF_CACHES - 1, 0);
			snoopyGrants = 1 << $urandom_range(NUMBER_OF_CACHES, 0);

			//cpu memory transactions
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				memoryTransactions[i].address = $urandom();
				memoryTransactions[i].dataOut = $urandom();
				memoryTransactions[i].readEnabled = $urandom();
				memoryTransactions[i].writeEnabled = ~memoryTransactions[i].readEnabled;
			end

			//cpu command transactions
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				cpuCommandTransactions[i].commandOut = COMMAND_SET[$urandom() % COMMAND_SET_LENGTH];
			end

			//snoopy memory transactions
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				readMemoryTransactions[i].dataIn           = $urandom();
				readMemoryTransactions[i].functionComplete = $urandom();
			end

			//snoopy command transactions
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				snoopyCommandTransactions[i].isInvalidated = $urandom();
			end

			//ram memory transaction
			ramMemoryTransaction.dataIn           = $urandom();
			ramMemoryTransaction.functionComplete = $urandom();
		endfunction : myRandomize
	endclass : BusSequenceItem

	class BusDriver extends BasicDriver;
		`uvm_component_utils(BusDriver)

		virtual TestInterface testInterface;

		function new(string name = "BusDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface)::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
				@(posedge testInterface.clock);
		endtask : resetDUT

		virtual task drive();
			BusSequenceItem sequenceItem;
			$cast(sequenceItem, req);
			
			testInterface.cpuGrants    = sequenceItem.cpuGrants;
			testInterface.snoopyGrants = sequenceItem.snoopyGrants;

			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				testInterface.cpuSlaveMemoryInterfaceStruct[i].address      = sequenceItem.memoryTransactions[i].address;
				testInterface.cpuSlaveMemoryInterfaceStruct[i].dataOut      = sequenceItem.memoryTransactions[i].dataOut;
				testInterface.cpuSlaveMemoryInterfaceStruct[i].readEnabled  = sequenceItem.memoryTransactions[i].readEnabled;
				testInterface.cpuSlaveMemoryInterfaceStruct[i].writeEnabled = sequenceItem.memoryTransactions[i].writeEnabled;
				
				testInterface.cpuBusCommandInterfaceStruct[i].commandOut = sequenceItem.cpuCommandTransactions[i].commandOut;
				
				testInterface.snoopyMasterReadMemoryInterfaceStruct[i].dataIn           = sequenceItem.readMemoryTransactions[i].dataIn;
				testInterface.snoopyMasterReadMemoryInterfaceStruct[i].functionComplete = sequenceItem.readMemoryTransactions[i].functionComplete;

				testInterface.snoopyBusCommandInterfaceStruct[i].isInvalidated = sequenceItem.snoopyCommandTransactions[i].isInvalidated;
			end
			
			testInterface.ramMemoryInterfaceStruct.dataIn           = sequenceItem.ramMemoryTransaction.dataIn;
			testInterface.ramMemoryInterfaceStruct.functionComplete = sequenceItem.ramMemoryTransaction.functionComplete;

			@(posedge testInterface.clock);
			@(posedge testInterface.clock);
		endtask : drive
	endclass : BusDriver

	class BusCollectedItem extends BasicCollectedItem;
		bit[NUMBER_OF_CACHES - 1 : 0] cpuGrants, snoopyGrants;
		MemoryCollectedItem cpuMemoryCollectedItems[NUMBER_OF_CACHES];
		CPUCommandCollectedItem cpuCommandCollectedItems[NUMBER_OF_CACHES];
		ReadMemoryCollectedItem snoopyMemoryCollectedItems[NUMBER_OF_CACHES];
		SnoopyCommandCollectedItem snoopyCommandCollectedItems[NUMBER_OF_CACHES];
		MemoryCollectedItem ramMemoryCollectedItem;

		`uvm_object_utils_begin(BusCollectedItem)
			`uvm_field_int(cpuGrants, UVM_ALL_ON)
			`uvm_field_int(snoopyGrants, UVM_ALL_ON)
		`uvm_object_utils_end
	endclass : BusCollectedItem

	class BusMonitor extends BasicMonitor;
		`uvm_component_utils(BusMonitor)

		virtual TestInterface testInterface;

		function new(string name = "BusMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface)::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
				@(posedge testInterface.clock);
		endtask : resetDUT

		virtual task collect();
			BusCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);
			
			@(posedge testInterface.clock);

			collectedItem.cpuGrants    = testInterface.cpuGrants;
			collectedItem.snoopyGrants = testInterface.snoopyGrants;

			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				collectedItem.cpuMemoryCollectedItems[i].address          = testInterface.cpuSlaveMemoryInterfaceStruct[i].address;
				collectedItem.cpuMemoryCollectedItems[i].dataOut          = testInterface.cpuSlaveMemoryInterfaceStruct[i].dataOut;
				collectedItem.cpuMemoryCollectedItems[i].dataIn           = testInterface.cpuSlaveMemoryInterfaceStruct[i].dataIn;
				collectedItem.cpuMemoryCollectedItems[i].readEnabled      = testInterface.cpuSlaveMemoryInterfaceStruct[i].readEnabled;
				collectedItem.cpuMemoryCollectedItems[i].writeEnabled     = testInterface.cpuSlaveMemoryInterfaceStruct[i].writeEnabled;
				collectedItem.cpuMemoryCollectedItems[i].functionComplete = testInterface.cpuSlaveMemoryInterfaceStruct[i].functionComplete;

				collectedItem.cpuCommandCollectedItems[i].commandOut    = testInterface.cpuBusCommandInterfaceStruct[i].commandOut;
				collectedItem.cpuCommandCollectedItems[i].isInvalidated = testInterface.cpuBusCommandInterfaceStruct[i].isInvalidated;
				
				collectedItem.snoopyMemoryCollectedItems[i].address          = testInterface.snoopyMasterReadMemoryInterfaceStruct[i].address;
				collectedItem.snoopyMemoryCollectedItems[i].dataIn           = testInterface.snoopyMasterReadMemoryInterfaceStruct[i].dataIn;
				collectedItem.snoopyMemoryCollectedItems[i].readEnabled      = testInterface.snoopyMasterReadMemoryInterfaceStruct[i].readEnabled;
				collectedItem.snoopyMemoryCollectedItems[i].functionComplete = testInterface.snoopyMasterReadMemoryInterfaceStruct[i].functionComplete;

				collectedItem.snoopyCommandCollectedItems[i].commandIn     = testInterface.snoopyBusCommandInterfaceStruct[i].commandIn;
				collectedItem.snoopyCommandCollectedItems[i].isInvalidated = testInterface.snoopyBusCommandInterfaceStruct[i].isInvalidated;
			end

				collectedItem.ramMemoryCollectedItem.address          = testInterface.ramMemoryInterfaceStruct.address;
				collectedItem.ramMemoryCollectedItem.dataOut          = testInterface.ramMemoryInterfaceStruct.dataOut;
				collectedItem.ramMemoryCollectedItem.dataIn           = testInterface.ramMemoryInterfaceStruct.dataIn;
				collectedItem.ramMemoryCollectedItem.readEnabled      = testInterface.ramMemoryInterfaceStruct.readEnabled;
				collectedItem.ramMemoryCollectedItem.writeEnabled     = testInterface.ramMemoryInterfaceStruct.writeEnabled;
				collectedItem.ramMemoryCollectedItem.functionComplete = testInterface.ramMemoryInterfaceStruct.functionComplete;
			@(posedge testInterface.clock);
		endtask : collect
	endclass : BusMonitor

	class BusScoreboard extends BasicScoreboard;
		`uvm_component_utils(BusScoreboard)

		function new(string name = "BusScoreaboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void checkBehaviour();
			int errorCounter = 0;	
			int cpuGrant = NUMBER_OF_CACHES, snoopyGrant = NUMBER_OF_CACHES;
			int isInvalidated = 1;
			BusCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);
			
			for (int i  = 0; i < NUMBER_OF_CACHES; i++) begin
				if (collectedItem.snoopyCommandCollectedItems[i].isInvalidated == 0) begin
					isInvalidated = 0;
					break;
				end
			end

			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				if (collectedItem.cpuGrants[i] == 1) begin
					cpuGrant = i;
				end
				if (collectedItem.snoopyGrants[i] == 1) begin
					snoopyGrant = i;
				end
			end	

			if (collectedItem.cpuMemoryCollectedItems[cpuGrant].address != collectedItem.ramMemoryCollectedItem.address) begin
				int expected = collectedItem.cpuMemoryCollectedItems[cpuGrant].address;
				int recevied = collectedItem.ramMemoryCollectedItem.address;
				`uvm_error("RAM_ADDRESS_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
				errorCounter++;
			end

			if (collectedItem.cpuMemoryCollectedItems[cpuGrant].dataOut != collectedItem.ramMemoryCollectedItem.dataOut) begin
				int expected = collectedItem.cpuMemoryCollectedItems[cpuGrant].dataOut;
				int recevied = collectedItem.ramMemoryCollectedItem.dataOut;
				`uvm_error("RAM_DATA_OUT_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
				errorCounter++;
			end

			if (collectedItem.cpuMemoryCollectedItems[cpuGrant].writeEnabled != collectedItem.ramMemoryCollectedItem.writeEnabled) begin
				int expected = collectedItem.cpuMemoryCollectedItems[cpuGrant].dataOut;
				int recevied = collectedItem.ramMemoryCollectedItem.dataOut;
				`uvm_error("RAM_WRITE_ENABLED_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
				errorCounter++;
			end

			if (snoopyGrant == NUMBER_OF_CACHES && collectedItem.cpuMemoryCollectedItems[cpuGrant].readEnabled != collectedItem.ramMemoryCollectedItem.readEnabled) begin
				int expected = collectedItem.cpuMemoryCollectedItems[cpuGrant].readEnabled;
				int recevied = collectedItem.ramMemoryCollectedItem.readEnabled;
				`uvm_error("RAM_READ_ENABLED_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
				errorCounter++;
			end

			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				if (collectedItem.cpuMemoryCollectedItems[cpuGrant].address != collectedItem.snoopyMemoryCollectedItems[i].address) begin
					int expected = collectedItem.cpuMemoryCollectedItems[cpuGrant].address;
					int recevied = collectedItem.snoopyMemoryCollectedItems[i].address;
					`uvm_error("SNOOPY_ADDRESS_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
					errorCounter++;
				end
			end

			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				if (collectedItem.cpuMemoryCollectedItems[cpuGrant].readEnabled != collectedItem.snoopyMemoryCollectedItems[i].readEnabled) begin
					int expected = collectedItem.cpuMemoryCollectedItems[cpuGrant].readEnabled;
					int recevied = collectedItem.snoopyMemoryCollectedItems[i].readEnabled;
					`uvm_error("SNOOPY_READ_ENABLED_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
					errorCounter++;
				end
			end

			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				if (collectedItem.cpuCommandCollectedItems[cpuGrant].commandOut != collectedItem.snoopyCommandCollectedItems[i].commandIn) begin
					int expected = collectedItem.cpuCommandCollectedItems[cpuGrant].commandOut;
					int recevied = collectedItem.snoopyCommandCollectedItems[i].commandIn;
					`uvm_error("SNOOPY_COMMAND_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
					errorCounter++;
				end
			end

			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				if (collectedItem.cpuCommandCollectedItems[i].isInvalidated != isInvalidated) begin
					int expected = collectedItem.cpuCommandCollectedItems[i].isInvalidated;
					int recevied = isInvalidated;
					`uvm_error("CPU_IS_INVALIDATED_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
					errorCounter++;
				end
			end
		
			if (snoopyGrant == NUMBER_OF_CACHES) begin
				for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
					if (collectedItem.cpuMemoryCollectedItems[i].dataIn != collectedItem.ramMemoryCollectedItem.dataIn) begin
						int expected = collectedItem.cpuMemoryCollectedItems[i].dataIn;
						int recevied = collectedItem.ramMemoryCollectedItem.dataIn;
						`uvm_error("CPU_RAM_DATA_IN_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
						errorCounter++;
					end
				end

				for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
					if (collectedItem.cpuMemoryCollectedItems[i].functionComplete != collectedItem.ramMemoryCollectedItem.functionComplete) begin
						int expected = collectedItem.cpuMemoryCollectedItems[i].functionComplete;
						int recevied = collectedItem.ramMemoryCollectedItem.functionComplete;
						`uvm_error("CPU_RAM_FUNCTION_COMPLETE_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
						errorCounter++;
					end
				end
			end else begin
				for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
					if (collectedItem.cpuMemoryCollectedItems[i].dataIn != collectedItem.snoopyMemoryCollectedItems[snoopyGrant].dataIn) begin
						int expected = collectedItem.cpuMemoryCollectedItems[i].dataIn;
						int recevied = collectedItem.snoopyMemoryCollectedItems[snoopyGrant].dataIn;
						`uvm_error("CPU_SNOOPY_DATA_IN_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
						errorCounter++;
					end
				end

				for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
					if (collectedItem.cpuMemoryCollectedItems[i].functionComplete != collectedItem.snoopyMemoryCollectedItems[snoopyGrant].functionComplete) begin
						int expected = collectedItem.cpuMemoryCollectedItems[i].functionComplete;
						int recevied = collectedItem.snoopyMemoryCollectedItems[snoopyGrant].functionComplete;
						`uvm_error("CPU_SNOOPY_FUNCTION_COMPLETE_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, recevied))
						errorCounter++;
					end
				end
			end

			if (errorCounter == 0) begin
				`uvm_info("TEST_OK", "", UVM_LOW)
			end
		endfunction : checkBehaviour 
	endclass : BusScoreboard

	class BusTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		`uvm_component_utils(BusTest)

		function new(string name = "BusTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(BusSequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(BusDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(BusCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(BusMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(BusScoreboard::get_type(), 1);
		endfunction : registerReplacements
	endclass : BusTest
endpackage : testPackage 
