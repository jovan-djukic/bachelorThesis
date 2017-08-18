package ramTestPackage;
	import uvm_pkg::*;
	import ramAgentPackage::*;
	`include "uvm_macros.svh"

	parameter ADDRESS_WIDTH			= 16;
	parameter DATA_WIDTH				= 8;
	parameter SIZE							= 1024;
	parameter SEQUENCE_COUNT		= 1000;

	//Scoreboard
	class MemoryScoreboard extends uvm_scoreboard;
		`uvm_component_utils(MemoryScoreboard)

		uvm_analysis_export#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)) analysisExport;
		uvm_tlm_analysis_fifo#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)) fifo;
		MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) memoryTransaction;

		logic [DATA_WIDTH - 1 : 0] memory[SIZE];

		function new(string name = "MemoryScoreboard", uvm_component parent);
			super.new(name, parent);

			memoryTransaction	= new("MemoryTransaction");
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			analysisExport = new("analysisExport", this);
			fifo 					 = new("fifo", this);

			for (int i = 0; i < SIZE; i++) begin
				memory[i] = 0;
			end
		endfunction : build_phase

		function void connect_phase(uvm_phase phase);
			analysisExport.connect(fifo.analysis_export);
		endfunction : connect_phase

		task run();
			forever begin
				fifo.get(memoryTransaction);
				compare();
			end
		endtask : run

		virtual task compare();
			if (memoryTransaction.isRead) begin
				if (memoryTransaction.data != memory[memoryTransaction.address]) begin
					`uvm_info("READ ERROR", $sformatf("ADDRESS: %d, VALUE READ: %d, VALUE EXPECTED: %d", memoryTransaction.address, memory[memoryTransaction.address], memoryTransaction.data), UVM_LOW)	
				end else begin
					`uvm_info("TEST OK", $sformatf("MEM[%d]=%d, RAM[%d]=%d", memoryTransaction.address, memory[memoryTransaction.address], memoryTransaction.address, memoryTransaction.data), UVM_LOW)
				end
			end else begin
				`uvm_info("WRITING", $sformatf("MEM[%d] = %d", memoryTransaction.address, memoryTransaction.data), UVM_LOW)
				memory[memoryTransaction.address] = memoryTransaction.data;
			end	
		endtask : compare
	endclass : MemoryScoreboard

	//Environment
	class MemoryEnvironment extends uvm_env;
		`uvm_component_utils(MemoryEnvironment)

		MemoryAgent#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) agent;
		MemoryScoreboard															scoreboard;

		function new(string name = "MemoryEnvironment", uvm_component parent);
			super.new(name, parent);
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			agent				= MemoryAgent#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::type_id::create("MemoryAgent", this);
			scoreboard	= MemoryScoreboard::type_id::create("MemoryScoreboard", this);
		endfunction : build_phase

		function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);

			agent.analysisPort.connect(scoreboard.analysisExport);
		endfunction : connect_phase
	endclass : MemoryEnvironment
		
	//Test
	class MemoryTest extends uvm_test;
		`uvm_component_utils(MemoryTest)

		MemoryEnvironment environment;

		function new(string name = "MemoryTest", uvm_component parent);
			super.new(name, parent);
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			environment	= MemoryEnvironment::type_id::create("MemoryEnvironment", this);
		endfunction : build_phase

		task run_phase(uvm_phase phase);
			MemoryVirtualSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE, SEQUENCE_COUNT) memoryVirtualSequence;

			phase.raise_objection(this);
				memoryVirtualSequence = MemoryVirtualSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE, SEQUENCE_COUNT)::type_id::create("MemoryVirtualSequence");
				memoryVirtualSequence.sequencer = environment.agent.sequencer;
				memoryVirtualSequence.start(null);
			phase.drop_objection(this);
		endtask : run_phase
	endclass : MemoryTest
endpackage : ramTestPackage
