package replacementAlgorithmVerification;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  //Sequence item definition
  class ReplacementAlgorithmSequenceItem #(
    int NUMBER_OF_CACHE_LINES = 4,
    int COUNTER_WIDTH = NUMBER_OF_CACHE_LINES == 4  ? 2 :
                        NUMBER_OF_CACHE_LINES == 8  ? 3 :
                        NUMBER_OF_CACHE_LINES == 16 ? 4 : 
                        NUMBER_OF_CACHE_LINES == 32 ? 5 : 
                        NUMBER_OF_CACHE_LINES == 64 ? 6 : 7 
  ) extends uvm_sequence_item;

    rand bit[COUNTER_WIDTH - 1 : 0] lastAccessedCacheLine, replacementCacheLine;

    `uvm_object_utils_begin(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES))
      `uvm_field_int(lastAccessedCacheLine, UVM_ALL_ON)
      `uvm_field_int(replacementCacheLine, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "ReplacementAlgorithmSequenceItem");
      super.new(name);
    endfunction : new

    function void myRandomize();
      lastAccessedCacheLine = $urandom();
    endfunction : myRandomize

  endclass : ReplacementAlgorithmSequenceItem 

  //Sequencer
  class ReplacementAlgorithmSequencer #(
    int NUMBER_OF_CACHE_LINES = 4
  ) extends uvm_sequencer#(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES));

    `uvm_sequencer_utils(ReplacementAlgorithmSequencer#(NUMBER_OF_CACHE_LINES))

    function new(string name = "ReplacementAlgorithmSequencer", uvm_component parent);
      super.new(name, parent);
    endfunction : new

  endclass : ReplacementAlgorithmSequencer

  //Sequence
  class ReplacementAlgorithmSequence #(
    int NUMBER_OF_CACHE_LINES = 4
  ) extends uvm_sequence#(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES));

    `uvm_object_utils(ReplacementAlgorithmSequence#(NUMBER_OF_CACHE_LINES))

    function new(string name = "ReplacementAlgorithmSequence");
      super.new(name);
    endfunction : new

    virtual task body();
      repeat(500) begin
        req = ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES)::type_id::create("request");
        wait_for_grant();
        req.myRandomize();
        send_request(req);
        wait_for_item_done();
        //get_response(rsp);
      end
    endtask : body

  endclass : ReplacementAlgorithmSequence

  //Driver
  class ReplacementAlgorithmDriver #(
    int NUMBER_OF_CACHE_LINES = 4
  ) extends uvm_driver#(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES));

    virtual TestInterface#(NUMBER_OF_CACHE_LINES) testInterface;
    
    `uvm_component_utils(ReplacementAlgorithmDriver#(NUMBER_OF_CACHE_LINES))

    function new(string name = "ReplacementAlgorithmDriver", uvm_component parent);
      super.new(name, parent); 
    endfunction : new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual TestInterface#(NUMBER_OF_CACHE_LINES))::get(this, "", "TestInterface", testInterface)) begin
        `uvm_fatal("NO VIRTUAL INTERFACE", {"VIRTUAL INTERFACE MUST BE SET FOR: ", get_full_name(), ".vif"});
      end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
			testInterface.replacementAlgorithmInterface.reset = 1;
			@(posedge testInterface.clock);
			testInterface.replacementAlgorithmInterface.reset = 0;
			@(posedge testInterface.clock);
      forever begin
        seq_item_port.get_next_item(req);
        drive();
        seq_item_port.item_done();
      end
    endtask : run_phase

    virtual task drive();
      testInterface.replacementAlgorithmInterface.lastAccessedCacheLine <= req.lastAccessedCacheLine;
      testInterface.replacementAlgorithmInterface.enable <= 1;
      @(posedge testInterface.clock);
      @(posedge testInterface.clock);
			testInterface.replacementAlgorithmInterface.enable = 0;
			@(posedge testInterface.clock);
      @(posedge testInterface.clock);
    endtask : drive
  endclass : ReplacementAlgorithmDriver

  //Monitor
  class ReplacementAlgorithmMonitor #(
    int NUMBER_OF_CACHE_LINES = 4
  ) extends uvm_monitor;
    
    virtual TestInterface#(NUMBER_OF_CACHE_LINES) testInterface;

    uvm_analysis_port#(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES)) collectedItemPort;

    ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES) collectedTransaction;

    `uvm_component_utils(ReplacementAlgorithmMonitor#(NUMBER_OF_CACHE_LINES))
    
    function new(string name = "ReplacementAlgorithmMonitor", uvm_component parent);
      super.new(name, parent);
      collectedTransaction = new();
      collectedItemPort = new("collectedItemPort", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual TestInterface#(NUMBER_OF_CACHE_LINES))::get(this, "", "TestInterface", testInterface)) begin
        `uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
      end
    endfunction : build_phase
    
    virtual task run_phase(uvm_phase phase);
      forever begin
				if (testInterface.replacementAlgorithmInterface.enable == 1) begin
					collectedTransaction.lastAccessedCacheLine  = testInterface.replacementAlgorithmInterface.lastAccessedCacheLine;
					@(posedge testInterface.clock);
					@(posedge testInterface.clock);
					collectedTransaction.replacementCacheLine   = testInterface.replacementAlgorithmInterface.replacementCacheLine;
					collectedItemPort.write(collectedTransaction);
				end
				
				@(posedge testInterface.clock);
      end   
    endtask : run_phase

  endclass : ReplacementAlgorithmMonitor

  //Agent
  class ReplacementAlgorithmAgent #(
    int NUMBER_OF_CACHE_LINES = 4
  ) extends uvm_agent;
    
		uvm_analysis_port#(ReplacementAlgorithmSequenceItem#(NUMBER_OF_CACHE_LINES)) agentPort;
    ReplacementAlgorithmDriver#(NUMBER_OF_CACHE_LINES) driver;
    ReplacementAlgorithmSequencer#(NUMBER_OF_CACHE_LINES) sequencer;
    ReplacementAlgorithmMonitor#(NUMBER_OF_CACHE_LINES) monitor;

    `uvm_component_utils(ReplacementAlgorithmAgent#(NUMBER_OF_CACHE_LINES))

    function new(string name = "ReplacementAlgorithmAgent", uvm_component parent);
      super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

			agentPort = new(.name("agentPort"), .parent(this));

      driver    = ReplacementAlgorithmDriver#(NUMBER_OF_CACHE_LINES)::type_id::create("ReplacementAlgorithmDriver", this);
      sequencer = ReplacementAlgorithmSequencer#(NUMBER_OF_CACHE_LINES)::type_id::create("ReplacementAlgorithmSequencer", this);
      monitor   = ReplacementAlgorithmMonitor#(NUMBER_OF_CACHE_LINES)::type_id::create("ReplacementAlgorithmMonitor", this);

    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.collectedItemPort.connect(agentPort);
    endfunction : connect_phase

  endclass : ReplacementAlgorithmAgent

endpackage : replacementAlgorithmVerification


