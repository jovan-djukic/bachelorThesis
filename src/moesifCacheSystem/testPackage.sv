package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import states::*;

	localparam ADDRESS_WIDTH            = 8;
	localparam DATA_WIDTH               = 8;
	localparam TAG_WIDTH                = 4;
	localparam INDEX_WIDTH              = 2;
	localparam OFFSET_WIDTH             = 2;
	localparam SET_ASSOCIATIVITY        = 1;
	localparam NUMBER_OF_CACHES         = 4;
	localparam CACHE_NUMBER_WIDTH			  = $clog2(NUMBER_OF_CACHES);
	localparam type STATE_TYPE          = CacheLineState;
	localparam STATE_TYPE INVALID_STATE = INVALID;
	localparam SEQUENCE_ITEM_COUNT      = 400;
	localparam TEST_INTERFACE           = "TestInterface";

	localparam NUMBER_OF_BLOCKS = 64;
	localparam SIZE_IN_WORDS    = (1 << OFFSET_WIDTH) * NUMBER_OF_BLOCKS;

	//memory sequence item
	class MemorySequenceItem extends uvm_sequence_item;
		bit [ADDRESS_WIDTH - 1 	: 0] address;
		bit [DATA_WIDTH - 1			: 0] data;
		bit													 isRead;

		`uvm_object_utils_begin(MemorySequenceItem)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(data, UVM_ALL_ON)
			`uvm_field_int(isRead, UVM_ALL_ON)
		`uvm_object_utils_end
		
		function new(string name = "MemorySequenceItem");
			super.new(name);
		endfunction : new

		virtual function void myRandomize();
			address	= $urandom_range(SIZE_IN_WORDS - 1, 0);
			data		= $urandom();
			isRead	=	$urandom();
		endfunction : myRandomize
	endclass : MemorySequenceItem

	//memory reset sequence
	class MemoryResetSequence extends uvm_sequence#(MemorySequenceItem);
		`uvm_object_utils(MemoryResetSequence)

		function new(string name = "MemoryResetSequence");
			super.new(name);
		endfunction : new

		virtual task body();
			MemorySequenceItem memorySequenceItem = MemorySequenceItem::type_id::create(.name("memorySequenceItem"));

			for (int i = 0; i < SIZE_IN_WORDS; i++) begin
				start_item(memorySequenceItem);
					memorySequenceItem.address = i;
					memorySequenceItem.data    = 0;
					memorySequenceItem.isRead  = 0;
				finish_item(memorySequenceItem);	
			end
		endtask : body
	endclass : MemoryResetSequence

	//memory write read sequence
	class MemoryRandomSequence extends uvm_sequence#(MemorySequenceItem);
		`uvm_object_utils(MemoryRandomSequence)

		function new(string name = "MemoryRandomSequence");
			super.new(name);
		endfunction : new

		task body();
			MemorySequenceItem memorySequenceItem;

			repeat (SEQUENCE_ITEM_COUNT) begin
				memorySequenceItem = MemorySequenceItem::type_id::create(.name("memorySequenceItem"));
				
				start_item(memorySequenceItem);
					memorySequenceItem.myRandomize();
				finish_item(memorySequenceItem);	
			end
		endtask : body
	endclass : MemoryRandomSequence

	typedef uvm_sequencer#(MemorySequenceItem) MemorySequencer;

	//memory driver
	class MemoryDriver extends uvm_driver#(MemorySequenceItem);
		`uvm_component_utils(MemoryDriver)

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
		) testInterface;

		int cacheNumber;

		function new(string name = "MemoryDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));

			cacheNumber = 0;
		endfunction : new  

		function void setCacheNumber(int cacheNumber);
			this.cacheNumber = cacheNumber;
		endfunction : setCacheNumber
		
		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
	
			if (!uvm_config_db#(virtual TestInterface#(
																		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
																		.DATA_WIDTH(DATA_WIDTH),
																		.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
																	))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			resetDUT();
			forever begin
				seq_item_port.get_next_item(req);
				drive();
				seq_item_port.item_done();
			end
		endtask : run_phase
		
		virtual task resetDUT();
			if (cacheNumber == 0) begin
				testInterface.reset = 1;
			end

			repeat (2) begin
				@(posedge testInterface.clock);
			end
			
			if (cacheNumber == 0) begin
				testInterface.reset = 0;
			end
			
			wait (testInterface.functionComplete[cacheNumber] == 0);
		endtask : resetDUT

		virtual task drive();
			testInterface.address[cacheNumber] = req.address;

			if (req.isRead == 1) begin
				testInterface.readEnabled[cacheNumber] = 1;
			end else begin
				testInterface.writeEnabled[cacheNumber] = 1;
				testInterface.dataOut[cacheNumber]      = req.data;
			end

			wait (testInterface.functionComplete[cacheNumber] == 1);
			@(posedge testInterface.clock);

			if (req.isRead == 1) begin
				testInterface.readEnabled[cacheNumber] <= 0;
			end else begin
				testInterface.writeEnabled[cacheNumber] <= 0;
			end

			wait (testInterface.functionComplete[cacheNumber] == 0);
			@(posedge testInterface.clock);
		endtask : drive;
	endclass : MemoryDriver
	
	//memory collected item
	class MemoryCollectedItem extends uvm_object;
		bit[ADDRESS_WIDTH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] data;
		bit 											 isRead;
		int 											 cacheNumber;

		`uvm_object_utils_begin(MemoryCollectedItem)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(data, UVM_ALL_ON)
			`uvm_field_int(isRead, UVM_ALL_ON)
			`uvm_field_int(cacheNumber, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "MemoryCollectedItem");
			super.new(.name(name));
		endfunction : new
	endclass : MemoryCollectedItem

	//memory monitor
	class MemoryMonitor extends uvm_monitor;
		`uvm_component_utils(MemoryMonitor)

		uvm_analysis_port#(MemoryCollectedItem) analysisPort;

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
		) testInterface;

		MemoryCollectedItem collectedItem;

		function new(string name = "MemoryMonitor", uvm_component parent);
			super.new(name, parent);
		endfunction : new 

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			analysisPort  = new(.name("analysisPort"), .parent(this));
			collectedItem = MemoryCollectedItem::type_id::create(.name("memoryCollectedItem"));

			if (!uvm_config_db#(virtual TestInterface#(
																		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
																		.DATA_WIDTH(DATA_WIDTH),
																		.NUMBER_OF_CACHES(NUMBER_OF_CACHES)
																	))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTAUL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase	

		virtual task run_phase(uvm_phase phase);
			resetDUT();
			forever begin
				for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
					if (testInterface.functionComplete[i] == 1) begin
						if (testInterface.readEnabled[i] == 1 || testInterface.writeEnabled[i] == 1) begin
							collect(.cacheNumber(i));
							analysisPort.write(collectedItem);
						end
					end
				end
				@(posedge testInterface.clock);
			end
		endtask : run_phase

		virtual task resetDUT();
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				wait (testInterface.functionComplete[i] == 0);
			end
		endtask : resetDUT
			
		virtual task collect(int cacheNumber);
			collectedItem.address = testInterface.address[cacheNumber];
			if (testInterface.readEnabled[cacheNumber] == 1) begin
				collectedItem.isRead = 1;
				collectedItem.data 	 = testInterface.dataIn[cacheNumber];
			end else begin
				collectedItem.isRead = 0;
				collectedItem.data	 = testInterface.dataOut[cacheNumber];
			end
			collectedItem.cacheNumber = cacheNumber;
		endtask : collect
	endclass : MemoryMonitor

	//memory agent
	class MemoryAgent extends uvm_agent;
		`uvm_component_utils(MemoryAgent)

		uvm_analysis_port#(MemoryCollectedItem) analysisPort;

		MemorySequencer sequencer[NUMBER_OF_CACHES];
		MemoryDriver driver[NUMBER_OF_CACHES];
		MemoryMonitor monitor;

		function new(string name = "MemoryAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new
		
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort = new(.name("analysisPort"), .parent(this));
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				sequencer[i] = MemorySequencer::type_id::create(.name($sformatf("sequencer%d", i)), .parent(this));
			end
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				driver[i] = MemoryDriver::type_id::create(.name($sformatf("driver%d", i)), .parent(this));
				driver[i].setCacheNumber(.cacheNumber(i));
			end
			monitor = MemoryMonitor::type_id::create(.name("monitor"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));
			
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				driver[i].seq_item_port.connect(sequencer[i].seq_item_export);
			end
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase
	endclass : MemoryAgent

	//memory scoreboard
	class MemoryScoreboard extends uvm_scoreboard;
		`uvm_component_utils(MemoryScoreboard)

		uvm_analysis_export#(MemoryCollectedItem) analysisExport;
		
		uvm_tlm_analysis_fifo#(MemoryCollectedItem) analysisFifo;

		MemoryCollectedItem collectedItem;

		logic [DATA_WIDTH - 1 : 0] memory[SIZE_IN_WORDS];

		function new(string name = "MemoryScoreboard", uvm_component parent);
			super.new(name, parent);
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));
			
			analysisExport = new(.name("analysisExport"), .parent(this));
			analysisFifo   = new(.name("analysisFifo"), .parent(this));
			collectedItem  = MemoryCollectedItem::type_id::create(.name("collectedItem"));
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
			if (collectedItem.isRead) begin
				if (collectedItem.data != memory[collectedItem.address]) begin
					bit[ADDRESS_WIDTH - 1      : 0] address     = collectedItem.address;
					bit[DATA_WIDTH - 1         : 0] dataMemory  = memory[collectedItem.address];
					bit[DATA_WIDTH - 1         : 0] dataCache   = collectedItem.data;
					bit[CACHE_NUMBER_WIDTH - 1 : 0] cacheNumber = collectedItem.cacheNumber;
					`uvm_error("READ ERROR", $sformatf("CACHE_NUMBER=%x, ADDRESS=%x, EXPECTED=%x, RECEIVED=%x", cacheNumber, address, dataMemory, dataCache))	
				end else begin
					bit[ADDRESS_WIDTH - 1      : 0] address     = collectedItem.address;
					bit[DATA_WIDTH - 1         : 0] dataMemory  = memory[collectedItem.address];
					bit[DATA_WIDTH - 1         : 0] dataCache   = collectedItem.data;
					bit[CACHE_NUMBER_WIDTH - 1 : 0] cacheNumber = collectedItem.cacheNumber;
					
					`uvm_info("READING", $sformatf("CACHE_NUMBER=%x, MEM[%x]=%x, CACHE[%x]=%x",cacheNumber, address, dataMemory, address, dataCache), UVM_LOW)
				end
			end else begin
				bit[ADDRESS_WIDTH - 1      : 0] address     = collectedItem.address;
				bit[DATA_WIDTH - 1         : 0] dataCache   = collectedItem.data;
				bit[CACHE_NUMBER_WIDTH - 1 : 0] cacheNumber = collectedItem.cacheNumber;

				`uvm_info("WRITING", $sformatf("CACHE_NUMBER=%x, MEM[%x] = %x", cacheNumber,  address, dataCache), UVM_LOW)
				memory[collectedItem.address] = collectedItem.data;
			end	
		endfunction : checkBehaviour 
	endclass : MemoryScoreboard

	//memory environment
	class MemoryEnvironment extends uvm_env;
		`uvm_component_utils(MemoryEnvironment)

		MemoryAgent agent;
		MemoryScoreboard scoreboard;

		function new(string name = "MemoryEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			agent      = MemoryAgent::type_id::create(.name("agent"), .parent(this));
			scoreboard = MemoryScoreboard::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			agent.analysisPort.connect(scoreboard.analysisExport);
		endfunction : connect_phase
	endclass : MemoryEnvironment

	//memory test
	class MemoryTest extends uvm_test;
		`uvm_component_utils(MemoryTest)

		MemoryEnvironment environment;

		function new(string name = "MemoryTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));
			environment = MemoryEnvironment::type_id::create(.name("environment"), .parent(this));
		endfunction : build_phase
		
		virtual function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(.phase(phase));

			this.print();
			factory.print();
		endfunction : end_of_elaboration_phase

		virtual task run_phase(uvm_phase phase);
			MemoryResetSequence memoryResetSequence;	
			MemoryRandomSequence memoryRandomSequence[NUMBER_OF_CACHES];

			memoryResetSequence  = MemoryResetSequence::type_id::create(.name("memoryResetSequence"));
			for (int i = 0; i < NUMBER_OF_CACHES; i++) begin
				memoryRandomSequence[i] = MemoryRandomSequence::type_id::create(.name("memoryRandomSequence"));
			end

			phase.raise_objection(.obj(this));
				memoryResetSequence.start(environment.agent.sequencer[0]);
				fork
					memoryRandomSequence[0].start(environment.agent.sequencer[0]);
					memoryRandomSequence[1].start(environment.agent.sequencer[1]);
					memoryRandomSequence[2].start(environment.agent.sequencer[2]);
					memoryRandomSequence[3].start(environment.agent.sequencer[3]);
				join
			phase.drop_objection(.obj(this));
		endtask : run_phase
	endclass : MemoryTest
endpackage : testPackage
