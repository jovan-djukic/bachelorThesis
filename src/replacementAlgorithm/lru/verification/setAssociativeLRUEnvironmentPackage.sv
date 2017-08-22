package setAssociativeLRUEnvironmentPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	typedef enum int {
		ACCESS,
		INVALIDATE,
		ACCESS_AND_INVALIDATE	
	} ACCESS_TYPE;

	class SetAssociativeLRUTransaction#(
		int INDEX_WIDTH				= 6,
		int SET_ASSOCIATIVITY	= 2	
	) extends uvm_sequence_item;
		
		//index tells us which set it is, or rather whic lru to use
		bit[INDEX_WIDTH - 1 : 0] 			 cpuIndexIn, snoopyIndexIn;
		//there are lines per lru as much as there are smaller caches
		bit[SET_ASSOCIATIVITY - 1 : 0] lastAccessedCacheLine, invalidatedCacheLine, replacementCacheLine;
		ACCESS_TYPE                    accessType;
		
		`uvm_object_utils_begin(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))
			`uvm_field_int(cpuIndexIn, UVM_ALL_ON)
			`uvm_field_int(snoopyIndexIn, UVM_ALL_ON)
			`uvm_field_int(lastAccessedCacheLine, UVM_ALL_ON)
			`uvm_field_int(invalidatedCacheLine, UVM_ALL_ON)
			`uvm_field_int(replacementCacheLine, UVM_ALL_ON)
			`uvm_field_enum(ACCESS_TYPE, accessType, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SetAssociativeLRUTransaction");
			super.new(.name(name));
		endfunction : new

		virtual function void myRandomize();
			case ($urandom_range(2, 0))
				0: begin
					accessType = ACCESS;
				end
				1: begin
					accessType = INVALIDATE;
				end
				2: begin
					accessType = ACCESS_AND_INVALIDATE;
				end
			endcase

			case (accessType)
				ACCESS:                begin
					cpuIndexIn            = $urandom();
					lastAccessedCacheLine = $urandom();
				end
				INVALIDATE:            begin
					snoopyIndexIn        = $urandom();
					invalidatedCacheLine = $urandom();
				end
				ACCESS_AND_INVALIDATE: begin
					cpuIndexIn             = $urandom();
					snoopyIndexIn          = cpuIndexIn;
					lastAccessedCacheLine  = $urandom();
					do begin
						invalidatedCacheLine = $urandom();
					end while (lastAccessedCacheLine == invalidatedCacheLine);
				end
			endcase
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
				case (req.accessType)
					ACCESS:                begin
						testInterface.cpuIndexIn                                          = req.cpuIndexIn;
						testInterface.replacementAlgorithmInterface.lastAccessedCacheLine = req.lastAccessedCacheLine;
						testInterface.replacementAlgorithmInterface.accessEnable          = 1;
					end
					INVALIDATE:            begin
						testInterface.snoopyIndexIn                                       = req.snoopyIndexIn;
						testInterface.replacementAlgorithmInterface.invalidatedCacheLine  = req.invalidatedCacheLine;
						testInterface.replacementAlgorithmInterface.invalidateEnable      = 1;
					end
					ACCESS_AND_INVALIDATE: begin
						testInterface.cpuIndexIn                                          = req.cpuIndexIn;
						testInterface.snoopyIndexIn                                       = req.snoopyIndexIn;
						testInterface.replacementAlgorithmInterface.lastAccessedCacheLine = req.lastAccessedCacheLine;
						testInterface.replacementAlgorithmInterface.invalidatedCacheLine  = req.invalidatedCacheLine;
						testInterface.replacementAlgorithmInterface.accessEnable          = 1;
						testInterface.replacementAlgorithmInterface.invalidateEnable      = 1;
					end
				endcase

				//wait for write to sync in
				repeat (2) begin
					@(posedge testInterface.clock);
				end
				//wait for monitor to collect data
				@(posedge testInterface.clock);
				//turn off access and invalidate
				testInterface.replacementAlgorithmInterface.accessEnable     = 0;
				testInterface.replacementAlgorithmInterface.invalidateEnable = 0;
			
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
				//case (req.accessType)
				if (testInterface.replacementAlgorithmInterface.accessEnable == 1 && testInterface.replacementAlgorithmInterface.invalidateEnable == 1) begin
					//ACCESS_AND_INVALIDATE	
					transaction.accessType            = ACCESS_AND_INVALIDATE;
					transaction.cpuIndexIn            = testInterface.cpuIndexIn;
					transaction.snoopyIndexIn         = testInterface.snoopyIndexIn;
					transaction.invalidatedCacheLine  = testInterface.replacementAlgorithmInterface.invalidatedCacheLine;
					transaction.lastAccessedCacheLine = testInterface.replacementAlgorithmInterface.lastAccessedCacheLine;
					transaction.replacementCacheLine  = testInterface.replacementAlgorithmInterface.replacementCacheLine;
				end else if (testInterface.replacementAlgorithmInterface.accessEnable == 1) begin
					//ACCESS
					transaction.accessType            = ACCESS;
					transaction.cpuIndexIn            = testInterface.cpuIndexIn;
					transaction.lastAccessedCacheLine = testInterface.replacementAlgorithmInterface.lastAccessedCacheLine;
					transaction.replacementCacheLine  = testInterface.replacementAlgorithmInterface.replacementCacheLine;
				end else begin
					//INVALIDATE
					transaction.accessType           = INVALIDATE;
					transaction.snoopyIndexIn        = testInterface.snoopyIndexIn;
					transaction.invalidatedCacheLine = testInterface.replacementAlgorithmInterface.invalidatedCacheLine;
					transaction.replacementCacheLine = testInterface.replacementAlgorithmInterface.replacementCacheLine;
				end

				//write data
				analysisPort.write(transaction);
				@(posedge testInterface.clock);
				//wait for turning off of access and invalidate
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
	
	//Scoreboard
	class SetAssociativeLRUScoreboard#(
		int INDEX_WIDTH       = 4,
		int SET_ASSOCIATIVITY = 2
	) extends uvm_scoreboard;
		
		`uvm_component_utils(SetAssociativeLRUScoreboard#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		uvm_analysis_export#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) analysisExport;

		uvm_tlm_analysis_fifo#(SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) analysisFifo;

		SetAssociativeLRUTransaction#(.INDEX_WIDTH(INDEX_WIDTH), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)) transaction;

		//data needed for checking lru
		setAssociativeLRUClassImplementationPackage::SetAssociativeLRUClassImplementation#(
			.INDEX_WIDTH(INDEX_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) lruImplementation;

		function new(string name = "SetAssociativeLRUScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));

			transaction = new(.name("transaction"));
			
			lruImplementation = new();
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
			int cpuIndexIn            = transaction.cpuIndexIn;
			int snoopyIndexIn         = transaction.snoopyIndexIn;
			int lastAccessedCacheLine = transaction.lastAccessedCacheLine;
			int invalidatedCacheLine  = transaction.invalidatedCacheLine;
			int replacementCacheLine  = transaction.replacementCacheLine;
			ACCESS_TYPE accessType    = transaction.accessType;
			
			case (accessType) 
				ACCESS:                begin
					lruImplementation.access(
						.index(cpuIndexIn),
						.line(lastAccessedCacheLine)
					);
				end
				INVALIDATE:            begin
					lruImplementation.invalidate(
						.index(snoopyIndexIn),
						.line(invalidatedCacheLine)
					);
				end
				ACCESS_AND_INVALIDATE: begin
					lruImplementation.accessAndInvalidate(
						.cpuIndex(cpuIndexIn),
						.snoopyIndex(snoopyIndexIn),
						.cpuLine(lastAccessedCacheLine),
						.snoopyLine(invalidatedCacheLine)	
					);
				end
			endcase
	
			//find replacement and compare
			if (lruImplementation.getReplacementCacheLine(cpuIndexIn) != replacementCacheLine) begin
				`uvm_info("SCOREBOARD::ERROR", $sformatf("\nINDEX=%d, EXPECTED_LINE=%d, LRU_LINE=%d, TYPE=%s", cpuIndexIn, lruImplementation.getReplacementCacheLine(cpuIndexIn), replacementCacheLine, accessType.name()), UVM_LOW)
			end else begin
				`uvm_info("SCOREBOARD::OK", $sformatf("\nINDEX=%d, EXPECTED_LINE=%d, LRU_LINE=%d, TYPE=%s", cpuIndexIn, lruImplementation.getReplacementCacheLine(cpuIndexIn), replacementCacheLine, accessType.name()), UVM_LOW)
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
