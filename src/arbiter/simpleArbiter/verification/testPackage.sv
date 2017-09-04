package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;

	localparam NUMBER_OF_DEVICES   = 8;
	localparam SEQUENCE_ITEM_COUNT = 1000;
	localparam TEST_INTERFACE      = "TestInterface";

	class ArbiterSequenceItem extends BasicSequenceItem;
		bit[NUMBER_OF_DEVICES - 1 : 0] requests;

		`uvm_object_utils_begin(ArbiterSequenceItem)
			`uvm_field_int(requests, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "ArbiterSequenceItem");
			super.new(.name(name));
		endfunction : new

		virtual function void myRandomize();
			requests = $urandom();
		endfunction : myRandomize
	endclass : ArbiterSequenceItem

	class ArbiterDriver extends BasicDriver;
		`uvm_component_utils(ArbiterDriver)

		protected virtual TestInterface#(
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) testInterface;

		ArbiterSequenceItem sequenceItem;

		function new(string name, uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if (!uvm_config_db#(virtual TestInterface#(.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase
		
		virtual task resetDUT();
			@(posedge testInterface.clock);
		endtask : resetDUT

		virtual task drive();
			$cast(sequenceItem, req);

			//for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
			//	testInterface.arbiterInterfaces[i].request = sequenceItem.requests[i];
			//end
			testInterface.requests = sequenceItem.requests;

			@(posedge testInterface.clock);
			@(posedge testInterface.clock);
		endtask : drive;
	endclass : ArbiterDriver
	
	class ArbiterCollectedItem extends BasicCollectedItem;
		bit[NUMBER_OF_DEVICES - 1 : 0] requests, grants;

		`uvm_object_utils_begin(ArbiterCollectedItem)
			`uvm_field_int(requests, UVM_ALL_ON)
			`uvm_field_int(grants, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "ArbiterCollectedItem");
			super.new(.name(name));
		endfunction : new
	endclass : ArbiterCollectedItem

	//memory monitor
	class ArbiterMonitor extends BasicMonitor;
		`uvm_component_utils(ArbiterMonitor)

		virtual TestInterface#(
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) testInterface;

		function new(string name = "ArbiterMonitor", uvm_component parent);
			super.new(name, parent);
		endfunction : new 

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if (!uvm_config_db#(virtual TestInterface#(.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTAUL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase	

		virtual task resetDUT();
			@(posedge testInterface.clock);
		endtask : resetDUT
			
		virtual task collect();
			ArbiterCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);

			@(posedge testInterface.clock);

			//for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
			//	collectedItem.requests[i] = testInterface.arbiterInterfaces[i].request;
			//	collectedItem.grants[i]   = testInterface.arbiterInterfaces[i].grant;
			//end

			collectedItem.requests = testInterface.requests;
			collectedItem.grants = testInterface.grants;

			@(posedge testInterface.clock);
		endtask : collect
	endclass : ArbiterMonitor

	//s=memory scoreboard
	class ArbiterScoreboard extends BasicScoreboard;
		`uvm_component_utils(ArbiterScoreboard)

		ArbiterCollectedItem collectedItem;

		function new(string name = "ArbiterScoreboard", uvm_component parent);
			super.new(name, parent);
		endfunction : new

		virtual function void checkBehaviour();
			int errorCounter = 0;
			int grants = 0;
			$cast(collectedItem, super.collectedItem);

			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				if (collectedItem.requests[i] == 1) begin
					if (collectedItem.grants[i] == 1) begin
						if (grants == 0) begin
							grants++;
						end else begin
							`uvm_error("ARBITER_ERROR", "")
							errorCounter++;
						end
					end
				end
			end

			if (errorCounter == 0) begin
				`uvm_info("TEST_OK", "", UVM_LOW)
			end
		endfunction : checkBehaviour 
	endclass : ArbiterScoreboard

	//memory test
	class ArbiterTest extends BasicTest#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT));
		`uvm_component_utils(ArbiterTest)

		function new(string name = "ArbiterTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(ArbiterSequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(ArbiterDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(ArbiterCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(ArbiterMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(ArbiterScoreboard::get_type(), 1);
		endfunction : registerReplacements;		
	endclass : ArbiterTest
endpackage : testPackage
