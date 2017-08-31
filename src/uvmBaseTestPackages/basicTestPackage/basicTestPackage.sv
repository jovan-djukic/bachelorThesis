package basicTestPackage;
	
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//basi sequence item 
	class BasicSequenceItem extends uvm_sequence_item;
		`uvm_object_utils(BasicSequenceItem)

		function new(string name = "BasicSequenceItem");
			super.new(.name(name));
		endfunction : new

		virtual function void myRandomize();
			`uvm_info("BasicSequenceItem", "myRandomize stub", UVM_LOW)
		endfunction : myRandomize
	endclass : BasicSequenceItem

	//basic sequence
	class BasicSequence#(
		int SEQUENCE_ITEM_COUNT = 50
	) extends uvm_sequence#(BasicSequenceItem);
		`uvm_object_utils(BasicSequence#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)))

		function new(string name = "BasicSequence");
			super.new(.name(name));
		endfunction : new

		virtual task body();
			BasicSequenceItem basicSequenceItem = BasicSequenceItem::type_id::create(.name("basicSequenceItem"));

			repeat (SEQUENCE_ITEM_COUNT) begin
				start_item(basicSequenceItem);
					basicSequenceItem.myRandomize();
				finish_item(basicSequenceItem);
			end
		endtask :body
	endclass : BasicSequence

	//basic sequencer
	typedef uvm_sequencer#(BasicSequenceItem) BasicSequencer;

	//basic driver
	class BasicDriver extends uvm_driver#(BasicSequenceItem);
		`uvm_component_utils(BasicDriver)

		function new(string name = "BasicDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual task run_phase(uvm_phase phase);
			resetDUT();
			forever begin
				seq_item_port.get_next_item(req);
				drive();
				seq_item_port.item_done();
			end
		endtask : run_phase

		virtual task resetDUT();
			`uvm_info("BasicDriver", "resetDUT method stub", UVM_LOW)
		endtask : resetDUT

		virtual task drive();
			`uvm_info("BasicDriver", "drive method stub", UVM_LOW)
		endtask : drive
	endclass : BasicDriver

	//basic collect item
	class BasicCollectedItem extends uvm_object;
		`uvm_object_utils(BasicCollectedItem)

		function new(string name = "BasicCollectedItem");
			super.new(.name(name));
		endfunction : new
	endclass : BasicCollectedItem

	//basic monitor
	class BasicMonitor extends uvm_monitor;
		`uvm_component_utils(BasicMonitor)

		uvm_analysis_port#(BasicCollectedItem) analysisPort;
	
		protected BasicCollectedItem basicCollectedItem;

		function new(string name = "BasicMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort       = new(.name("analysisPort"), .parent(this));
			basicCollectedItem = BasicCollectedItem::type_id::create(.name("basicCollectedItem"));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			resetDUT();
			forever begin
				collect();
				analysisPort.write(basicCollectedItem);
			end
		endtask : run_phase

		virtual task resetDUT();
			`uvm_info("BasicDriver", "resetDUT method stub", UVM_LOW)
		endtask : resetDUT

		virtual task collect();
			`uvm_info("BasicMonitor", "collect method stub", UVM_LOW);
		endtask : collect
	endclass : BasicMonitor

	//basic agent
	class BasicAgent extends uvm_agent;
		`uvm_component_utils(BasicAgent)

		uvm_analysis_port#(BasicCollectedItem) analysisPort;

		BasicSequencer sequencer;
		BasicDriver driver;
		BasicMonitor monitor;

		function new(string name = "BasicAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new
		
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort = new(.name("analysisPort"), .parent(this));
			sequencer    = BasicSequencer::type_id::create(.name("sequencer"), .parent(this));
			driver       = BasicDriver::type_id::create(.name("driver"), .parent(this));
			monitor      = BasicMonitor::type_id::create(.name("monitor"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));
			
			driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase
	endclass : BasicAgent

	//basic scoreboard
	class BasicScoreboard extends uvm_scoreboard;
		`uvm_component_utils(BasicScoreboard)
		
		uvm_analysis_export#(BasicCollectedItem) analysisExport;
		
		uvm_tlm_analysis_fifo#(BasicCollectedItem) analysisFifo;
		
		BasicCollectedItem collectedItem;

		function new(string name = "BasicScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));
			
			analysisExport = new(.name("analysisExport"), .parent(this));
			analysisFifo   = new(.name("analysisFifo"), .parent(this));
			collectedItem  = BasicCollectedItem::type_id::create(.name("collectedItem"));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			analysisExport.connect(analysisFifo.analysis_export);
		endfunction : connect_phase

		virtual task run();
			forever begin
				analysisFifo.get(collectedItem);
				checkBehaviour();
			end
		endtask : run

		virtual function void checkBehaviour();
			`uvm_info("BasicScoreboard", "checkBehaviour method stub", UVM_LOW)
		endfunction : checkBehaviour
	endclass : BasicScoreboard

	//basic environment
	class BasicEnvironment extends uvm_env;
		`uvm_component_utils(BasicEnvironment)

		BasicAgent agent;
		BasicScoreboard scoreboard;

		function new(string name = "BasicEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			agent      = BasicAgent::type_id::create(.name("agent"), .parent(this));
			scoreboard = BasicScoreboard::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			agent.analysisPort.connect(scoreboard.analysisExport);
		endfunction : connect_phase

	endclass : BasicEnvironment

	//basic test
	class BasicTest#(
		int SEQUENCE_ITEM_COUNT = 50
	) extends uvm_test;
		`uvm_component_utils(BasicTest#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)))

		BasicEnvironment environment;

		function new(string name = "BasicTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			`uvm_info("BasicTest", "customBuild method stub", UVM_LOW)
		endfunction : registerReplacements

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			this.registerReplacements();

			environment = BasicEnvironment::type_id::create(.name("environment"), .parent(this));
		endfunction : build_phase
		
		virtual function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(.phase(phase));

			this.print();
			factory.print();
		endfunction : end_of_elaboration_phase

		virtual task run_phase(uvm_phase phase);
			BasicSequence#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)) basicSequence = BasicSequence#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT))
																																							 ::type_id
																																							 ::create(.name("basicSequence"));
			phase.raise_objection(.obj(this));
				basicSequence.start(environment.agent.sequencer);
			phase.drop_objection(.obj(this));
		endtask : run_phase
	endclass : BasicTest
endpackage : basicTestPackage
