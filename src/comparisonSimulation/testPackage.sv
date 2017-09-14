package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	localparam ADDRESS_WIDTH       = 8;
	localparam DATA_WIDTH          = 8;
	localparam TAG_WIDTH           = 2;
	localparam INDEX_WIDTH         = 2;
	localparam OFFSET_WIDTH        = 4;
	localparam SET_ASSOCIATIVITY   = 1;
	localparam NUMBER_OF_DEVICES   = 4;
	localparam DEVICE_NUMBER_WIDTH = $clog2(NUMBER_OF_DEVICES);
	localparam RAM_DELAY           = 8;
	localparam SEQUENCE_ITEM_COUNT = 100;

	localparam NUMBER_OF_BLOCKS = 16;
	localparam SIZE_IN_WORDS    = (1 << OFFSET_WIDTH) * NUMBER_OF_BLOCKS;

	localparam MIN_ADJACENT_ADDRESSES = SEQUENCE_ITEM_COUNT / 10;
	localparam MAX_ADJACENT_ADDRESSES = SEQUENCE_ITEM_COUNT / 2;
	localparam MIN_NUMBER_OF_REPETITIONS = 1;
	localparam MAX_NUMBER_OF_REPETITIONS = SEQUENCE_ITEM_COUNT;
	 
	localparam BASIC  = "BASIC";
	localparam WBI    = "WBI";
	localparam MESI   = "MESI";
	localparam MOESIF = "MOESIF";

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
	class MemoryCPUSequence extends uvm_sequence#(MemorySequenceItem);
		bit[ADDRESS_WIDTH - 1 : 0] address[SEQUENCE_ITEM_COUNT];
		bit[DATA_WIDTH - 1    : 0] data[SEQUENCE_ITEM_COUNT];
		bit 											 isRead[SEQUENCE_ITEM_COUNT];

		`uvm_object_utils_begin(MemoryCPUSequence)
			`uvm_field_sarray_int(address, UVM_ALL_ON)
			`uvm_field_sarray_int(data, UVM_ALL_ON)
			`uvm_field_sarray_int(isRead, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "MemoryCPUSequence");
			super.new(name);
		endfunction : new

		virtual function void myRandomize();
			int fillCount = 0;
			while (fillCount < SEQUENCE_ITEM_COUNT) begin
				bit[ADDRESS_WIDTH - 1 : 0] address         = $urandom_range(SIZE_IN_WORDS - 1, 0);
				bit[DATA_WIDTH - 1    : 0] data            = $urandom();
				bit 											 isRead          = $urandom();
				int 											 adjacentCount   = $urandom_range(MAX_ADJACENT_ADDRESSES, MIN_ADJACENT_ADDRESSES);
				int												 repetitionCount = $urandom_range(MAX_NUMBER_OF_REPETITIONS, MIN_NUMBER_OF_REPETITIONS);

				for (int i = 0; i < repetitionCount && fillCount < SEQUENCE_ITEM_COUNT; i++) begin
					for (int j = 0; j < adjacentCount && fillCount < SEQUENCE_ITEM_COUNT; j++, fillCount++) begin
						this.address[fillCount] = (address + j) % SIZE_IN_WORDS;
						this.data[fillCount]    = data;
						this.isRead[fillCount]  = isRead;
					end
				end
			end
		endfunction : myRandomize

		task body();
			MemorySequenceItem memorySequenceItem;

			for (int i = 0; i < SEQUENCE_ITEM_COUNT; i++) begin
				memorySequenceItem = MemorySequenceItem::type_id::create(.name("memorySequenceItem"));
				
				start_item(memorySequenceItem);
					memorySequenceItem.address = this.address[i];
					memorySequenceItem.data    = this.data[i];
					memorySequenceItem.isRead  = this.isRead[i];
				finish_item(memorySequenceItem);	
			end
		endtask : body
	endclass : MemoryCPUSequence

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
			
			dutInterface.memoryInterface.readEnabled = 0;
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
		string testInterfaceName;

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
		) testInterface, string testInterfaceName);
	
			this.testInterface     = testInterface;
			this.testInterfaceName = testInterfaceName;

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

			`uvm_info(testInterfaceName, $sformatf("NUMBER OF CLOCKS IS %d", testInterface.clockCounter), UVM_LOW)
		endfunction : report_phase
	endclass : MemoryEnvironment

	//memory test
	class MemoryTest extends uvm_test;
		`uvm_component_utils(MemoryTest)

		MemoryEnvironment basicEnvironment, writeBackInvalidateEnvironment, mesiEnvironment, moesifEnvironment;

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH),
			.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
		) basicTestInterface, writeBackInvalidateTestInterface, mesiTestInterface, moesifTestInterface;

		function new(string name = "MemoryTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
																		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
																		.DATA_WIDTH(DATA_WIDTH),
																		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
																	))::get(this, "", BASIC, basicTestInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end

			if (!uvm_config_db#(virtual TestInterface#(
																		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
																		.DATA_WIDTH(DATA_WIDTH),
																		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
																	))::get(this, "", WBI, writeBackInvalidateTestInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end

			if (!uvm_config_db#(virtual TestInterface#(
																		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
																		.DATA_WIDTH(DATA_WIDTH),
																		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
																	))::get(this, "", MESI, mesiTestInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end

			if (!uvm_config_db#(virtual TestInterface#(
																		.ADDRESS_WIDTH(ADDRESS_WIDTH), 
																		.DATA_WIDTH(DATA_WIDTH),
																		.NUMBER_OF_DEVICES(NUMBER_OF_DEVICES)
																	))::get(this, "", MOESIF, moesifTestInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end

			basicEnvironment               = MemoryEnvironment::type_id::create(.name("basicEnvironment"), .parent(this));
			writeBackInvalidateEnvironment = MemoryEnvironment::type_id::create(.name("writeBackInvalidateEnvironment"), .parent(this));
			mesiEnvironment                = MemoryEnvironment::type_id::create(.name("mesiEnvironment"), .parent(this));
			moesifEnvironment              = MemoryEnvironment::type_id::create(.name("moesifEnvironment"), .parent(this));
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(.phase(phase));

			basicEnvironment.setTestInterface(.testInterface(basicTestInterface), .testInterfaceName(BASIC));
			writeBackInvalidateEnvironment.setTestInterface(.testInterface(writeBackInvalidateTestInterface), .testInterfaceName(WBI));
			mesiEnvironment.setTestInterface(.testInterface(mesiTestInterface), .testInterfaceName(MESI));
			moesifEnvironment.setTestInterface(.testInterface(moesifTestInterface), .testInterfaceName(MOESIF));
		endfunction : connect_phase
		
		virtual function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(.phase(phase));

			this.print();
			factory.print();
		endfunction : end_of_elaboration_phase

		virtual task run_phase(uvm_phase phase);
			MemoryResetSequence memoryResetSequence;	
			MemoryCPUSequence memoryCPUSequence[NUMBER_OF_DEVICES];

			memoryResetSequence  = MemoryResetSequence::type_id::create(.name("memoryResetSequence"));
			for (int i = 0; i < NUMBER_OF_DEVICES; i++) begin
				memoryCPUSequence[i] = MemoryCPUSequence::type_id::create(.name("memoryCPUSequence"));
				memoryCPUSequence[i].myRandomize();
			end

			basicTestInterface.testDone               = 1;
			writeBackInvalidateTestInterface.testDone = 1;
			mesiTestInterface.testDone                = 1;
			moesifTestInterface.testDone              = 1;

			phase.raise_objection(.obj(this));
				`uvm_info(BASIC, "TEST START", UVM_LOW)
				memoryResetSequence.start(basicEnvironment.agent[0].sequencer);
				basicTestInterface.testDone = 0;
				fork
					memoryCPUSequence[0].start(basicEnvironment.agent[0].sequencer);
					memoryCPUSequence[1].start(basicEnvironment.agent[1].sequencer);
					memoryCPUSequence[2].start(basicEnvironment.agent[2].sequencer);
					memoryCPUSequence[3].start(basicEnvironment.agent[3].sequencer);
				join
				basicTestInterface.testDone = 1;
				`uvm_info(BASIC, "TEST END", UVM_LOW)

				`uvm_info(WBI, "TEST START", UVM_LOW)
				memoryResetSequence.start(writeBackInvalidateEnvironment.agent[0].sequencer);
				writeBackInvalidateTestInterface.testDone = 0;
				fork
					memoryCPUSequence[0].start(writeBackInvalidateEnvironment.agent[0].sequencer);
					memoryCPUSequence[1].start(writeBackInvalidateEnvironment.agent[1].sequencer);
					memoryCPUSequence[2].start(writeBackInvalidateEnvironment.agent[2].sequencer);
					memoryCPUSequence[3].start(writeBackInvalidateEnvironment.agent[3].sequencer);
				join
				writeBackInvalidateTestInterface.testDone = 1;
				`uvm_info(WBI, "TEST END", UVM_LOW)

				`uvm_info(MESI, "TEST START", UVM_LOW)
				memoryResetSequence.start(mesiEnvironment.agent[0].sequencer);
				mesiTestInterface.testDone = 0;
				fork
					memoryCPUSequence[0].start(mesiEnvironment.agent[0].sequencer);
					memoryCPUSequence[1].start(mesiEnvironment.agent[1].sequencer);
					memoryCPUSequence[2].start(mesiEnvironment.agent[2].sequencer);
					memoryCPUSequence[3].start(mesiEnvironment.agent[3].sequencer);
				join
				mesiTestInterface.testDone = 1;
				`uvm_info(MESI, "TEST END", UVM_LOW)

				`uvm_info(MOESIF, "TEST START", UVM_LOW)
				memoryResetSequence.start(moesifEnvironment.agent[0].sequencer);
				moesifTestInterface.testDone = 0;
				fork
					memoryCPUSequence[0].start(moesifEnvironment.agent[0].sequencer);
					memoryCPUSequence[1].start(moesifEnvironment.agent[1].sequencer);
					memoryCPUSequence[2].start(moesifEnvironment.agent[2].sequencer);
					memoryCPUSequence[3].start(moesifEnvironment.agent[3].sequencer);
				join
				moesifTestInterface.testDone = 1;
				`uvm_info(MOESIF, "TEST END", UVM_LOW)
			phase.drop_objection(.obj(this));

		endtask : run_phase
	endclass : MemoryTest
endpackage : testPackage
