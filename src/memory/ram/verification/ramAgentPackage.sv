package ramAgentPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//Transaction
	class MemoryTransaction #(
		int ADDRESS_WIDTH	= 32,
		int DATA_WIDTH		= 32,
		int SIZE					= 1024
	) extends uvm_sequence_item;
		
		bit [ADDRESS_WIDTH - 1 	: 0] address;
		bit [DATA_WIDTH - 1			: 0] data;
		bit													 isRead;

		`uvm_object_utils_begin(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE))
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_int(data, UVM_ALL_ON)
			`uvm_field_int(isRead, UVM_ALL_ON)
		`uvm_object_utils_end
		
		function new(string name = "MemoryTransaction");
			super.new(name);
		endfunction : new

		function void myRandomize();
			address	= $urandom_range(SIZE - 1, 0);
			data		= $urandom();
			isRead	=	$urandom();
		endfunction : myRandomize
	endclass

	//Sequencer
	class MemorySequencer#(
		int ADDRESS_WIDTH = 32,
		int DATA_WIDTH		= 32,
		int SIZE					= 1024
	) extends uvm_sequencer#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE));
		
		`uvm_component_utils(MemorySequencer#(ADDRESS_WIDTH, DATA_WIDTH, SIZE))

		function new(string name = "MemorySequencer", uvm_component parent);
			super.new(name, parent);
		endfunction : new
	endclass : MemorySequencer

	//Sequences
	//RestartSequence
	class MemoryResetSequence #(
		int ADDRESS_WIDTH		= 32,
		int DATA_WIDTH			= 32,
		int SIZE						= 1024
	) extends uvm_sequence#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE));

		`uvm_object_utils(MemoryResetSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE))

		function new(string name = "MemorySequence");
			super.new(name);

			do_not_randomize	=	1'b1;
		endfunction : new

		task body();
			MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) memoryTransaction;

			for (int i = 0; i < SIZE; i++) begin
				memoryTransaction	=	MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::type_id::create("MemoryTransaction");
				
				start_item(memoryTransaction);
					memoryTransaction.address = i;
					memoryTransaction.data 		= 0;
					memoryTransaction.isRead	= 0;
				finish_item(memoryTransaction);	
			end
		endtask : body
	endclass : MemoryResetSequence

	//WriteReadSequence
	class MemoryWriteReadSequence #(
		int ADDRESS_WIDTH		= 32,
		int DATA_WIDTH			= 32,
		int SIZE						= 1024,
		int SEQUENCE_COUNT	= 50
	) extends uvm_sequence#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE));

		`uvm_object_utils(MemoryWriteReadSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE, SEQUENCE_COUNT))
		int addressQueue[$];

		function new(string name = "MemorySequence");
			super.new(name);

			do_not_randomize	=	1'b1;
		endfunction : new

		task body();
			MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) memoryTransaction;

			repeat (SEQUENCE_COUNT) begin
				memoryTransaction	=	MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::type_id::create("MemoryTransaction");
				
				start_item(memoryTransaction);
					memoryTransaction.myRandomize();
					addressQueue.push_back(memoryTransaction.address);
					memoryTransaction.isRead = 0;
				finish_item(memoryTransaction);	
			end

			repeat (SEQUENCE_COUNT) begin
				memoryTransaction	=	MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::type_id::create("MemoryTransaction");
				
				start_item(memoryTransaction);
					memoryTransaction.address = addressQueue.pop_front();
					memoryTransaction.isRead	= 1;
				finish_item(memoryTransaction);	
			end
		endtask : body
	endclass : MemoryWriteReadSequence
	
	//Virtual Sequence
	class MemoryVirtualSequence #(
		int ADDRESS_WIDTH		= 32,
		int DATA_WIDTH			= 32,
		int SIZE						= 1024,
		int SEQUENCE_COUNT	= 50
	) extends uvm_sequence#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE));

		`uvm_object_utils(MemoryVirtualSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE, SEQUENCE_COUNT))

		MemorySequencer#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) sequencer;

		function new(string name = "MemorySequence");
			super.new(name);

			do_not_randomize	=	1'b1;
		endfunction : new

		task body();
			MemoryResetSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) memoryResetSequence	= MemoryResetSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::
																																									type_id::create("MemoryResetSequence");	
			MemoryWriteReadSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE, SEQUENCE_COUNT) memoryWriteReadSequence = MemoryWriteReadSequence#(ADDRESS_WIDTH, DATA_WIDTH, SIZE, SEQUENCE_COUNT)::type_id::create("MemoryWriteReadSequence");

			`uvm_info("SEQUENCE::", "SEQUENCE STARTING", UVM_LOW)
			memoryResetSequence.start(.sequencer(sequencer), .parent_sequence(this));
			memoryWriteReadSequence.start(.sequencer(sequencer), .parent_sequence(this));
		endtask : body
	endclass : MemoryVirtualSequence


	//Driver
	class MemoryDriver #(
		int ADDRESS_WIDTH = 32,
		int DATA_WIDTH 		= 32,
		int SIZE					= 1024
	) extends uvm_driver#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE));
		
		`uvm_component_utils(MemoryDriver#(ADDRESS_WIDTH, DATA_WIDTH, SIZE))

		protected virtual MemoryInterface#(ADDRESS_WIDTH, DATA_WIDTH) memoryInterface;

		function new(string name = "MemoryDriver", uvm_component parent);
			super.new(name, parent);
		endfunction : new  
		
		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if (!uvm_config_db#(virtual MemoryInterface#(ADDRESS_WIDTH, DATA_WIDTH))::get(this, "", "MemoryInterface", memoryInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			repeat(4) @(posedge memoryInterface.clock);
			forever begin
				seq_item_port.get_next_item(req);
				drive();
				seq_item_port.item_done();
			end
		endtask : run_phase

		virtual task drive();
			memoryInterface.address = req.address;

			if (req.isRead == 1) begin
				memoryInterface.readEnabled <= 1;
			end else begin
				memoryInterface.writeEnabled <= 1;
				memoryInterface.dataOut 	 <= req.data;
			end

			while (memoryInterface.functionComplete != 1) begin
				@(posedge memoryInterface.clock);
			end

			if (req.isRead == 1) begin
				memoryInterface.readEnabled <= 0;
				req.data										<= memoryInterface.dataIn;
			end else begin
				memoryInterface.writeEnabled <= 0;
			end

			while (memoryInterface.functionComplete != 0) begin
				@(posedge memoryInterface.clock);
			end
		endtask : drive;
	endclass : MemoryDriver
	
	//Monitor
	class MemoryMonitor#(
		int ADDRESS_WIDTH = 32,
		int DATA_WIDTH		= 32,
		int SIZE					= 1024
	) extends uvm_monitor;

		`uvm_component_utils(MemoryMonitor#(ADDRESS_WIDTH, DATA_WIDTH, SIZE))

		uvm_analysis_port#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)) analysisPort;
		MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) 										memoryTransaction;
		
		virtual MemoryInterface#(ADDRESS_WIDTH, DATA_WIDTH) memoryInterface;
		
		function new(string name = "MemoryMonitor", uvm_component parent);
			super.new(name, parent);
		endfunction : new 

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if (!uvm_config_db#(virtual MemoryInterface#(ADDRESS_WIDTH, DATA_WIDTH))::get(this, "", "MemoryInterface", memoryInterface)) begin
				`uvm_fatal("NO VIRTAUL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
	
			analysisPort 			= new("analysisPort", this);
			memoryTransaction	= new("MemoryTransaction");
		endfunction : build_phase

		virtual task run_phase(uvm_phase phase);
			repeat(4) @(posedge memoryInterface.clock);
			forever begin
				while (memoryInterface.functionComplete != 1) begin
					@(posedge memoryInterface.clock);
				end

				memoryTransaction.address = memoryInterface.address;
				if (memoryInterface.readEnabled == 1) begin
					memoryTransaction.isRead = 1;
					memoryTransaction.data 	 = memoryInterface.dataIn;
				end else begin
					memoryTransaction.isRead = 0;
					memoryTransaction.data	 = memoryInterface.dataOut;
				end

				analysisPort.write(memoryTransaction);

				while (memoryInterface.functionComplete != 0) begin
					@(posedge memoryInterface.clock);
				end
			end	
		endtask : run_phase

	endclass : MemoryMonitor

	//Agent
	class MemoryAgent#(
		int ADDRESS_WIDTH = 32,
		int DATA_WIDTH		= 32,
		int SIZE					= 1024
	) extends uvm_agent;
		
		`uvm_component_utils(MemoryAgent#(ADDRESS_WIDTH, DATA_WIDTH, SIZE))

		uvm_analysis_port#(MemoryTransaction#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)) analysisPort;

		MemorySequencer#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)	sequencer;
		MemoryDriver#(ADDRESS_WIDTH, DATA_WIDTH, SIZE) 		driver;
		MemoryMonitor#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)		monitor;
		
		function new(string name = "MemoryAgent", uvm_component parent);
			super.new(name, parent);
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			analysisPort = new("analysisPort", this);

			monitor		= MemoryMonitor#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::type_id::create("MemoryMonitor", this);
			sequencer	= MemorySequencer#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::type_id::create("MemorySequencer", this);
			driver		= MemoryDriver#(ADDRESS_WIDTH, DATA_WIDTH, SIZE)::type_id::create("MemoryDriver", this);
		endfunction : build_phase

		function void connect_phase(uvm_phase phase);
			driver.seq_item_port.connect(sequencer.seq_item_export);
			monitor.analysisPort.connect(analysisPort);
		endfunction : connect_phase

	endclass : MemoryAgent
endpackage : ramAgentPackage
