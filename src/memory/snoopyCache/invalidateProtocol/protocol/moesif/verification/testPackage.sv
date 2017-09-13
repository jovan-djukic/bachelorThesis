package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import classImplementation::*;
	import commands::*;
	import states::*;

	localparam type STATE_TYPE                        = CacheLineState;
	localparam STATE_SET_LENGTH                       = 6;
	localparam STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {
																									MODIFIED,
																									OWNED,
																									EXCLUSIVE,
																									SHARED,
																									INVALID,
																									FORWARD
																							};
	localparam COMMAND_SET_LENGTH                      = 3;
	localparam Command COMMAND_SET[COMMAND_SET_LENGTH] = {
																									BUS_READ,
																									BUS_INVALIDATE,
																									BUS_READ_EXCLUSIVE
																							};
	localparam SEQUENCE_ITEM_COUNT = 1000;
	localparam TEST_INTERFACE      = "TestInterface";


	class MOESIFSequenceItem extends BasicSequenceItem;
		STATE_TYPE cpuStateOut, snoopyStateOut, writeBackState;
		bit cpuRead, cpuWrite, isShared, isOwned;
		Command snoopyCommandIn;

		`uvm_object_utils_begin(MOESIFSequenceItem)
			`uvm_field_enum(STATE_TYPE, cpuStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, writeBackState, UVM_ALL_ON)
			`uvm_field_enum(Command, snoopyCommandIn, UVM_ALL_ON)
			`uvm_field_int(cpuRead, UVM_ALL_ON)
			`uvm_field_int(cpuWrite, UVM_ALL_ON)
			`uvm_field_int(isShared, UVM_ALL_ON)
			`uvm_field_int(isOwned, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "MOESIFSequenceItem");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			cpuStateOut     = STATE_SET[$urandom() % STATE_SET_LENGTH];
			snoopyStateOut  = STATE_SET[$urandom() % STATE_SET_LENGTH];
			writeBackState  = STATE_SET[$urandom() % STATE_SET_LENGTH];
			cpuRead         = $urandom();
			cpuWrite        = ~cpuRead;
			isShared        = $urandom();
			isOwned         = $urandom();
			snoopyCommandIn = COMMAND_SET[$urandom() % COMMAND_SET_LENGTH];
		endfunction : myRandomize
	endclass : MOESIFSequenceItem

	class MOESIFDriver extends BasicDriver;
		`uvm_component_utils(MOESIFDriver)

		virtual TestInterface#(
			.STATE_TYPE(STATE_TYPE)
		) testInterface;

		function new(string name = "MOESIFDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
				.STATE_TYPE(STATE_TYPE)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
				@(posedge testInterface.clock);
		endtask : resetDUT

		virtual task drive();
			MOESIFSequenceItem sequenceItem;
			$cast(sequenceItem, req);

			testInterface.cpuProtocolInterface.stateOut       = sequenceItem.cpuStateOut;
			testInterface.cpuProtocolInterface.writeBackState = sequenceItem.writeBackState;
			testInterface.cpuProtocolInterface.read           = sequenceItem.cpuRead;
			testInterface.cpuProtocolInterface.write          = sequenceItem.cpuWrite;

			testInterface.snoopyProtocolInterface.stateOut  = sequenceItem.snoopyStateOut;
			testInterface.snoopyProtocolInterface.commandIn = sequenceItem.snoopyCommandIn;

			testInterface.moesifInterface.sharedIn = sequenceItem.isShared;
			testInterface.moesifInterface.ownedIn  = sequenceItem.isOwned;
			@(posedge testInterface.clock);
			@(posedge testInterface.clock);
		endtask : drive
	endclass : MOESIFDriver

	class MOESIFCollectedItem extends BasicCollectedItem;
		STATE_TYPE cpuStateOut, cpuStateIn, snoopyStateOut, snoopyStateIn, writeBackState;
		bit cpuRead, cpuWrite, sharedIn, sharedOut, ownedIn, ownedOut, writeBackRequired, invalidateRequired, readExclusiveRequired, request;
		Command snoopyCommandIn;

		`uvm_object_utils_begin(MOESIFCollectedItem)
			`uvm_field_enum(STATE_TYPE, cpuStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cpuStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateOut, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, writeBackState, UVM_ALL_ON)
			`uvm_field_enum(Command, snoopyCommandIn, UVM_ALL_ON)
			`uvm_field_int(cpuRead, UVM_ALL_ON)
			`uvm_field_int(cpuWrite, UVM_ALL_ON)
			`uvm_field_int(sharedIn, UVM_ALL_ON)
			`uvm_field_int(sharedOut, UVM_ALL_ON)
			`uvm_field_int(ownedIn, UVM_ALL_ON)
			`uvm_field_int(ownedOut, UVM_ALL_ON)
			`uvm_field_int(writeBackRequired, UVM_ALL_ON)
			`uvm_field_int(invalidateRequired, UVM_ALL_ON)
			`uvm_field_int(readExclusiveRequired, UVM_ALL_ON)
			`uvm_field_int(request, UVM_ALL_ON)
		`uvm_object_utils_end
	endclass : MOESIFCollectedItem

	class MOESIFMonitor extends BasicMonitor;
		`uvm_component_utils(MOESIFMonitor)

		virtual TestInterface#(
			.STATE_TYPE(STATE_TYPE)
		) testInterface;

		function new(string name = "MOESIFMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
				.STATE_TYPE(STATE_TYPE)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
				@(posedge testInterface.clock);
		endtask : resetDUT

		virtual task collect();
			MOESIFCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);
			
			@(posedge testInterface.clock);
			
			collectedItem.cpuStateOut           = testInterface.cpuProtocolInterface.stateOut;
			collectedItem.cpuStateIn            = testInterface.cpuProtocolInterface.stateIn;
			collectedItem.snoopyStateOut        = testInterface.snoopyProtocolInterface.stateOut;
			collectedItem.snoopyStateIn         = testInterface.snoopyProtocolInterface.stateIn;
			collectedItem.writeBackState				= testInterface.cpuProtocolInterface.writeBackState;
			collectedItem.cpuRead               = testInterface.cpuProtocolInterface.read;
			collectedItem.cpuWrite              = testInterface.cpuProtocolInterface.write;
			collectedItem.sharedIn              = testInterface.moesifInterface.sharedIn;
			collectedItem.sharedOut             = testInterface.moesifInterface.sharedOut;
			collectedItem.ownedIn              	= testInterface.moesifInterface.ownedIn;
			collectedItem.ownedOut             	= testInterface.moesifInterface.ownedOut;
			collectedItem.writeBackRequired     = testInterface.cpuProtocolInterface.writeBackRequired;
			collectedItem.invalidateRequired    = testInterface.cpuProtocolInterface.invalidateRequired;
			collectedItem.readExclusiveRequired = testInterface.cpuProtocolInterface.readExclusiveRequired;
			collectedItem.request               = testInterface.snoopyProtocolInterface.request;
			collectedItem.snoopyCommandIn       = testInterface.snoopyProtocolInterface.commandIn;

			@(posedge testInterface.clock);
		endtask : collect
	endclass : MOESIFMonitor

	class MOESIFScoreboard extends BasicScoreboard;
		`uvm_component_utils(MOESIFScoreboard)

		MOESIFClassImplementation classImplementation;

		function new(string name = "MOESIFScoreaboard", uvm_component parent);
			super.new(.name(name), .parent(parent));

			classImplementation = new();
		endfunction : new

		virtual function void checkBehaviour();
			int errorCounter = 0;	
			MOESIFCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);

			if (collectedItem.writeBackRequired != classImplementation.writeBackRequired(.state(collectedItem.writeBackState))) begin
				int expected = classImplementation.writeBackRequired(.state(collectedItem.cpuStateOut));
				int received = collectedItem.writeBackRequired;
				`uvm_error("WRITE_BACK_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.invalidateRequired != classImplementation.invalidateRequired(.state(collectedItem.cpuStateOut), .write(collectedItem.cpuWrite))) begin
				int expected = classImplementation.invalidateRequired(.state(collectedItem.cpuStateOut), .write(collectedItem.cpuWrite));
				int received = collectedItem.invalidateRequired;
				`uvm_error("INVALIDATE_REQUIRED_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.readExclusiveRequired != classImplementation.readExclusiveRequired(.state(collectedItem.cpuStateOut), .write(collectedItem.cpuWrite))) begin
				int expected = classImplementation.readExclusiveRequired(.state(collectedItem.cpuStateOut), .write(collectedItem.cpuWrite));
				int received = collectedItem.readExclusiveRequired;
				`uvm_error("READ_EXCLUSIVE_REQUIRED_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.cpuStateIn != classImplementation.cpuStateIn(.state(collectedItem.cpuStateOut),
																																		 .read(collectedItem.cpuRead),
																																		 .write(collectedItem.cpuWrite),
																																		 .sharedIn(collectedItem.sharedIn),
																																		 .ownedIn(collectedItem.ownedIn))) begin
				int expected = classImplementation.cpuStateIn(.state(collectedItem.cpuStateOut),
																																		 .read(collectedItem.cpuRead),
																																		 .write(collectedItem.cpuWrite),
																																		 .sharedIn(collectedItem.sharedIn),
																																		 .ownedIn(collectedItem.ownedIn));
				int received = collectedItem.cpuStateIn;
				`uvm_error("CPU_STATE_IN_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.request != classImplementation.request(.state(collectedItem.snoopyStateOut))) begin
				int expected = classImplementation.request(.state(collectedItem.snoopyStateOut));
				int received = collectedItem.request;
				`uvm_error("REQUEST_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (collectedItem.snoopyStateIn != classImplementation.snoopyStateIn(.state(collectedItem.snoopyStateOut), .command(collectedItem.snoopyCommandIn))) begin
				int expected = classImplementation.snoopyStateIn(.state(collectedItem.snoopyStateOut), .command(collectedItem.snoopyCommandIn));
				int received = collectedItem.snoopyStateIn;
				`uvm_error("SNOOPY_STATE_IN_MISMATCH", $sformatf("EXPECTED=%d, RECEIVED=%d", expected, received))
				errorCounter++;
			end

			if (errorCounter == 0) begin
				`uvm_info("TEST_OK", "", UVM_LOW)
			end
		endfunction : checkBehaviour 
	endclass : MOESIFScoreboard

	class MOESIFTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		`uvm_component_utils(MOESIFTest)

		function new(string name = "MOESIFTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(MOESIFSequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(MOESIFDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(MOESIFCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(MOESIFMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(MOESIFScoreboard::get_type(), 1);
		endfunction : registerReplacements
	endclass : MOESIFTest
endpackage : testPackage 
