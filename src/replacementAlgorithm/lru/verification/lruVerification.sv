package lruVerification;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import replacementAlgorithmVerification::*;

  parameter NUMBER_OF_CACHE_LINES = 4;

  //Scoreboard
  class LRUScoreboard extends uvm_scoreboard;
    
    `uvm_component_utils(LRUScoreboard);

    uvm_analysis_export#(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES)) collectedItemExport;
		uvm_tlm_analysis_fifo#(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES)) analysisFifo;
		ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES) transaction;

    int counters[NUMBER_OF_CACHE_LINES];

    function new(string name = "LRUScoreboard", uvm_component parent);
      super.new(name, parent);
			transaction = new("transaction");

      for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
        counters[i] = i;
      end
    endfunction : new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      collectedItemExport = new("collectedItemExport", this);
			analysisFifo = new("analysisFifo", this);
    endfunction : build_phase

		function void connect_phase(uvm_phase phase);
			collectedItemExport.connect(analysisFifo.analysis_export);	
		endfunction : connect_phase

		task run();
			forever begin
				analysisFifo.get(transaction);
				check();
			end	
		endtask : run

    virtual function void check();
      $display("Scoreboard:: packet received");
      //transaction.print();
      
      //adjust counters
      for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
        if (i == transaction.lastAccessedCacheLine) begin
          continue; 
        end       
        if (counters[i] < counters[transaction.lastAccessedCacheLine]) begin
          counters[i]++;
        end
      end 

      for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
        if (counters[i] == ~0) begin
          if (i != transaction.replacementCacheLine) begin
            `uvm_info("compare", {"ERROR"}, UVM_LOW);
          end
          break;
        end
      end
    endfunction : check 

  endclass : LRUScoreboard

  //Environment
  class LRUEnvironment extends uvm_env;
    
    ReplacementAlgorithmAgent#(NUMBER_OF_CACHE_LINES) agent;
    LRUScoreboard                                     scoreboard;

    `uvm_component_utils(LRUEnvironment)

    function new(string name = "LRUEnvironment", uvm_component parent);
      super.new(name, parent);
    endfunction : new
    
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      agent       = ReplacementAlgorithmAgent#(NUMBER_OF_CACHE_LINES)::type_id::create("ReplacementAlgorithmAgent", this);
      scoreboard  = LRUScoreboard::type_id::create("LRUScoreboard", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
     	agent.agentPort.connect(scoreboard.collectedItemExport); 
    endfunction : connect_phase

  endclass : LRUEnvironment

  //Test
  class LRUTest extends uvm_test;
    
    `uvm_component_utils(LRUTest)

    LRUEnvironment environment;
    ReplacementAlgorithmSequence#(NUMBER_OF_CACHE_LINES) seq;

    function new(string name = "LRUTest", uvm_component parent = null);
      super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      environment = LRUEnvironment::type_id::create("environment", this);
      seq         = ReplacementAlgorithmSequence#(NUMBER_OF_CACHE_LINES)::type_id::create("seq");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      seq.start(environment.agent.sequencer);
      phase.drop_objection(this);
    endtask : run_phase

  endclass : LRUTest

endpackage : lruVerification
