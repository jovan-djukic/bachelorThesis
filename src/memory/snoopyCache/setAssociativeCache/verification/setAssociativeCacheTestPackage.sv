package setAssociativeCacheTestPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import setAssociativeCacheEnvirnomentPackage::*;

	typedef enum logic[1 : 0] {
		STATE_0,
		STATE_1,
		STATE_2,
		STATE_3	
	} State;

	localparam TAG_WIDTH                              = 9;
	localparam INDEX_WIDTH                            = 3;
	localparam OFFSET_WIDTH                           = 4;
	localparam SET_ASSOCIATIVITY                      = 3;
	localparam DATA_WIDTH                             = 16;
	localparam type STATE_TYPE                        = State;
	localparam STATE_SET_LENGTH                       = 3;
	localparam STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {STATE_1, STATE_2, STATE_3};
	localparam STATE_TYPE INVALID_STATE               = STATE_0;
	localparam SEQUENCE_COUNT                         = 1000;
	 
	class CacheAccessTest extends uvm_test;
		`uvm_component_utils(CacheAccessTest)

		CacheAccessEnvironment#(
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET),
			.INVALID_STATE(INVALID_STATE)	
		) environment;

		CacheAccessSequence#(
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET),
			.SEQUENCE_COUNT(SEQUENCE_COUNT)
		) testSequence;
		
		function new(string name = "CacheAccessTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			environment = CacheAccessEnvironment#(
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.INVALID_STATE(INVALID_STATE)	
			)::type_id::create(.name("environment"), .parent(this));

			testSequence = CacheAccessSequence#(
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.SEQUENCE_COUNT(SEQUENCE_COUNT)
			)::type_id::create(.name("testSequence"));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			phase.raise_objection(this);
				testSequence.start(environment.agent.sequencer);
			phase.drop_objection(this);
		endtask : run_phase

	endclass : CacheAccessTest

endpackage : setAssociativeCacheTestPackage
