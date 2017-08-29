package baseTestPackage;
	
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import setAssociativeCacheUnitClassImplementationPackage::*;

	//BaseCacheAccessTransaction, this class is used for driving signals, drive method is overriden for the desidered behaviour
	class BaseCacheAccessTransaction#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 16,
		int INDEX_WIDTH       = 8,
		int OFFSET_WIDTH      = 8,
		int SET_ASSOCIATIVITY = 4
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
			`uvm_info("DRIVE_STUB", "Method drive not implemented", UVM_LOW)
		endtask : drive
	endclass : BaseCacheAccessTransaction

	//BaseCollectedCacheTransaction, this class represents collected data and it is used to update test model 
	class BaseCollectedCacheTransaction#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 16,
		int INDEX_WIDTH       = 8,
		int OFFSET_WIDTH      = 8,
		int SET_ASSOCIATIVITY = 4
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
			`uvm_info("COLLECT_STUB", "Method collect not implemented", UVM_LOW)
		endtask : collect
	endclass : BaseCollectedCacheTransaction
	
	//BaseTestModel, this class uses data form collected transactions and checks if the behaviour is correct
	class BaseTestModel#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 16,
		int INDEX_WIDTH       = 8,
		int OFFSET_WIDTH      = 8,
		int SET_ASSOCIATIVITY = 4
	);
		virtual function void compare(
			BaseCollectedCacheTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) transaction
		);
			`uvm_info("COLLECT_STUB", "Method collect not implemented", UVM_LOW)
		endfunction : compare 
	endclass : BaseTestModel
		
	//BaseTestItemFactory, this class instanciates transactions and model and is used in all other classes
	//to implement the desired behaviour we override create methods with our own
	class BaseTestItemFactory#(
		int ADDRESS_WITDH     = 32,
		int DATA_WIDTH        = 32,
		int TAG_WIDTH         = 16,
		int INDEX_WIDTH       = 8,
		int OFFSET_WIDTH      = 8,
		int SET_ASSOCIATIVITY = 4
	);
		virtual function BaseCacheAccessTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createCacheAccessTransaction();

			return BaseCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("cacheAccessTransaction"));

		endfunction : createCacheAccessTransaction

		virtual function BaseCollectedCacheTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createCollectedCacheTransaction();
			BaseCollectedCacheTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) collectedCacheTransaction = new();

			return collectedCacheTransaction;
		endfunction : createCollectedCacheTransaction

		virtual function BaseTestModel#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) createTestModel();

			BaseTestModel#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) testModel = new();

			return testModel;
		endfunction : createTestModel
	endclass : BaseTestItemFactory

	//all other classes retrieve this factory from uvm_config_db
	//Sequence
	//extended sequences must implement createTransaction method
	class BaseCacheAccessSequence#(
		int ADDRESS_WITDH        = 32,
		int DATA_WIDTH           = 32,
		int TAG_WIDTH            = 6,
		int INDEX_WIDTH          = 6,
		int OFFSET_WIDTH         = 4,
		int SET_ASSOCIATIVITY    = 2,
		string TEST_FACTORY_NAME = "TestFactory",
		int SEQUENCE_COUNT       = 50
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
		
		`uvm_object_utils(BaseCacheAccessSequence#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TEST_FACTORY_NAME(TEST_FACTORY_NAME), .SEQUENCE_COUNT(SEQUENCE_COUNT)))

		function new(string name = "BaseCacheAccessSequence");
			super.new(.name(name));
		endfunction : new

		task body();
			BaseTestItemFactory#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) testFactory; 				

			BaseCacheAccessTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) transaction; 				

			if (!uvm_config_db#(BaseTestItemFactory#(
					.ADDRESS_WITDH(ADDRESS_WITDH),
					.DATA_WIDTH(DATA_WIDTH),
					.TAG_WIDTH(TAG_WIDTH),
					.INDEX_WIDTH(INDEX_WIDTH),
					.OFFSET_WIDTH(OFFSET_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
				))::get(uvm_root::get(), "", TEST_FACTORY_NAME, testFactory)) begin
				
				`uvm_fatal("NO TEST FACTORY", "Test factory is not set");
			end

			transaction = testFactory.createCacheAccessTransaction();

			repeat (SEQUENCE_COUNT) begin
				start_item(transaction);
					transaction.myRandomize();
				finish_item(transaction);
			end
		endtask : body
	endclass : BaseCacheAccessSequence

	//Driver
	class BaseCacheAccessDriver#(
		int ADDRESS_WITDH          = 32,
		int DATA_WIDTH             = 32,
		int TAG_WIDTH              = 6,
		int INDEX_WIDTH            = 6,
		int OFFSET_WIDTH           = 4,
		int SET_ASSOCIATIVITY      = 2,
		string TEST_INTERFACE_NAME = "TestInterface"
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
		
		`uvm_component_utils(BaseCacheAccessDriver#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TEST_INTERFACE_NAME(TEST_INTERFACE_NAME)))

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
					))::get(this, "", TEST_INTERFACE_NAME, testInterface)) begin
				
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

	//Monitor
	class BaseCacheAccessMonitor#(
		int ADDRESS_WITDH          = 32,
		int DATA_WIDTH             = 32,
		int TAG_WIDTH              = 16,
		int INDEX_WIDTH            = 8,
		int OFFSET_WIDTH           = 8,
		int SET_ASSOCIATIVITY      = 4,
		string TEST_INTERFACE_NAME = "TestInterface",
		string TEST_FACTORY_NAME   = "TestFactory"
	) extends uvm_monitor;
		
		`uvm_component_utils(BaseCacheAccessMonitor#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TEST_INTERFACE_NAME(TEST_INTERFACE_NAME), .TEST_FACTORY_NAME(TEST_FACTORY_NAME)))

		uvm_analysis_port#(
			BaseCollectedCacheTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) analysisPort;

		BaseCollectedCacheTransaction#(
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

		BaseTestItemFactory#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testFactory; 				

		function new(string name = "BaseCacheAccessMonitor", uvm_component parent);
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
					))::get(this, "", TEST_INTERFACE_NAME, testInterface)) begin
				
				`uvm_fatal("NO VIRTUAL INTERFACE", {"Virtual interface must be set for : ", get_full_name(), ".vif"})
			end
		
			if (!uvm_config_db#(BaseTestItemFactory#(
					.ADDRESS_WITDH(ADDRESS_WITDH),
					.DATA_WIDTH(DATA_WIDTH),
					.TAG_WIDTH(TAG_WIDTH),
					.INDEX_WIDTH(INDEX_WIDTH),
					.OFFSET_WIDTH(OFFSET_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
				))::get(this, "", TEST_FACTORY_NAME, testFactory)) begin
				
				`uvm_fatal("NO TEST FACTORY", "Test factory is not set");
			end

			transaction  = testFactory.createCollectedCacheTransaction();
			analysisPort = new (.name("analysisPort"), .parent(this));
		endfunction : build_phase
		
		virtual task run_phase(uvm_phase phase);
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			forever begin
				transaction.collect(.testInterface(testInterface));
				analysisPort.write(transaction);
			end
		endtask : run_phase
	endclass : BaseCacheAccessMonitor

	//Agent
	class BaseCacheAccessAgent#(
		int ADDRESS_WITDH          = 32,
		int DATA_WIDTH             = 32,
		int TAG_WIDTH              = 6,
		int INDEX_WIDTH            = 6,
		int OFFSET_WIDTH           = 4,
		int SET_ASSOCIATIVITY      = 2,
		string TEST_INTERFACE_NAME = "TestInterface",
		string TEST_FACTORY_NAME   = "TestFactory"
	)	extends uvm_agent;
		
		`uvm_component_utils(BaseCacheAccessAgent#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TEST_INTERFACE_NAME(TEST_INTERFACE_NAME), .TEST_FACTORY_NAME(TEST_FACTORY_NAME)))

		uvm_analysis_port#(
			BaseCollectedCacheTransaction#(
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
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME)
		) driver;

		BaseCacheAccessMonitor#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
			.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
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
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
			.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
		) createMonitor();
			return BaseCacheAccessMonitor#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
			)::type_id::create(.name("monitor"), .parent(this));
		endfunction : createMonitor

		virtual function BaseCacheAccessDriver#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME)
		) createDriver();
			return BaseCacheAccessDriver#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME)
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
		int ADDRESS_WITDH        = 32,
		int DATA_WIDTH           = 32,
		int TAG_WIDTH            = 6,
		int INDEX_WIDTH          = 6,
		int OFFSET_WIDTH         = 4,
		int SET_ASSOCIATIVITY    = 2,
		string TEST_FACTORY_NAME = "TestFactory"
	)	extends uvm_scoreboard;
		
		`uvm_component_utils(BaseCacheAccessScoreboard#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TEST_FACTORY_NAME(TEST_FACTORY_NAME)))

		uvm_analysis_export#(
			BaseCollectedCacheTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) analysisExport;

		uvm_tlm_analysis_fifo#(
			BaseCollectedCacheTransaction#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)
		) analysisFifo;

		BaseCollectedCacheTransaction#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) transaction;

		BaseTestItemFactory#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testFactory; 				

		BaseTestModel#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testModel;

		function new(string name = "BaseCacheAccessScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(BaseTestItemFactory#(
					.ADDRESS_WITDH(ADDRESS_WITDH),
					.DATA_WIDTH(DATA_WIDTH),
					.TAG_WIDTH(TAG_WIDTH),
					.INDEX_WIDTH(INDEX_WIDTH),
					.OFFSET_WIDTH(OFFSET_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
				))::get(this, "", TEST_FACTORY_NAME, testFactory)) begin
				
				`uvm_fatal("NO TEST FACTORY", "Test factory is not set");
			end

			analysisExport = new(.name("analysisPort"), .parent(this));
			transaction    = testFactory.createCollectedCacheTransaction();
			testModel      = testFactory.createTestModel();
			
			analysisFifo = new(.name("analysisFifo"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			analysisExport.connect(analysisFifo.analysis_export);
		endfunction : connect_phase

		virtual task run();
			forever begin
				analysisFifo.get(transaction);
				testModel.compare(.transaction(transaction));
			end
		endtask : run
	endclass : BaseCacheAccessScoreboard

	class BaseCacheAccessEnvironment#(
		int ADDRESS_WITDH          = 32,
		int DATA_WIDTH             = 32,
		int TAG_WIDTH              = 6,
		int INDEX_WIDTH            = 6,
		int OFFSET_WIDTH           = 4,
		int SET_ASSOCIATIVITY      = 2,
		string TEST_INTERFACE_NAME = "TestInterface",
		string TEST_FACTORY_NAME   = "TestFactory"
	) extends uvm_env;
		
		`uvm_component_utils(BaseCacheAccessEnvironment#(.ADDRESS_WITDH(ADDRESS_WITDH), .DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TEST_INTERFACE_NAME(TEST_INTERFACE_NAME), .TEST_FACTORY_NAME(TEST_FACTORY_NAME)))

		BaseCacheAccessAgent#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
			.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
		) agent;

		BaseCacheAccessScoreboard#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
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
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
		) createScoreboard();
			return BaseCacheAccessScoreboard#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
			)::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : createScoreboard

		virtual function BaseCacheAccessAgent#(
			.ADDRESS_WITDH(ADDRESS_WITDH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
			.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
		) createAgent();
			return BaseCacheAccessAgent#(
				.ADDRESS_WITDH(ADDRESS_WITDH),
				.DATA_WIDTH(DATA_WIDTH),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.TEST_INTERFACE_NAME(TEST_INTERFACE_NAME),
				.TEST_FACTORY_NAME(TEST_FACTORY_NAME)
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
