package baseTestPackage;
	
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import types::*;

	//base transaction, drive method is to be implemented so that transaction can drive interface in driver run phase
	class BaseCacheAccessTransaction#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2
	) extends uvm_sequence_item;

		`uvm_object_utils(BaseCacheAccessTransaction#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		function new(string name = "BaseCacheAccessTransaction");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
		endfunction : myRandomize

		virtual task drive(
			virtual TestInterface#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) testInterface
		);
		endtask : drive
	endclass : BaseCacheAccessTransaction

	//Sequence
	//extended sequences must implement createTransaction method
	class BaseCacheAccessSequence#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2,
		int SEQUENCE_COUNT    = 50
	) extends uvm_sequence#(
		BaseCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		)
	);
		
		`uvm_object_utils(BaseCacheAccessSequence#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .SEQUENCE_COUNT(SEQUENCE_COUNT)))

		function new(string name = "BaseCacheAccessSequence");
			super.new(.name(name));
		endfunction : new

		virtual function BaseCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createTransaction();
			return BaseCacheAccessTransaction#( .ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("transaction"));
		endfunction : createTransaction;
		
		task body();
			BaseCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) transaction = this.createTransaction();
				
			repeat (SEQUENCE_COUNT) begin
				start_item(transaction);
					transaction.myRandomize();
				finish_item(transaction);
			end
		endtask : body
	endclass : BaseCacheAccessSequence

	//Driver
	class BaseCacheAccessDriver#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2
	) extends uvm_driver#(
		BaseCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		)
	);
		
		`uvm_component_utils(BaseCacheAccessDriver#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		protected virtual TestInterface#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testInterface;

		function new(string name = "BaseCacheAccessDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
						.ADDRESS_WITDH(ADDRESS_WITDH),
						.DATA_WIDTH(DATA_WIDTH),
						.TAG_WIDTH(TAG_WIDTH),
						.INDEX_WIDTH(INDEX_WIDTH),
						.OFFSET_WIDTH(OFFSET_WIDTH),
						.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
					))::get(this, "", "TestInterface", testInterface)) begin
				
				`uvm_fatal("NO VIRTUAL INTERFACE", {"Virtual interface must be set for : ", get_full_name(), ".vif"})
			end
		
		endfunction : build_phase
		
		virtual task run_phase(uvm_phase phase);
			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
			forever begin
				seq_item_port.get_next_item(req);
				req.drive(.testInterface(testInterface));
				seq_item_port.item_done();
			end
		endtask : run_phase
	endclass : BaseCacheAccessDriver

	//BaseCollectedTransaction
	//Collected transaction class, this class represents collected data and its duty is to update scoreboard model
	class BaseCollectedCacheAccessTransaction#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2
	);

		virtual task collect(
			virtual TestInterface#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) testInterface
		);
		endtask : collect
	endclass : BaseCollectedCacheAccessTransaction

	//Monitor
	class BaseCacheAccessMonitor#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2
	) extends uvm_monitor;
		
		`uvm_component_utils(BaseCacheAccessMonitor#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		uvm_analysis_port#(
			BaseCollectedCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) analysisPort;

		BaseCollectedCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) transaction;
		
		protected virtual TestInterface#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testInterface;

		function new(string name = "BaseCacheAccessMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function BaseCollectedCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createTransaction();
			BaseCollectedCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) newTransaction = new();
			return newTransaction;
		endfunction : createTransaction;

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
						.ADDRESS_WITDH(ADDRESS_WITDH),
						.DATA_WIDTH(DATA_WIDTH),
						.TAG_WIDTH(TAG_WIDTH),
						.INDEX_WIDTH(INDEX_WIDTH),
						.OFFSET_WIDTH(OFFSET_WIDTH),
						.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
					))::get(this, "", "TestInterface", testInterface)) begin
				
				`uvm_fatal("NO VIRTUAL INTERFACE", {"Virtual interface must be set for : ", get_full_name(), ".vif"})
			end
		
			transaction  = this.createTransaction();
			analysisPort = new (.name("analysisPort"), .parent(this));
		endfunction : build_phase
		
		virtual task run_phase(uvm_phase phase);
			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
			forever begin
				transaction.collect(.testInterface(testInterface));
				analysisPort.write(transaction);
			end
		endtask : run_phase
	endclass : BaseCacheAccessMonitor

	//Agent
	class BaseCacheAccessAgent#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2
	)	extends uvm_agent;
		
		`uvm_component_utils(BaseCacheAccessAgent#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		uvm_analysis_port#(
			BaseCollectedCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) analysisPort;

		uvm_sequencer#(
			BaseCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) sequencer;

		BaseCacheAccessDriver#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) driver;

		BaseCacheAccessMonitor#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) monitor;

		function new(string name = "BaseCacheAccessAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function uvm_sequencer#(
			BaseCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) createSequencer();
			return uvm_sequencer#(
				BaseCacheAccessTransaction#(
					.ADDRESS_WITDH(ADDRESS_WITDH),
					.DATA_WIDTH(DATA_WIDTH),
					.TAG_WIDTH(TAG_WIDTH),
					.INDEX_WIDTH(INDEX_WIDTH),
					.OFFSET_WIDTH(OFFSET_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
				)
			)::type_id::create(.name("sequencer"), .parent(this));
		endfunction : createSequencer

		virtual function BaseCacheAccessMonitor#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createMonitor();
			return BaseCacheAccessMonitor#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("monitor"), .parent(this));
		endfunction : createMonitor

		virtual function BaseCacheAccessDriver#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createDriver();
			return BaseCacheAccessDriver#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("driver"), .parent(this));
		endfunction : createDriver

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort = new(.name("analysisPort"), .parent(this));
			sequencer    = this.createSequencer();
			driver       = this.createDriver();
			monitor      = this.createMonitor();
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase
	endclass : BaseCacheAccessAgent

	//Scoreboard
	class BaseCacheAccessScoreboard#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2
	)	extends uvm_scoreboard;
		
		`uvm_component_utils(BaseCacheAccessScoreboard#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		uvm_analysis_export#(
			BaseCollectedCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) analysisExport;

		uvm_tlm_analysis_fifo#(
			BaseCollectedCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) analysisFifo;

		BaseCollectedCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) transaction;

		function new(string name = "BaseCacheAccessScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisExport = new(.name("analysisPort"), .parent(this));
			transaction  = new();
			
			analysisFifo = new(.name("analysisFifo"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			analysisExport.connect(analysisFifo.analysis_export);
		endfunction : connect_phase

		virtual function void compare(
			BaseCollectedCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) transaction
		);
		endfunction : compare 
		
		virtual task run();
			forever begin
				analysisFifo.get(transaction);
				this.compare(.transaction(transaction));
			end
		endtask : run
	endclass : BaseCacheAccessScoreboard

	class BaseCacheAccessEnvironment#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 6,
		int INDEX_WIDTH       = 6,
		int OFFSET_WIDTH      = 4,
		int SET_ASSOCIATIVITY = 2
	) extends uvm_env;
		
		`uvm_component_utils(BaseCacheAccessEnvironment#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		BaseCacheAccessAgent#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) agent;

		BaseCacheAccessScoreboard#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) scoreboard;

		function new(string name = "BaseCacheAccessEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function BaseCacheAccessScoreboard#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createScoreboard();
			return BaseCacheAccessScoreboard#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : createScoreboard

		virtual function BaseCacheAccessAgent#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createAgent();
			return BaseCacheAccessAgent#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("agent"), .parent(this));
		endfunction : createAgent

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			agent      = this.createAgent();
			scoreboard = this.createScoreboard();
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			agent.analysisPort.connect(scoreboard.analysisExport);
		endfunction : connect_phase
	endclass : BaseCacheAccessEnvironment
endpackage : baseTestPackage
