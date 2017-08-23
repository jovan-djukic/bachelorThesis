package setAssociativeCacheEnvirnomentPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//Transaction
	class CacheAccessTransaction#(
		int TAG_WIDTH                          = 6,
		int INDEX_WIDTH                        = 6,
		int OFFSET_WIDTH                       = 4,
		int SET_ASSOCIATIVITY                  = 2,
		int DATA_WIDTH                         = 16,
		type STATE_TYPE                        = logic[1 : 0],
		int STATE_SET_LENGTH                   = 3,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {1, 2, 3}
	) extends uvm_sequence_item;
		
		logic[INDEX_WIDTH - 1       : 0] cpuIndex;
		logic[TAG_WIDTH - 1         : 0] cpuTagIn, cpuTagOut;
		logic[DATA_WIDTH - 1        : 0] cpuDataIn, cpuDataOut;
		logic[SET_ASSOCIATIVITY - 1 : 0] cpuCacheNumber;
		STATE_TYPE                  		 cpuStateIn, cpuStateOut;
		logic                       		 cpuHit;

		//snoopy controller ports
		logic[INDEX_WIDTH - 1       : 0] snoopyIndex;
		logic[TAG_WIDTH - 1         : 0] snoopyTagIn;
		logic[DATA_WIDTH - 1        : 0] snoopyDataOut;
		logic[SET_ASSOCIATIVITY - 1 : 0] snoopyCacheNumber;
		STATE_TYPE                  		 snoopyStateIn, snoopyStateOut;
		logic                       		 snoopyHit, isInvalidated;
		
		`uvm_object_utils_begin(CacheAccessTransaction#(.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .DATA_WIDTH(DATA_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET)))	
			//cpu fields
			`uvm_field_int(cpuIndex, UVM_ALL_ON)
			`uvm_field_int(cpuTagIn, UVM_ALL_ON)
			`uvm_field_int(cpuTagOut, UVM_ALL_ON)
			`uvm_field_int(cpuDataIn, UVM_ALL_ON)
			`uvm_field_int(cpuDataOut, UVM_ALL_ON)
			`uvm_field_int(cpuCacheNumber, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cpuStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cpuStateOut, UVM_ALL_ON)
			`uvm_field_int(cpuHit, UVM_ALL_ON)

			//snoopy fields
			`uvm_field_int(snoopyIndex, UVM_ALL_ON)
			`uvm_field_int(snoopyTagIn, UVM_ALL_ON)
			`uvm_field_int(snoopyDataOut, UVM_ALL_ON)
			`uvm_field_int(snoopyCacheNumber, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateOut, UVM_ALL_ON)
			`uvm_field_int(snoopyHit, UVM_ALL_ON)
			`uvm_field_int(isInvalidated, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "CacheAccessTransaction");
			super.new(.name(name));
		endfunction : new		

		function void myRandomize();
			//cpu randomized data
			cpuIndex   = $urandom();
			cpuTagIn   = $urandom();
			cpuDataIn  = $urandom();
			cpuStateIn = STATE_SET[$urandom() % STATE_SET_LENGTH];

			//snoopy randomized data
			snoopyIndex   = cpuIndex; 
			snoopyTagIn   = cpuTagIn;
			snoopyStateIn = STATE_SET[$urandom() % STATE_SET_LENGTH];
		endfunction : myRandomize

	endclass : CacheAccessTransaction

	//Sequence
	class CacheAccessSequence#(
		int TAG_WIDTH                          = 6,
		int INDEX_WIDTH                        = 6,
		int OFFSET_WIDTH                       = 4,
		int DATA_WIDTH                         = 16,
		int SET_ASSOCIATIVITY                  = 2,
		type STATE_TYPE                        = logic[1 : 0],
		int STATE_SET_LENGTH                   = 3,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {1, 2, 3},
		int SEQUENCE_COUNT                     = 50
	) extends uvm_sequence#(
		CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		)
	);
		
		`uvm_object_utils(CacheAccessSequence#(.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .DATA_WIDTH(DATA_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .SEQUENCE_COUNT(SEQUENCE_COUNT)))

		function new(string name = "CacheAccessSequence");
			super.new(.name(name));
		endfunction : new

		virtual task body();
			CacheAccessTransaction#(
				.TAG_WIDTH(TAG_WIDTH), 
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET)
			) transaction;

			repeat (SEQUENCE_COUNT) begin
				transaction = CacheAccessTransaction#(
					.TAG_WIDTH(TAG_WIDTH), 
					.INDEX_WIDTH(INDEX_WIDTH),
					.OFFSET_WIDTH(OFFSET_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
					.DATA_WIDTH(DATA_WIDTH),
					.STATE_TYPE(STATE_TYPE),
					.STATE_SET_LENGTH(STATE_SET_LENGTH),
					.STATE_SET(STATE_SET)
				)::type_id::create(.name("transaction"));

				start_item(transaction);
					transaction.myRandomize();
				finish_item(transaction);
			end
		endtask : body

	endclass : CacheAccessSequence

	//Driver
	class CacheAccessDriver#(
		int TAG_WIDTH                          = 6,
		int INDEX_WIDTH                        = 6,
		int OFFSET_WIDTH                       = 4,
		int SET_ASSOCIATIVITY                  = 2,
		int DATA_WIDTH                         = 16,
		type STATE_TYPE                        = logic[1 : 0],
		int STATE_SET_LENGTH                   = 3,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {1, 2, 3},
		STATE_TYPE INVALID_STATE               = 2'b0
	) extends uvm_driver#(
		CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		)
	);
		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		`uvm_component_utils(CacheAccessDriver#(.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .DATA_WIDTH(DATA_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .INVALID_STATE(INVALID_STATE)))

		protected virtual interface TestInterface#(
			.STATE_TYPE(STATE_TYPE),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.INVALID_STATE(INVALID_STATE)
		) testInterface;

		function new(string name = "CacheAccessDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual interface TestInterface#(
				.STATE_TYPE(STATE_TYPE),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.INVALID_STATE(INVALID_STATE)
			))::get(this, "", "TestInterface", testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"})
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
				drive();
				seq_item_port.item_done();
			end
		endtask : run_phase

		virtual task drive();
			//drive cpu controller signals
			testInterface.cacheInterface.cpuIndex   = req.cpuIndex;
			testInterface.cacheInterface.cpuOffset  = 0;
			testInterface.cacheInterface.cpuTagIn   = req.cpuTagIn;
			testInterface.cacheInterface.cpuStateIn = req.cpuStateIn;
			testInterface.cacheInterface.cpuDataIn  = req.cpuDataIn;

			//wait for data to sync in
			@(posedge testInterface.clock);

			//if not hit write data
			if (testInterface.cacheInterface.cpuHit == 0) begin
				testInterface.cacheInterface.cpuWriteTag   = 1;
				testInterface.cacheInterface.cpuWriteState = 1;
				testInterface.cacheInterface.cpuWriteData  = 1;

				for (int i = 0; i < NUMBER_OF_WORDS; i++) begin
					testInterface.cacheInterface.cpuOffset    = i;
					repeat (2) begin
						@(posedge testInterface.clock);
					end
				end	

				testInterface.cacheInterface.cpuWriteTag   = 0;
				testInterface.cacheInterface.cpuWriteState = 0;
				testInterface.cacheInterface.cpuWriteData  = 0;
			end

			testInterface.accessEnable = 1;
			@(posedge testInterface.clock);
			testInterface.accessEnable = 0;
			@(posedge testInterface.clock);

			//drive snoopy controller signals
			testInterface.cacheInterface.snoopyIndex   = req.snoopyIndex;
			testInterface.cacheInterface.snoopyTagIn   = req.snoopyTagIn;
			testInterface.cacheInterface.snoopyOffset  = 0;
			testInterface.cacheInterface.snoopyStateIn = req.snoopyStateIn;

			//wait for data to sync in
			@(posedge testInterface.clock);

			//change state if hit
			if (testInterface.cacheInterface.snoopyHit == 1) begin
				testInterface.cacheInterface.snoopyWriteState = 1;
				repeat (2) begin
					@(posedge testInterface.clock);
				end
				testInterface.cacheInterface.snoopyWriteState = 0;
			end

			//wait for monitor to collect data
			@(posedge testInterface.clock);

			//now invalidate sam block
			if (testInterface.cacheInterface.snoopyHit == 1) begin
				testInterface.cacheInterface.snoopyStateIn    = INVALID_STATE;
				testInterface.cacheInterface.snoopyWriteState = 1;
				testInterface.invalidateEnable                = 1;

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				testInterface.cacheInterface.snoopyWriteState = 0;
				testInterface.invalidateEnable                = 0;
			end

			//wait for monitor to collect data
			@(posedge testInterface.clock);
		endtask : drive

	endclass : CacheAccessDriver

	//Monitor
	class CacheAccessMonitor#(
		int TAG_WIDTH                          = 6,
		int INDEX_WIDTH                        = 6,
		int OFFSET_WIDTH                       = 4,
		int SET_ASSOCIATIVITY                  = 2,
		int DATA_WIDTH                         = 16,
		type STATE_TYPE                        = logic[1 : 0],
		int STATE_SET_LENGTH                   = 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {1, 2, 3},
		STATE_TYPE INVALID_STATE               = 2'b0
	) extends uvm_monitor;

		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		`uvm_component_utils(CacheAccessMonitor#(.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .DATA_WIDTH(DATA_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .INVALID_STATE(INVALID_STATE)))

		uvm_analysis_port#(CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		)) analysisPort;

		CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		) transaction;

		protected virtual interface TestInterface#(
			.STATE_TYPE(STATE_TYPE),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.INVALID_STATE(INVALID_STATE)
		) testInterface;

		function new(string name = "CacheAccessMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual interface TestInterface#(
				.STATE_TYPE(STATE_TYPE),
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.INVALID_STATE(INVALID_STATE)
			))::get(this, "", "TestInterface", testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"})
			end

			analysisPort = new(.name("analysisPort"), .parent(this));
			transaction  = new(.name("transaction"));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			repeat (2) begin
				@(posedge testInterface.clock);
			end

			forever begin
				collect();
			end
		endtask : run_phase

		virtual task collect();
			//wait for driver to drive cpu controller signals
			@(posedge testInterface.clock);
			
			//collect cpu controller signals
			transaction.cpuIndex   = testInterface.cacheInterface.cpuIndex;
			transaction.cpuTagIn   = testInterface.cacheInterface.cpuTagIn;
			transaction.cpuStateIn = testInterface.cacheInterface.cpuStateIn;
			transaction.cpuDataIn  = testInterface.cacheInterface.cpuDataIn;
			transaction.cpuHit     = testInterface.cacheInterface.cpuHit;

			//if not hit write data
			if (transaction.cpuHit == 0) begin
				for (int i = 0; i < NUMBER_OF_WORDS; i++) begin
					repeat (2) begin
						@(posedge testInterface.clock);
					end
				end	
			end

			@(posedge testInterface.clock);

			//collect output signals
			transaction.cpuTagOut      = testInterface.cacheInterface.cpuTagOut;
			transaction.cpuDataOut     = testInterface.cacheInterface.cpuDataOut;
			transaction.cpuStateOut    = testInterface.cacheInterface.cpuStateOut;
			transaction.cpuCacheNumber = testInterface.cacheInterface.cpuCacheNumber;
			
			//synchronize with monitor
			@(posedge testInterface.clock);

			//wait for driver to drive snoopy controller signals
			@(posedge testInterface.clock);
			//collect snoopy controller signals
			transaction.snoopyIndex   = testInterface.cacheInterface.snoopyIndex;
			transaction.snoopyTagIn   = testInterface.cacheInterface.snoopyTagIn;
			transaction.snoopyStateIn = testInterface.cacheInterface.snoopyStateIn;
			transaction.snoopyHit     = testInterface.cacheInterface.snoopyHit;
			transaction.snoopyDataOut = testInterface.cacheInterface.snoopyDataOut;

			//change state if hit
			if (transaction.snoopyHit == 1) begin
				repeat (2) begin
					@(posedge testInterface.clock);
				end
			end

			transaction.snoopyStateOut    = testInterface.cacheInterface.snoopyStateOut;
			transaction.snoopyCacheNumber = testInterface.cacheInterface.snoopyCacheNumber;
			//wait for monitor to collect data
			@(posedge testInterface.clock);

			//if hit wait for wait for block invalidate
			if (testInterface.cacheInterface.snoopyHit == 1) begin
				repeat (2) begin
					@(posedge testInterface.clock);
				end
			end

			//collect hit signal
			transaction.isInvalidated = ~testInterface.cacheInterface.snoopyHit;
			analysisPort.write(transaction);
			@(posedge testInterface.clock);
		endtask : collect

	endclass : CacheAccessMonitor

	//Agent
	class CacheAccessAgent#(
		int TAG_WIDTH                          = 6,
		int INDEX_WIDTH                        = 6,
		int OFFSET_WIDTH                       = 4,
		int SET_ASSOCIATIVITY                  = 2,
		int DATA_WIDTH                         = 16,
		type STATE_TYPE                        = logic[1 : 0],
		int STATE_SET_LENGTH                   = 3,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {1, 2, 3},
		STATE_TYPE INVALID_STATE               = 2'b0
	) extends uvm_agent;

		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		`uvm_component_utils(CacheAccessAgent#(.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .DATA_WIDTH(DATA_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .INVALID_STATE(INVALID_STATE)))

		uvm_analysis_port#(CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		)) analysisPort;

		uvm_sequencer#(CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		)) sequencer;

		CacheAccessDriver#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET),
			.INVALID_STATE(INVALID_STATE)
		) driver;

		CacheAccessMonitor#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET),
			.INVALID_STATE(INVALID_STATE)
		) monitor;

		function new(string name = "CacheAccessAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort = new(.name("analysisPort"), .parent(this));

			sequencer = uvm_sequencer#(CacheAccessTransaction#(
				.TAG_WIDTH(TAG_WIDTH), 
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET)
			))::type_id::create(.name("sequencer"), .parent(this));

			driver = CacheAccessDriver#(
				.TAG_WIDTH(TAG_WIDTH), 
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.INVALID_STATE(INVALID_STATE)
			)::type_id::create(.name("driver"), .parent(this));

			monitor = CacheAccessMonitor#(
				.TAG_WIDTH(TAG_WIDTH), 
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.INVALID_STATE(INVALID_STATE)
			)::type_id::create(.name("monitor"), .parent(this));

		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase

	endclass : CacheAccessAgent

	//Scoreboard
	class CacheAccessScoreboard#(
		int TAG_WIDTH                          = 6,
		int INDEX_WIDTH                        = 6,
		int OFFSET_WIDTH                       = 4,
		int SET_ASSOCIATIVITY                  = 2,
		int DATA_WIDTH                         = 16,
		type STATE_TYPE                        = logic[1 : 0],
		int STATE_SET_LENGTH                   = 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {0, 1, 2, 3},
		STATE_TYPE INVALID_STATE               = 2'b0
	) extends uvm_agent;

		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		`uvm_component_utils(CacheAccessScoreboard#(.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .DATA_WIDTH(DATA_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .INVALID_STATE(INVALID_STATE)))

		uvm_analysis_export#(CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		)) analysisExport;

		uvm_tlm_analysis_fifo#(CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		)) analysisFifo;

		CacheAccessTransaction#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET)
		) transaction;

		setAssociativeCacheClassImplementationPackage::SetAssociativeCacheClassImplementation#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)
		) classImplementation;

		function new(string name = "CacheAccessScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			transaction = CacheAccessTransaction#(
				.TAG_WIDTH(TAG_WIDTH), 
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
				.DATA_WIDTH(DATA_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET)
			)::type_id::create(.name("transaction"));

			analysisExport      = new (.name("analysisExport"), .parent(this));
			analysisFifo        = new (.name("analysisFifo"), .parent(this));
			classImplementation = new();
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			analysisExport.connect(analysisFifo.analysis_export);
		endfunction : connect_phase

		virtual task run();
			forever begin
				analysisFifo.get(transaction);
				check();
			end
		endtask : run

		virtual function void check();
			int errorCounter = 0;

			//helper variables
			int cpuHit = classImplementation.isHit(.index(transaction.cpuIndex), .tag(transaction.cpuTagIn));
			if (transaction.cpuHit != cpuHit) begin
				`uvm_info("CPU_HIT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", cpuHit, transaction.cpuHit), UVM_LOW);
			end

			if (transaction.cpuHit == 0) begin
				classImplementation.writeTag(.index(transaction.cpuIndex), .tag(transaction.cpuTagIn));
				classImplementation.writeState(.index(transaction.cpuIndex), .tag(transaction.cpuTagIn), .state(transaction.cpuStateIn));
				classImplementation.writeDataToWholeLine(.index(transaction.cpuIndex), .tag(transaction.cpuTagIn), .data(transaction.cpuDataIn));
			end
			classImplementation.access(.index(transaction.cpuIndex), .tag(transaction.cpuTagIn));

			begin
				//helper variables
				logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber  = classImplementation.getCacheNumber(.index(transaction.cpuIndex), .tag(transaction.cpuTagIn));
				logic[TAG_WIDTH - 1         : 0] tagOut       = classImplementation.getTag(.cacheNumber(cacheNumber), .index(transaction.cpuIndex));
				logic[DATA_WIDTH - 1        : 0] dataOut      = classImplementation.getData(.cacheNumber(cacheNumber), .index(transaction.cpuIndex));
				STATE_TYPE											 stateOut     = classImplementation.getState(.cacheNumber(cacheNumber), .index(transaction.cpuIndex));
				//check if it is in the right cache Number
				if (transaction.cpuCacheNumber != cacheNumber) begin
					`uvm_info("CACHE_NUMBER_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", cacheNumber, transaction.cpuCacheNumber), UVM_LOW)
					errorCounter++;
				end
				//check if tagOuts match
				if (transaction.cpuTagOut != tagOut) begin
					`uvm_info("TAG_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", tagOut, transaction.cpuTagOut), UVM_LOW)
					errorCounter++;
				end
				//check if dataOuts match
				if (transaction.cpuDataOut != dataOut) begin
					`uvm_info("DATA_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", dataOut, transaction.cpuDataOut), UVM_LOW)
					errorCounter++;
				end
				//check if stateOuts match
				if (transaction.cpuStateOut != stateOut) begin
					`uvm_info("STATE_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", stateOut, transaction.cpuStateOut), UVM_LOW)
					errorCounter++;
				end
			end
	
			begin
				logic snoopyHit = classImplementation.isHit(.index(transaction.snoopyIndex), .tag(transaction.snoopyTagIn));
				logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber = classImplementation.getCacheNumber(.index(transaction.snoopyIndex), .tag(transaction.snoopyTagIn));
				logic[DATA_WIDTH - 1 : 0] snoopyDataOut      = classImplementation.getData(.cacheNumber(cacheNumber), .index(transaction.snoopyIndex));
				//check snoopy hit
				if (transaction.snoopyHit != snoopyHit) begin
					`uvm_info("SNOOPY_HIT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", ~transaction.snoopyHit, transaction.snoopyHit), UVM_LOW);
					errorCounter++;
				end
				
				if (transaction.snoopyCacheNumber != cacheNumber) begin
					`uvm_info("SNOOPY_CACHE_NUMBER_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", cacheNumber, transaction.snoopyCacheNumber), UVM_LOW);
					errorCounter++;
				end	

				if (transaction.snoopyDataOut != snoopyDataOut) begin
					`uvm_info("SNOOPY_DATA_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", snoopyDataOut, transaction.snoopyDataOut), UVM_LOW);
					errorCounter++;
				end	

				//if snoopy hit write and check state
				if (snoopyHit == 1) begin
					classImplementation.writeState(.index(transaction.snoopyIndex), .tag(transaction.snoopyTagIn), .state(transaction.snoopyStateIn));	
					if (transaction.snoopyStateOut != classImplementation.getState(.cacheNumber(cacheNumber), .index(transaction.snoopyIndex))) begin
						`uvm_info("SNOOPY_STATE_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", classImplementation.getState(.cacheNumber(cacheNumber), .index(transaction.snoopyIndex)), transaction.snoopyStateOut), UVM_LOW);
						errorCounter++;
					end

					//invalidate
					classImplementation.invalidate(.index(transaction.snoopyIndex), .tag(transaction.snoopyTagIn));
					classImplementation.writeState(.index(transaction.snoopyIndex),.tag(transaction.snoopyTagIn), .state(INVALID_STATE));
					if (transaction.isInvalidated != ~classImplementation.isHit(.index(transaction.snoopyIndex), .tag(transaction.snoopyTagIn))) begin
						`uvm_info("SNOOPY_INVALIDATE_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", 1, transaction.isInvalidated), UVM_LOW);
						errorCounter++;
					end	
				end
			end

			if (errorCounter == 0) begin
				`uvm_info("TEST_OK", "", UVM_LOW)
			end
		endfunction : check

	endclass : CacheAccessScoreboard

	//Environment
	class CacheAccessEnvironment#(
		int TAG_WIDTH                          = 6,
		int INDEX_WIDTH                        = 6,
		int OFFSET_WIDTH                       = 4,
		int SET_ASSOCIATIVITY                  = 2,
		int DATA_WIDTH                         = 16,
		type STATE_TYPE                        = logic[1 : 0],
		int STATE_SET_LENGTH                   = 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH] = {0, 1, 2, 3},
		STATE_TYPE INVALID_STATE               = 2'b0
	) extends uvm_env;
		
		`uvm_component_utils(CacheAccessEnvironment#(.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .DATA_WIDTH(DATA_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .INVALID_STATE(INVALID_STATE)))
		
		CacheAccessScoreboard#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH), 
			.OFFSET_WIDTH(OFFSET_WIDTH), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
			.DATA_WIDTH(DATA_WIDTH),	
			.STATE_TYPE(STATE_TYPE), 
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.INVALID_STATE(INVALID_STATE)
		) scoreboard;

		CacheAccessAgent#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH), 
			.OFFSET_WIDTH(OFFSET_WIDTH), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
			.DATA_WIDTH(DATA_WIDTH),	
			.STATE_TYPE(STATE_TYPE), 
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET),
			.INVALID_STATE(INVALID_STATE) 
		) agent;

		function new(string name = "CacheAccessEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			agent = CacheAccessAgent#(
				.TAG_WIDTH(TAG_WIDTH), 
				.INDEX_WIDTH(INDEX_WIDTH), 
				.OFFSET_WIDTH(OFFSET_WIDTH), 
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.DATA_WIDTH(DATA_WIDTH),	
				.STATE_TYPE(STATE_TYPE), 
				.STATE_SET_LENGTH(STATE_SET_LENGTH), 
				.STATE_SET(STATE_SET), 
				.INVALID_STATE(INVALID_STATE) 
			)::type_id::create(.name("agent"), .parent(this));

			scoreboard = CacheAccessScoreboard#(
				.TAG_WIDTH(TAG_WIDTH), 
				.INDEX_WIDTH(INDEX_WIDTH), 
				.OFFSET_WIDTH(OFFSET_WIDTH), 
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.DATA_WIDTH(DATA_WIDTH),	
				.STATE_TYPE(STATE_TYPE), 
				.STATE_SET_LENGTH(STATE_SET_LENGTH), 
				.STATE_SET(STATE_SET), 
				.INVALID_STATE(INVALID_STATE)
			)::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			agent.analysisPort.connect(scoreboard.analysisExport);
		endfunction : connect_phase
	endclass : CacheAccessEnvironment

endpackage : setAssociativeCacheEnvirnomentPackage
