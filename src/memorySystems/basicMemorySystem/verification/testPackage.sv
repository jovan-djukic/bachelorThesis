package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	localparam ADDRESS_WIDTH       = 8;
	localparam DATA_WIDTH          = 8;
	localparam NUMBER_OF_DEVICES   = 4;
	localparam DEVICE_NUMBER_WIDTH = $clog2(NUMBER_OF_DEVICES);
	localparam RAM_DELAY           = 16;
	localparam SEQUENCE_ITEM_COUNT = 400;
	localparam IS_TEST             = 1;
	localparam TEST_INTERFACE      = "TestInterface";

	localparam SIZE_IN_WORDS    = 1 << ADDRESS_WIDTH;

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

		virtual DUTInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH)
		) dutInterface;

		function new(string name = "MemoryDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new  

		function void setDUTInterface(virtual DUTInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH)
		) dutInterface);
			this.dutInterface = dutInterface;
		endfunction : setDUTInterface

		virtual task run_phase(uvm_phase phase);
			resetDUT();
			forever begin
				seq_item_port.get_next_item(req);
				drive();
				seq_item_port.item_done();
			end
		endtask : run_phase
		
		virtual task resetDUT();
			wait (dutInterface.reset == 1);
			wait (dutInterface.reset == 0);
			
			dutInterface.memoryInterface.readEnabled  = 0;
			dutInterface.memoryInterface.writeEnabled = 0;

			wait (dutInterface.memoryInterface.functionComplete == 0);
		endtask : resetDUT

		virtual task drive();
			dutInterface.memoryInterface.address = req.address;

			if (req.isRead == 1) begin
				dutInterface.memoryInterface.readEnabled = 1;
			end else begin
				dutInterface.memoryInterface.writeEnabled = 1;
				dutInterface.memoryInterface.dataOut      = req.data;
			end

			while (dutInterface.memoryInterface.functionComplete != 1) begin
				@(posedge dutInterface.clock);	
			end

			if (req.isRead == 1) begin
				dutInterface.memoryInterface.readEnabled <= 0;
			end else begin
				dutInterface.memoryInterface.writeEnabled <= 0;
			end

			while (dutInterface.memoryInterface.functionComplete != 0) begin
				@(posedge dutInterface.clock);	
			end
		endtask : drive;
	endclass : MemoryDriver
	
	//memory collected item
	class MemoryCollectedItem extends uvm_object;
		bit[ADDRESS_WIDTH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] data;
		bit 											 isRead;

		`uvm_object_utils_begin(MemoryCollectedItem)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(data, UVM_ALL_ON)
			`uvm_field_int(isRead, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "MemoryCollectedItem");
			super.new(.name(name));
		endfunction : new
	endclass : MemoryCollectedItem

	//memory monitor
	class MemoryMonitor extends uvm_monitor;
		`uvm_component_utils(MemoryMonitor)

		uvm_analysis_port#(MemoryCollectedItem) analysisPort;

		virtual DUTInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH)
		) dutInterface;

		MemoryCollectedItem collectedItem;

		function new(string name = "MemoryMonitor", uvm_component parent);
			super.new(name, parent);
		endfunction : new 

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			analysisPort  = new(.name("analysisPort"), .parent(this));
			collectedItem = MemoryCollectedItem::type_id::create(.name("memoryCollectedItem"));
		endfunction : build_phase	

		function void setDUTInterface(virtual DUTInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH)
		) dutInterface);
			this.dutInterface = dutInterface;
		endfunction : setDUTInterface

		virtual task run_phase(uvm_phase phase);
			resetDUT();
			forever begin
				collect();
				analysisPort.write(collectedItem);
			end
		endtask : run_phase

		virtual task resetDUT();
			wait (dutInterface.reset == 1);
			wait (dutInterface.reset == 0);
			wait (dutInterface.memoryInterface.functionComplete == 0);
		endtask : resetDUT
			
		virtual task collect();
			while (dutInterface.memoryInterface.functionComplete != 1) begin
				@(posedge dutInterface.clock);	
			end

			collectedItem.address = dutInterface.memoryInterface.address;
			if (dutInterface.memoryInterface.readEnabled == 1) begin
				collectedItem.isRead = 1;
				collectedItem.data 	 = dutInterface.memoryInterface.dataIn;
			end else begin
				collectedItem.isRead = 0;
				collectedItem.data	 = dutInterface.memoryInterface.dataOut;
			end

			while (dutInterface.memoryInterface.functionComplete != 0) begin
				@(posedge dutInterface.clock);	
			end
		endtask : collect
	endclass : MemoryMonitor

	//memory agent
	class MemoryAgent extends uvm_agent;
		`uvm_component_utils(MemoryAgent)

		uvm_analysis_port#(MemoryCollectedItem) analysisPort;

		MemorySequencer sequencer;
		MemoryDriver driver;
		MemoryMonitor monitor;

		function new(string name = "MemoryAgent", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new
		
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			analysisPort = new(.name("analysisPort"), .parent(this));
			sequencer = MemorySequencer::type_id::create(.name("sequencer"), .parent(this));
			driver    = MemoryDriver::type_id::create(.name("driver"), .parent(this));
			monitor   = MemoryMonitor::type_id::create(.name("monitor"), .parent(this));
		endfunction : build_phase
		
		function void setDUTInterface(virtual DUTInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH)
		) dutInterface);
			driver.setDUTInterface(.dutInterface(dutInterface));
			monitor.setDUTInterface(.dutInterface(dutInterface));	
		endfunction : setDUTInterface

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));
			
			driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase
	endclass : MemoryAgent

	//memory scoreboard
	class MemoryScoreboard extends uvm_scoreboard;
		`uvm_component_utils(MemoryScoreboard)

		uvm_analysis_export#(MemoryCollectedItem) analysisExport[NUMBER_OF_DEVICES];
		
		uvm_tlm_analysis_fifo#(MemoryCollectedItem) analysisFifo[NUMBER_OF_DEVICES];


		logic [DATA_WIDTH - 1 : 0] memory[SIZE_IN_WORDS];

		function new(string name = "MemoryScoreboard", uvm_component parent);
			super.new(name, parent);
			
			for (int i = 0; i < SIZE_IN_WORDS; i++) begin
				memory[i] = 0;
			end
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));
			
			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				analysisExport[i] = new(.name($sformatf("analysisExport%d", i)), .parent(this));
				analysisFifo[i]   = new(.name($sformatf("analysisFifo%d", i)), .parent(this));
			end
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				analysisExport[i].connect(analysisFifo[i].analysis_export);
			end
		endfunction : connect_phase

		virtual task run();
			MemoryCollectedItem collectedItem;
			bit[DEVICE_NUMBER_WIDTH - 1 : 0] deviceNumber;
			collectedItem  = MemoryCollectedItem::type_id::create(.name("collectedItem"));

			forever begin
				#1;
				deviceNumber = 0;
				for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
					if (analysisFifo[i].try_get(collectedItem) == 1) begin
						checkBehaviour(.collectedItem(collectedItem), .deviceNumber(deviceNumber));
					end
					deviceNumber++;
				end
			end
		endtask : run

		virtual function void checkBehaviour(MemoryCollectedItem collectedItem, bit[DEVICE_NUMBER_WIDTH - 1 : 0] deviceNumber);
			if (collectedItem.isRead) begin
				if (collectedItem.data != memory[collectedItem.address]) begin
					bit[ADDRESS_WIDTH - 1      : 0] address     = collectedItem.address;
					bit[DATA_WIDTH - 1         : 0] dataMemory  = memory[collectedItem.address];
					bit[DATA_WIDTH - 1         : 0] dataDevice   = collectedItem.data;
					`uvm_error("READ ERROR", $sformatf("DEVICE_NUMBER=%x, ADDRESS=%x, EXPECTED=%x, RECEIVED=%x", deviceNumber, address, dataMemory, dataDevice))	
				end else begin
					bit[ADDRESS_WIDTH - 1      : 0] address     = collectedItem.address;
					bit[DATA_WIDTH - 1         : 0] dataMemory  = memory[collectedItem.address];
					bit[DATA_WIDTH - 1         : 0] dataDevice   = collectedItem.data;
					
					`uvm_info("READING", $sformatf("DEVICE_NUMBER=%x, MEM[%x]=%x, DEVICE[%x]=%x",deviceNumber, address, dataMemory, address, dataDevice), UVM_LOW)
				end
			end else begin
				bit[ADDRESS_WIDTH - 1      : 0] address     = collectedItem.address;
				bit[DATA_WIDTH - 1         : 0] dataDevice   = collectedItem.data;

				`uvm_info("WRITING", $sformatf("DEVICE_NUMBER=%x, MEM[%x]=%x", deviceNumber,  address, dataDevice), UVM_LOW)
				memory[collectedItem.address] = collectedItem.data;
			end	
		endfunction : checkBehaviour 
	endclass : MemoryScoreboard

	//memory environment
	class MemoryEnvironment extends uvm_env;
		`uvm_component_utils(MemoryEnvironment)

		MemoryAgent agent[NUMBER_OF_DEVICES];
		MemoryScoreboard scoreboard;

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) testInterface;

		function new(string name = "MemoryEnvironment", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				agent[i] = MemoryAgent::type_id::create(.name($sformatf("agent%d", i)), .parent(this));
			end
			scoreboard = MemoryScoreboard::type_id::create(.name("scoreboard"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				agent[i].analysisPort.connect(scoreboard.analysisExport[i]);
			end
		endfunction : connect_phase

		virtual function void setTestInterface(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) testInterface);
	
			this.testInterface = testInterface;

			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				agent[i].setDUTInterface(.dutInterface(testInterface.dutInterface[i]));
			end
		endfunction : setTestInterface

		task run_phase(uvm_phase phase);
			super.run_phase(.phase(phase));

			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
		endtask : run_phase

		virtual function void report_phase(uvm_phase phase);
			super.report_phase(.phase(phase));

			`uvm_info("PERFORMANCE", $sformatf("NUMBER OF CLOCKS IS %d", testInterface.clockCounter), UVM_LOW)
		endfunction : report_phase
	endclass : MemoryEnvironment

	//memory test
	class MemoryTest extends uvm_test;
		`uvm_component_utils(MemoryTest)

		MemoryEnvironment environment;

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) testInterface;

		function new(string name = "MemoryTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
																		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
																		.DATA_WIDTH(DATA_WIDTH),
																		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
																	))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end

			environment = MemoryEnvironment::type_id::create(.name("environment"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			environment.setTestInterface(.testInterface(testInterface));
		endfunction : connect_phase
		
		virtual function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(.phase(phase));

			this.print();
			factory.print();
		endfunction : end_of_elaboration_phase

		virtual task run_phase(uvm_phase phase);
			MemoryRandomSequence memoryRandomSequence[NUMBER_OF_DEVICES];

			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				memoryRandomSequence[i] = MemoryRandomSequence::type_id::create(.name("memoryRandomSequence"));
			end

			testInterface.testDone = 1;
			phase.raise_objection(.obj(this));
				testInterface.testDone = 0;
				fork
					memoryRandomSequence[0].start(environment.agent[0].sequencer);
					memoryRandomSequence[1].start(environment.agent[1].sequencer);
					memoryRandomSequence[2].start(environment.agent[2].sequencer);
					memoryRandomSequence[3].start(environment.agent[3].sequencer);
				join
				testInterface.testDone = 1;
			phase.drop_objection(.obj(this));

		endtask : run_phase
	endclass : MemoryTest
endpackage : testPackage
