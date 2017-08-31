package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;

	localparam ADDRESS_WIDTH       = 16;
	localparam DATA_WIDTH          = 16;
	localparam SIZE                = 1024;
	localparam SEQUENCE_ITEM_COUNT = 50;
	localparam TEST_INTERFACE      = "TestInterface";

	//memory sequence item
	class MemorySequenceItem extends BasicSequenceItem;
		
		bit [ADDRESS_WIDTH - 1 	: 0] address;
		bit [DATA_WIDTH - 1			: 0] data;
		bit													 isRead;

		`uvm_object_utils_begin(MemorySequenceItem)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(data, UVM_ALL_ON)
			`uvm_field_int(isRead, UVM_ALL_ON)
		`uvm_object_utils_end
		
		function new(string name = "MemoryTransaction");
			super.new(name);
		endfunction : new

		virtual function void myRandomize();
			address	= $urandom_range(SIZE - 1, 0);
			data		= $urandom();
			isRead	=	$urandom();
		endfunction : myRandomize
	endclass : MemorySequenceItem

	//memory sequences
	//memory reset sequence
	class MemoryResetSequence extends uvm_sequence#(MemorySequenceItem);

		`uvm_object_utils(MemoryResetSequence)

		function new(string name = "MemoryResetSequence");
			super.new(name);
		endfunction : new

		virtual task body();
			MemorySequenceItem memorySequenceItem = MemorySequenceItem::type_id::create(.name("memorySequenceItem"));

			for (int i = 0; i < SIZE; i++) begin
				start_item(memorySequenceItem);
					memorySequenceItem.address = i;
					memorySequenceItem.data    = 0;
					memorySequenceItem.isRead  = 0;
				finish_item(memorySequenceItem);	
			end
		endtask : body
	endclass : MemoryResetSequence

	//memory write read sequence
	class MemoryWriteReadSequence extends uvm_sequence#(MemorySequenceItem);

		`uvm_object_utils(MemoryWriteReadSequence)
		int addressQueue[$];

		function new(string name = "MemorySequence");
			super.new(name);
		endfunction : new

		task body();
			MemorySequenceItem memorySequenceItem;

			repeat (SEQUENCE_ITEM_COUNT) begin
				memorySequenceItem = MemorySequenceItem::type_id::create(.name("memorySequenceItem"));
				
				start_item(memorySequenceItem);
					memorySequenceItem.myRandomize();
					addressQueue.push_back(memorySequenceItem.address);
					memorySequenceItem.isRead = 0;
				finish_item(memorySequenceItem);	
			end

			repeat (SEQUENCE_ITEM_COUNT) begin
				memorySequenceItem = MemorySequenceItem::type_id::create(.name("memorySequenceItem"));
				
				start_item(memorySequenceItem);
					memorySequenceItem.address = addressQueue.pop_front();
					memorySequenceItem.isRead  = 1;
				finish_item(memorySequenceItem);	
			end
		endtask : body
	endclass : MemoryWriteReadSequence
	
	//memory virtual sequence
	class MemoryVirtualSequence extends BasicSequence#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT));

		`uvm_object_utils(MemoryVirtualSequence)

		function new(string name = "MemorySequence");
			super.new(name);
		endfunction : new

		virtual task body();
			MemoryResetSequence memoryResetSequence         = MemoryResetSequence::type_id::create("memoryResetSequence");
			MemoryWriteReadSequence memoryWriteReadSequence = MemoryWriteReadSequence::type_id::create("memoryWriteReadSequence");

			memoryResetSequence.start(.sequencer(m_sequencer), .parent_sequence(this));
			memoryWriteReadSequence.start(.sequencer(m_sequencer), .parent_sequence(this));
		endtask : body
	endclass : MemoryVirtualSequence

	//memory driver
	class MemoryDriver extends BasicDriver;
		
		`uvm_component_utils(MemoryDriver)

		protected virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH)
		) testInterface;

		MemorySequenceItem sequenceItem;

		function new(string name = "MemoryDriver", uvm_component parent);
			super.new(name, parent);
		endfunction : new  
		
		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if (!uvm_config_db#(virtual TestInterface#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase
		
		virtual task resetDUT();
			wait (testInterface.memoryInterface.functionComplete == 0);
		endtask : resetDUT

		virtual task drive();
			$cast(sequenceItem, req);
			testInterface.memoryInterface.address = sequenceItem.address;

			if (sequenceItem.isRead == 1) begin
				testInterface.memoryInterface.readEnabled = 1;
			end else begin
				testInterface.memoryInterface.writeEnabled = 1;
				testInterface.memoryInterface.dataOut 	 	 = sequenceItem.data;
			end

			while (testInterface.memoryInterface.functionComplete != 1) begin
				@(posedge testInterface.clock);
			end

			if (sequenceItem.isRead == 1) begin
				testInterface.memoryInterface.readEnabled = 0;
			end else begin
				testInterface.memoryInterface.writeEnabled = 0;
			end

			while (testInterface.memoryInterface.functionComplete != 0) begin
				@(posedge testInterface.clock);
			end
		endtask : drive;
	endclass : MemoryDriver
	
	//memory collected item
	class MemoryCollectedItem extends BasicCollectedItem;
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
	class MemoryMonitor extends BasicMonitor;
		`uvm_component_utils(MemoryMonitor)

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH), 
			.DATA_WIDTH(DATA_WIDTH)
		) testInterface;

		MemoryCollectedItem collectedItem;
		
		function new(string name = "MemoryMonitor", uvm_component parent);
			super.new(name, parent);
		endfunction : new 

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if (!uvm_config_db#(virtual TestInterface#(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTAUL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase	

		virtual task resetDUT();
			wait (testInterface.memoryInterface.functionComplete == 0);
		endtask : resetDUT
			
		virtual task collect();
			$cast(collectedItem, super.collectedItem);

			while (testInterface.memoryInterface.functionComplete != 1) begin
				@(posedge testInterface.clock);
			end

			collectedItem.address = testInterface.memoryInterface.address;
			if (testInterface.memoryInterface.readEnabled == 1) begin
				collectedItem.isRead = 1;
				collectedItem.data 	 = testInterface.memoryInterface.dataIn;
			end else begin
				collectedItem.isRead = 0;
				collectedItem.data	 = testInterface.memoryInterface.dataOut;
			end

			while (testInterface.memoryInterface.functionComplete != 0) begin
				@(posedge testInterface.clock);
			end
		endtask : collect
	endclass : MemoryMonitor

	//s=memory scoreboard
	class MemoryScoreboard extends BasicScoreboard;
		`uvm_component_utils(MemoryScoreboard)

		logic [DATA_WIDTH - 1 : 0] memory[SIZE];

		MemoryCollectedItem collectedItem;

		function new(string name = "MemoryScoreboard", uvm_component parent);
			super.new(name, parent);
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			for (int i = 0; i < SIZE; i++) begin
				memory[i] = 0;
			end
		endfunction : build_phase

		virtual function void checkBehaviour();
			$cast(collectedItem, super.collectedItem);

			if (collectedItem.isRead) begin
				if (collectedItem.data != memory[collectedItem.address]) begin
					`uvm_info("READ ERROR", $sformatf("ADDRESS: %d, VALUE: %d, VALUE: %d", collectedItem.address, memory[collectedItem.address], collectedItem.data), UVM_LOW)	
				end else begin
					`uvm_info("TEST OK", $sformatf("MEM[%d]=%d, RAM[%d]=%d", collectedItem.address, memory[collectedItem.address], collectedItem.address, collectedItem.data), UVM_LOW)
				end
			end else begin
				`uvm_info("WRITING", $sformatf("MEM[%d] = %d", collectedItem.address, collectedItem.data), UVM_LOW)
				memory[collectedItem.address] = collectedItem.data;
			end	
		endfunction : checkBehaviour 
	endclass : MemoryScoreboard

	//memory test
	class MemoryTest extends BasicTest#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT));
		`uvm_component_utils(MemoryTest)

		function new(string name = "MemoryTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(MemorySequenceItem::get_type(), 1);
			BasicSequence#(.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT))::type_id::set_type_override(MemoryVirtualSequence::get_type(), 1);
			BasicDriver::type_id::set_type_override(MemoryDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(MemoryCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(MemoryMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(MemoryScoreboard::get_type(), 1);
		endfunction : registerReplacements;		
	endclass : MemoryTest
endpackage : testPackage
