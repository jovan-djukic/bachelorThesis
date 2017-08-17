package setAssociativeLRUEnvironmentPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	class SetAssociativeLRUTransaction#(
		int INDEX_WIDTH				= 6,
		int SET_ASSOCIATIVITY	= 2	
	) extends uvm_sequence_item;
		
		//index tells us which set it is, or rather whic lru to use
		bit[INDEX_WIDTH - 1 : 0] 			 index;
		//there are lines per lru as much as there are smaller caches
		bit[SET_ASSOCIATIVITY - 1 : 0] lastAccessedLine, replacementLine;
		bit														 isAccess;
		
		`uvm_object_utils_begin(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))
			`uvm_field_int(index, UVM_ALL_ON)
			`uvm_field_int(lastAccessedLine, UVM_ALL_ON)
			`uvm_field_int(isAccess, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SetAssociativeLRUTransaction");
			super.new(.name(name));
		endfunction : new

		virtual function void myRandomize();
			index            = $urandom();
			lastAccessedLine = $urandom();
			isAccess         = $urandom();
		endfunction : myRandomize

	endclass :SetAssociativeLRUTransaction

	class SetAssociativeLRUSequence#(
		int INDEX_WIDTH				= 6,
		int SET_ASSOCIATIVITY	= 2,
		int SEQUENCE_COUNT		= 10	
	) extends uvm_sequence#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)));
	
		`uvm_object_utils(SetAssociativeLRUSequence#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .SEQUENCE_COUNT(SEQUENCE_COUNT)))

		function new(string name = "SetAssociativeLRUSequence");
			super.new(.name(name));
		endfunction : new

		virtual task body();
			SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) transaction;
			
			repeat (SEQUENCE_COUNT) begin
				transaction = SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))::type_id::create(.name("transaction"));

				start_item(transaction);
					transaction.myRandomize();
				finish_item(transaction);
			end	

		endtask : body

	endclass : SetAssociativeLRUSequence

	class SetAssociativeLRUDriver#(
		int INDEX_WIDTH				= 6,
		int SET_ASSOCIATIVITY	= 2
	) extends uvm_driver#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)));
		
		`uvm_component_utils(SetAssociativeLRUDriver#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		protected virtual TestInterface#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) testInterface;

		function new(string name = "SetAssociativeLRUDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))::get(this, "", "TestInterface", testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			//restart module
			testInterface.reset = 1;
			repeat(2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;

			forever begin
				seq_item_port.get_next_item(req);
				drive();
				seq_item_port.item_done();
			end
		endtask : run_phase

		virtual task drive();
				testInterface.indexIn                                             = req.index;
				testInterface.replacementAlgorithmInterface.lastAccessedCacheLine = req.lastAccessedLine;
				testInterface.replacementAlgorithmInterface.accessEnable          = req.isAccess;
				testInterface.replacementAlgorithmInterface.invalidateEnable      = ~req.isAccess;

				//wait for write to sync in
				repeat (2) begin
					@(posedge testInterface.clock);
				end

				//wait for monitor to collect data
				@(posedge testInterface.clock);

		endtask : drive

	endclass : SetAssociativeLRUDriver
	
	class SetAssociativeLRUMonitor#(
		int INDEX_WIDTH				= 6,
		int SET_ASSOCIATIVITY	= 2
	) extends uvm_monitor;
		
		`uvm_component_utils(SetAssociativeLRUMonitor#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		uvm_analysis_port#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) analysisPort;

		protected virtual TestInterface#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) testInterface;

		function new(string name = "SetAssociativeLRUMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))::get(this, "", "TestInterface", testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end

			analysisPort = new(.name("analysisPort"), .parent(this));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) transaction;
			transaction = SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))::type_id::create(.name("transaction"));
			//restart module
			repeat(2) begin
				@(posedge testInterface.clock);
			end

			forever begin
				//wait for write to sync in
				repeat (2) begin
					@(posedge testInterface.clock);
				end

				//colect data
				transaction.lastAccessedLine = testInterface.replacementAlgorithmInterface.lastAccessedCacheLine;
				transaction.replacementLine  = testInterface.replacementAlgorithmInterface.replacementCacheLine;
				transaction.index            = testInterface.indexIn;
				transaction.isAccess         = testInterface.replacementAlgorithmInterface.accessEnable;

				//write data
				analysisPort.write(transaction);
				@(posedge testInterface.clock);
			end
		endtask : run_phase

	endclass : SetAssociativeLRUMonitor

	class SetAssociativeLRUAgent#(
		int INDEX_WIDTH				= 6,
		int SET_ASSOCIATIVITY	= 2
	) extends uvm_agent;

		`uvm_component_utils(SetAssociativeLRUAgent#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		uvm_analysis_port#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) analysisPort;

		uvm_sequencer#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) sequencer;
		SetAssociativeLRUDriver#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) driver;
		SetAssociativeLRUMonitor#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) monitor;

		function new(string name = "SetAssociativeLRUAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort = new(.name("analysisPort"), .parent(this));

			sequencer = uvm_sequencer#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))::type_id::create(.name("sequencer"), .parent(this));
			driver    = SetAssociativeLRUDriver#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))::type_id::create(.name("driver"), .parent(this));
			monitor   = SetAssociativeLRUMonitor#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))::type_id::create(.name("monitor"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase

	endclass : SetAssociativeLRUAgent
	
	class SetAssociativeLRUScoreboard#(
		int INDEX_WIDTH       = 4,
		int SET_ASSOCIATIVITY = 2
	) extends uvm_scoreboard;
		
		`uvm_component_utils(SetAssociativeLRUScoreboard#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		uvm_analysis_export#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) analysisExport;

		uvm_tlm_analysis_fifo#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) analysisFifo;

		SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) transaction;

		//data needed for checking lru
		localparam NUMBER_OF_CACHE_LINES = 1 << SET_ASSOCIATIVITY;
		localparam NUMBER_OF_LRUS        = 1 << INDEX_WIDTH;

		logic[SET_ASSOCIATIVITY - 1 : 0] lrus[NUMBER_OF_LRUS][NUMBER_OF_CACHE_LINES];

		function new(string name = "SetAssociativeLRUScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));

			transaction = new(.name("transaction"));
			
			for (int i = 0; i < NUMBER_OF_LRUS; i++) begin
				for (int j = 0; j < NUMBER_OF_CACHE_LINES; j++) begin
					lrus[i][j] = j;
				end
			end
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisExport = new(.name("analysisExpor"), .parent(this));

			analysisFifo = new(.name("analysisFifo"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			analysisExport.connect(analysisFifo.analysis_export);
		endfunction : connect_phase

		virtual task run();
			forever begin
				analysisFifo.get(transaction);
				check();
			end
		endtask : run

		virtual function void check();
			//helper variables
			int index            = transaction.index;
			int lastAccessedLine = transaction.lastAccessedLine;
			int replacementLine  = transaction.replacementLine;

			if (transaction.isAccess == 1) begin
				for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
					if (i != lastAccessedLine && lrus[index][i] < lrus[index][lastAccessedLine]) begin
						lrus[index][i]++;
					end		
				end

				lrus[index][lastAccessedLine] = 0;
			end else begin
				for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
					if (i != lastAccessedLine && lrus[index][i] > lrus[index][lastAccessedLine]) begin
						lrus[index][i]--;
					end		
				end

				lrus[index][lastAccessedLine] = NUMBER_OF_CACHE_LINES - 1;
			end

			//find replacement and compare
			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				if (lrus[index][i] == (NUMBER_OF_CACHE_LINES - 1)) begin
					if (i != replacementLine) begin
						`uvm_info("SCOREBOARD::ERROR", $sformatf("\nINDEX=%d, EXPECTED_LINE=%d, LRU_LINE=%d, IS_ACCESS=%d", index, i, replacementLine, transaction.isAccess), UVM_LOW)
					end else begin
						`uvm_info("SCOREBOARD::OK", $sformatf("\nINDEX=%d, EXPECTED_LINE=%d, LRU_LINE=%d, IS_ACCESS=%d", index, i, replacementLine, transaction.isAccess), UVM_LOW)
					end
				end 
			end
		endfunction : check

	endclass : SetAssociativeLRUScoreboard

	class SetAssociativeLRUEnvironment#(
		int INDEX_WIDTH       = 6,
		int SET_ASSOCIATIVITY = 2
	) extends uvm_env;
		
		`uvm_component_utils(SetAssociativeLRUEnvironment#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		SetAssociativeLRUAgent#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) agent;
		SetAssociativeLRUScoreboard#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) scoreboard;

		function new(string name = "SetAssociativeLRUEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			agent      = SetAssociativeLRUAgent#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))::type_id::create(.name("agent"), .parent(this));
			scoreboard = SetAssociativeLRUScoreboard#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			agent.analysisPort.connect(scoreboard.analysisExport);
		endfunction : connect_phase

	endclass : SetAssociativeLRUEnvironment

endpackage : setAssociativeLRUEnvironmentPackage
