package setAssociativeLRUTestPackage;
	
	import uvm_pkg::*;
	import setAssociativeLRUEnvironmentPackage::*;
	`include "uvm_macros.svh"

	localparam INDEX_WIDTH       = 8;
	localparam SET_ASSOCIATIVITY = 4;
	localparam SEQUENCE_COUNT    = 10000;

	class SetAssociativeLRUTest extends uvm_test;
		
		`uvm_component_utils(SetAssociativeLRUTest)

		SetAssociativeLRUEnvironment#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) environment;

		function new(string name = "SetAssociativeLRUTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			environment = SetAssociativeLRUEnvironment#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))::type_id::create(.name("environment"), .parent(this));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			SetAssociativeLRUSequence#(
				.INDEX_WIDTH(INDEX_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			) testSequence;

			phase.raise_objection(this);
				testSequence = SetAssociativeLRUSequence#(
					.INDEX_WIDTH(INDEX_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
					.SEQUENCE_COUNT(SEQUENCE_COUNT)
				)::type_id::create(.name("testSequence"));

				testSequence.start(environment.agent.sequencer);
			phase.drop_objection(this);
		endtask : run_phase
	endclass : SetAssociativeLRUTest
endpackage : setAssociativeLRUTestPackage
