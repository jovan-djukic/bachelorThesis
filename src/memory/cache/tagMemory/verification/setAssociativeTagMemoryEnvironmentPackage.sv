package setAssociativeTagMemoryEnvironmentPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//transaction
	class TagAccessTransaction#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		int SET_ASSOCIATIVITY 									= 2
	) extends uvm_sequence_item;

		bit[ADDRESS_WIDTH - 1 : 0]       address;
		STATE_TYPE								       state;
		logic											       hit;
		logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber;

		`uvm_object_utils_begin(TagAccessTransaction#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, state, UVM_ALL_ON)
			`uvm_field_int(hit, UVM_ALL_ON)
			`uvm_field_int(cacheNumber, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "TagAccessTransaction");
			super.new(.name(name));
		endfunction : new

		virtual function void myRandomize();
			address = $urandom();
			state		= STATE_SET[$urandom() % STATE_SET_LENGTH];
		endfunction : myRandomize

	endclass : TagAccessTransaction	

	//sequencer
	class TagAccessSequencer#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		int SET_ASSOCIATIVITY 									= 2
	) extends uvm_sequencer#(TagAccessTransaction#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
		.STATE_TYPE(STATE_TYPE), 
		.STATE_SET_LENGTH(STATE_SET_LENGTH), 
		.STATE_SET(STATE_SET), 
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	));
		
		`uvm_component_utils(TagAccessSequencer#(.ADDRESS_WIDTH(ADDRESS_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)))

		function new(string name = "TagAccessSequencer", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new
	endclass : TagAccessSequencer

	//sequence
	class TagAccessSequence#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		int SET_ASSOCIATIVITY 									= 2,
		int SEQUENCE_COUNT  										= 50
	) extends uvm_sequence#(TagAccessTransaction#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
		.STATE_TYPE(STATE_TYPE), 
		.STATE_SET_LENGTH(STATE_SET_LENGTH), 
		.STATE_SET(STATE_SET), 
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	));

		`uvm_object_utils(TagAccessSequence#(.ADDRESS_WIDTH(ADDRESS_WIDTH),	.STATE_TYPE(STATE_TYPE), .STATE_SET(STATE_SET), .STATE_SET_LENGTH(STATE_SET_LENGTH), .SEQUENCE_COUNT(SEQUENCE_COUNT), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY))) 

		function new(string name = "TagAccessSequence");
			super.new(.name(name));
		endfunction : new

		virtual task body();
			TagAccessTransaction#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH), 
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) firstTransaction, secondTransaction;
			
			repeat (SEQUENCE_COUNT) begin
				firstTransaction = TagAccessTransaction#(
					.ADDRESS_WIDTH(ADDRESS_WIDTH), 
					.STATE_TYPE(STATE_TYPE),
					.STATE_SET_LENGTH(STATE_SET_LENGTH),
					.STATE_SET(STATE_SET),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
				)::type_id::create(.name("firstTransaction"));

				start_item(firstTransaction);
					firstTransaction.myRandomize();
					$cast(secondTransaction, firstTransaction.clone());
				finish_item(firstTransaction);
				start_item(secondTransaction);
				finish_item(secondTransaction);
			end
		endtask : body

	endclass : TagAccessSequence

	//driver
	class TagAccessDriver#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		int SET_ASSOCIATIVITY 									= 2,
		int TAG_WIDTH				  									= 6,
		int INDEX_WIDTH			  									= 6,
		int OFFSET_WIDTH												= 4 
	) extends uvm_driver#(TagAccessTransaction#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
		.STATE_TYPE(STATE_TYPE), 
		.STATE_SET_LENGTH(STATE_SET_LENGTH), 
		.STATE_SET(STATE_SET), 
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
	));
		`uvm_component_utils(TagAccessDriver#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET),  .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH)))
		
		//number of smaller caches 
		localparam NUMBER_OF_CACHE_LINES = 1 << INDEX_WIDTH;

		//counter representing fifo replacement algorithm, there is a counter for each line in a small cache and its size is the number of caches
		logic[SET_ASSOCIATIVITY - 1 : 0] fifoCounters[NUMBER_OF_CACHE_LINES];

		//virtual interface
		protected virtual TestInterface#(
			.STATE_TYPE(STATE_TYPE), 
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testInterafce;
		
		function new(string name = "TagAccessDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			//get test interface from database
			if (!uvm_config_db#(virtual TestInterface#(
					.STATE_TYPE(STATE_TYPE),
					.TAG_WIDTH(TAG_WIDTH),
					.INDEX_WIDTH(INDEX_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
				))::get(this, "", "TestInterface", testInterafce)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"})
			end

			for (int i = 0; i < NUMBER_OF_CACHE_LINES; i++) begin
				fifoCounters[i] = 0;
			end
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			//first reset module
			testInterafce.reset = 1;
			repeat(2) begin
				@(posedge testInterafce.clock);
			end
			testInterafce.reset = 0;

			//start driving
			forever begin
				seq_item_port.get_next_item(req);
					drive();
				seq_item_port.item_done();
			end
		endtask : run_phase

		virtual task drive();
			testInterafce.tagUnitInterface.index 		= req.address[OFFSET_WIDTH +: INDEX_WIDTH];
			testInterafce.tagUnitInterface.tagIn 		= req.address[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];
			testInterafce.tagUnitInterface.stateIn	=	req.state;
			testInterafce.cacheNumberIn					 		= fifoCounters[req.address[OFFSET_WIDTH +: INDEX_WIDTH]];

			//this print is for checking if info is the same as the one received in the scoreboard
			//`uvm_info("DRIVER::TRANSACTION_INFO", $sformatf("\ntag=%d\nindex=%d\nstate=%d\ncacheNumber=%d\n", testInterafce.tagUnitInterface.tagIn, testInterafce.tagUnitInterface.index, testInterafce.tagUnitInterface.stateIn, testInterafce.cacheNumberIn), UVM_LOW)

			//wait for response
			@(posedge testInterafce.clock)

			//if tag is not present then write it, otherwise do nothing 
			if (testInterafce.tagUnitInterface.hit != 1) begin
				testInterafce.tagUnitInterface.writeTag		=	1;
				testInterafce.tagUnitInterface.writeState	= 1;	
				repeat(2) begin
					@(posedge testInterafce.clock);
				end
				testInterafce.tagUnitInterface.writeTag		=	0;
				testInterafce.tagUnitInterface.writeState	= 0;	
				fifoCounters[req.address[OFFSET_WIDTH +: INDEX_WIDTH]]++;	
			end

			@(posedge testInterafce.clock);
		endtask : drive;

	endclass : TagAccessDriver

	//monitor
	class TagAccessMonitor#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		int SET_ASSOCIATIVITY 									= 2,
		int TAG_WIDTH				  									= 6,
		int INDEX_WIDTH			  									= 6,
		int OFFSET_WIDTH												= 4 
	) extends uvm_monitor;
		
		`uvm_component_utils(TagAccessMonitor#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH)))

		protected virtual TestInterface#(
			.STATE_TYPE(STATE_TYPE), 
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testInterafce;

		uvm_analysis_port#(TagAccessTransaction#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.STATE_TYPE(STATE_TYPE), 
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		)) analysisPort;
		
		function new(string name = "TagAccessMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			//get test interface from database
			if (!uvm_config_db#(virtual TestInterface#(
					.STATE_TYPE(STATE_TYPE),
					.TAG_WIDTH(TAG_WIDTH),
					.INDEX_WIDTH(INDEX_WIDTH),
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
				))::get(this, "", "TestInterface", testInterafce)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"})
			end
			
			analysisPort = new(.name("analysisPort"), .parent(this));
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			//transaction 
			TagAccessTransaction#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH), 
				.STATE_TYPE(STATE_TYPE), 
				.STATE_SET_LENGTH(STATE_SET_LENGTH), 
				.STATE_SET(STATE_SET), 
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			) transaction = TagAccessTransaction#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH), 
				.STATE_TYPE(STATE_TYPE), 
				.STATE_SET_LENGTH(STATE_SET_LENGTH), 
				.STATE_SET(STATE_SET), 
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("transaction")); 

			//2 clock wait for reset
			repeat(2) begin
				@(posedge testInterafce.clock);
			end	

			//start collecting data
			forever begin
				//1 clock wait for output
				@(posedge testInterafce.clock);

				//collect address
				transaction.address = {testInterafce.tagUnitInterface.tagIn, testInterafce.tagUnitInterface.index, {(ADDRESS_WIDTH - TAG_WIDTH - INDEX_WIDTH){1'b0}}};
				transaction.hit		 	= testInterafce.tagUnitInterface.hit;

				//monitor info for debbuging
				//`uvm_info("MONITOR::TRANSACTION", $sformatf("hit=%d, interface.hit=%d", transaction.hit, testInterafce.tagUnitInterface.hit), UVM_LOW)
				//if not hit wait 2 clocks so that tag and state can be written
				if (testInterafce.tagUnitInterface.hit != 1) begin
					repeat(2) begin
						@(posedge testInterafce.clock);
					end
				end

				//write stateOut and cacheNumberOut, tag we have from address
				transaction.state 			= testInterafce.tagUnitInterface.stateOut;
				transaction.cacheNumber = testInterafce.cacheNumberOut;

				//write to analysis port
				analysisPort.write(transaction);	

				@(posedge testInterafce.clock);
			end
		endtask : run_phase

	endclass : TagAccessMonitor

	//agent
	class TagAccessAgent#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		int SET_ASSOCIATIVITY 									= 2,
		int TAG_WIDTH				  									= 6,
		int INDEX_WIDTH			  									= 6,
		int OFFSET_WIDTH												= 4 
	) extends uvm_agent;

		`uvm_component_utils(TagAccessAgent#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH)))

		uvm_analysis_port#(TagAccessTransaction#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.STATE_TYPE(STATE_TYPE), 
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		)) analysisPort;

		TagAccessSequencer#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) sequencer;

		TagAccessDriver#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH) 
		) driver;

		TagAccessMonitor#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH) 
		) monitor;

		function new(string name = "TagAccessAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort = new(.name("analysisPort"), .parent(this));

			sequencer = TagAccessSequencer#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH), 
				.STATE_SET(STATE_SET), 
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
			)::type_id::create(.name("sequencer"), .parent(this));


			driver = TagAccessDriver#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH), 
				.STATE_SET(STATE_SET), 
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH) 
			)::type_id::create(.name("driver"), .parent(this));
			
			monitor = TagAccessMonitor#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH), 
				.STATE_SET(STATE_SET), 
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH) 
			)::type_id::create(.name("monitor"), .parent(this));
		 
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase

	endclass : TagAccessAgent

	//scoreboard
	class TagAccessScoreboard#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		STATE_TYPE INVALID_STATE							  = 0,
		int SET_ASSOCIATIVITY 									= 2,
		int TAG_WIDTH				  									= 6,
		int INDEX_WIDTH			  									= 6,
		int OFFSET_WIDTH												= 4 
	) extends uvm_scoreboard;
		`uvm_component_utils(TagAccessScoreboard#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), .TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH)))

		//constant for number of smaller caches and number of cache lines per small cache
		localparam NUMBER_OF_SMALL_CACHES = 1 << SET_ASSOCIATIVITY;
		localparam NUMBER_OF_CACHE_LINES	 = 1 << INDEX_WIDTH;

		//data need for comparison of algorithms
		logic[TAG_WIDTH - 1 : 0] tags[NUMBER_OF_SMALL_CACHES][NUMBER_OF_CACHE_LINES];
		STATE_TYPE states[NUMBER_OF_SMALL_CACHES][NUMBER_OF_CACHE_LINES];

		uvm_analysis_export#(TagAccessTransaction#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.STATE_TYPE(STATE_TYPE), 
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		)) analysisExport;

		uvm_tlm_analysis_fifo#(TagAccessTransaction#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.STATE_TYPE(STATE_TYPE), 
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		)) analysisFifo;

		TagAccessTransaction#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.STATE_TYPE(STATE_TYPE), 
			.STATE_SET_LENGTH(STATE_SET_LENGTH), 
			.STATE_SET(STATE_SET), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) transaction;

		function new(string name = "TagAccessScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));

			transaction = new(.name("transaction"));
			
			for (int i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
				for (int j = 0; j < NUMBER_OF_CACHE_LINES; j++) begin
					states[i][j] = INVALID_STATE;
				end
			end
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisExport = new(.name("analysisExport"), .parent(this));

			analysisFifo	 = new(.name("analysisFifo"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			analysisExport.connect(analysisFifo.analysis_export);
		endfunction : connect_phase

		task run();
			forever begin
				analysisFifo.get(transaction);
				check();
			end
		endtask : run

		virtual function void check();
			//helper variables
			bit[SET_ASSOCIATIVITY - 1 : 0] cacheNumber = transaction.cacheNumber;
			bit[INDEX_WIDTH - 1 : 0]			 index			 = transaction.address[OFFSET_WIDTH +: INDEX_WIDTH];
			bit[TAG_WIDTH - 1 : 0]				 tag				 = transaction.address[(OFFSET_WIDTH + INDEX_WIDTH) +: TAG_WIDTH];	
			STATE_TYPE										 state			 = transaction.state;

			//first check if it shoudl be hit and if it is a hit
			if (transaction.hit == 0) begin
				for (int i = 0; i < NUMBER_OF_SMALL_CACHES; i++) begin
					if (tags[i][index] == tag && states[i][index] != INVALID_STATE && transaction.hit == 0) begin
						`uvm_info("SCOREBOARD::HIT_ERROR", $sformatf("\nTAGS[%d][%d]=%d == %d\n", i, index, tags[i][index], tag), UVM_LOW)
						return;
					end
				end
			end

			if (transaction.hit == 0) begin
				//write data 
				tags[cacheNumber][index] 	 = tag;
				states[cacheNumber][index] = state;

				//report to console
				`uvm_info("SCOREBOARD::WRITING", $sformatf("\nTAGS[%d][%d]=%d, STATES[%d][%d]=%s\n", cacheNumber, index, tag, cacheNumber, index, state.name()), UVM_LOW)
			end else begin
				string tagErrorString = "", stateErrorString = "";

				if (tags[cacheNumber][index] != tag) begin
					tagErrorString = $sformatf("TAGS[%d][%d]=%d expected TAGC[%d][%d]=%d ", cacheNumber, index, tags[cacheNumber][index], cacheNumber, index, tag);
				end
				
				if (states[cacheNumber][index] != state) begin
					stateErrorString = $sformatf("STATES[%d][%d]=%s expected STATEC[%d][%d]=%s", cacheNumber, index, states[cacheNumber][index], cacheNumber, index, state);
				end

				if (tagErrorString != "" || stateErrorString != "") begin
					`uvm_info("SCOREBOARD::WRITING_ERROR", {"\n", tagErrorString, stateErrorString, "\n"}, UVM_LOW)
				end else begin
					`uvm_info("SCOREBOARD::CHECK", $sformatf("\nOK\nTAGS[%d][%d]=%d == TAGC[%d][%d]=%d, STATES[%d][%d]=%s == STATEC[%d][%d]=%s\n", cacheNumber, index, tags[cacheNumber][index], cacheNumber, index, tag, cacheNumber, index, states[cacheNumber][index], cacheNumber, index, state), UVM_LOW)
				end
			end	
		endfunction : check

	endclass : TagAccessScoreboard;

	//environment
	class TagAccessEnvironment#(
		int ADDRESS_WIDTH		  									= 16,
		type STATE_TYPE			  									= logic[1 : 0],
		int STATE_SET_LENGTH										= 4,
		STATE_TYPE STATE_SET[STATE_SET_LENGTH]	= {0, 1, 2, 3}, 
		STATE_TYPE INVALID_STATE							  = 0,
		int SET_ASSOCIATIVITY 									= 2,
		int TAG_WIDTH				  									= 6,
		int INDEX_WIDTH			  									= 6,
		int OFFSET_WIDTH												= 4 
	) extends uvm_env;

		`uvm_component_utils(TagAccessEnvironment#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .STATE_TYPE(STATE_TYPE), .STATE_SET_LENGTH(STATE_SET_LENGTH), .STATE_SET(STATE_SET), .SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),	.TAG_WIDTH(TAG_WIDTH), .INDEX_WIDTH(INDEX_WIDTH), .OFFSET_WIDTH(OFFSET_WIDTH)))

		TagAccessAgent#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH) 
		) agent;

		
		TagAccessScoreboard#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.STATE_SET_LENGTH(STATE_SET_LENGTH),
			.STATE_SET(STATE_SET),
			.INVALID_STATE(INVALID_STATE),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH) 
		) scoreboard;


		function new(string name = "TagAccessEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			agent = TagAccessAgent#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH) 
			)::type_id::create(.name("agent"), .parent(this));

			scoreboard = TagAccessScoreboard#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.STATE_TYPE(STATE_TYPE),
				.STATE_SET_LENGTH(STATE_SET_LENGTH),
				.STATE_SET(STATE_SET),
				.INVALID_STATE(INVALID_STATE),
				.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY), 
				.TAG_WIDTH(TAG_WIDTH),
				.INDEX_WIDTH(INDEX_WIDTH),
				.OFFSET_WIDTH(OFFSET_WIDTH) 
			)::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			agent.analysisPort.connect(scoreboard.analysisExport);
		endfunction : connect_phase

	endclass : TagAccessEnvironment

endpackage : setAssociativeTagMemoryEnvironmentPackage
