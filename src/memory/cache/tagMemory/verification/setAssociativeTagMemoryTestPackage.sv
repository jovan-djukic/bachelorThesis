package setAssociativeTagMemoryTestPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import setAssociativeTagMemoryEnvironmentPackage::*;
	import types::*;

	localparam ADDRESS_WIDTH 							 						= 32;
	localparam type STATE_TYPE					   						= State;
	localparam STATE_SET_LENGTH						 						= 5;
	localparam STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {SHARED, EXCLUSIVE, FORWARD, MODIFIED, OWNED};
	localparam STATE_TYPE INVALID_STATE								= INVALID;
	localparam TAG_WIDTH		 							 						= 12;
	localparam INDEX_WIDTH	 							 						= 12;
	localparam SET_ASSOCIATIVITY 					 						= 4;
	localparam ADJUSTED_TAG_WIDTH 				 						= TAG_WIDTH + SET_ASSOCIATIVITY;
	localparam ADJUSTED_INDEX_WIDTH				 						= INDEX_WIDTH - SET_ASSOCIATIVITY;
	localparam OFFSET_WIDTH	 							 						= 8;

	localparam SEQUENCE_COUNT = 1000; 


	class TagAccessTest extends uvm_test;
		`uvm_component_utils(TagAccessTest)

		TagAccessEnvironment#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET),
			.INVALID_STATE(INVALID_STATE),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
			.TAG_WIDTH(ADJUSTED_TAG_WIDTH),
			.INDEX_WIDTH(ADJUSTED_INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH) 
		) environment;

		function new(string name = "TagAccessTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			environment = TagAccessEnvironment#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.INVALID_STATE(INVALID_STATE),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.TAG_WIDTH(ADJUSTED_TAG_WIDTH),
				.INDEX_WIDTH(ADJUSTED_INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH) 
			)::type_id::create(.name("environment"), .parent(this));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			TagAccessSequence#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			) cacheSequence = TagAccessSequence#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			)::type_id::create(.name("sequence"));

			phase.raise_objection(.obj(this));
				cacheSequence.start(environment.agent.sequencer);
			phase.drop_objection(.obj(this));
		endtask : run_phase

	endclass : TagAccessTest

endpackage : setAssociativeTagMemoryTestPackage
