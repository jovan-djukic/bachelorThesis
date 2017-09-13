package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	import cases::*;
	import commands::*;

	localparam ADDRESS_WIDTH            = 32;
	localparam DATA_WIDTH               = 32;
	localparam OFFSET_WIDTH             = 8;
	localparam SEQUENCE_ITEM_COUNT      = 1000;
	localparam TEST_INTERFACE           = "TestInterface";

	localparam CONCURRENCY_LOCK_CASE_SET_LENGTH = 13;
	localparam ConcurrencyLockCase CONCURRENCY_LOCK_CASE_SET[CONCURRENCY_LOCK_CASE_SET_LENGTH] = {
																																													READ_BUS_INVALIDATE_CPU_FIRST,
																																													READ_BUS_INVALIDATE_SNOOPY_FIRST,
																																													READ_BUS_READ_EXCLUSIVE_CPU_FIRST,
																																													READ_BUS_READ_EXCLUSIVE_SNOOPY_FIRST,
																																													WRITE_BUS_READ_CPU_FIRST,
																																													WRITE_BUS_READ_SNOOPY_FIRST,
																																													WRITE_BUS_INVALIDATE_CPU_FIRST,
																																													WRITE_BUS_INVALIDATE_SNOOPY_FIRST,
																																													WRITE_BUS_READ_EXCLUSIVE_CPU_FIRST,
																																													WRITE_BUS_READ_EXCLUSIVE_SNOOPY_FIRST,
																																													BUS_INVALIDATE_LOOP_BUS_INVALIDATE,
																																													BUS_INVALIDATE_LOOP_BUS_READ_EXCLUSIVE,
																																													WRITE_BACK_LOOP
																																												};

	class ConcurrencyLockSequenceItem extends BasicSequenceItem;
		bit[ADDRESS_WIDTH - 1 : 0] address;
		bit[DATA_WIDTH - 1    : 0] data;
		ConcurrencyLockCase				 concurrencyLockCase;

		`uvm_object_utils_begin(ConcurrencyLockSequenceItem)
			`uvm_field_int(address, UVM_ALL_ON)
			`uvm_field_enum(ConcurrencyLockCase, concurrencyLockCase, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "ConcurrencyLockSequenceItem");
			super.new(.name(name));
		endfunction : new
		
		virtual function void myRandomize();
			address             = $urandom();
			data                = $urandom();
			concurrencyLockCase = CONCURRENCY_LOCK_CASE_SET[$urandom() % CONCURRENCY_LOCK_CASE_SET_LENGTH];
		endfunction : myRandomize
	endclass : ConcurrencyLockSequenceItem

	class ConcurrencyLockDriver extends BasicDriver;
		`uvm_component_utils(ConcurrencyLockDriver)

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) testInterface;

		function new(string name = "ConcurrencyLockDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
			testInterface.cpuSlaveMemoryInterface.readEnabled        = 0;
			testInterface.cpuSlaveMemoryInterface.writeEnabled       = 0;
			testInterface.cpuMasterMemoryInterface.functionComplete  = 0;
			testInterface.cpuBusCommandInterface.commandOut          = NONE;
			testInterface.cpuArbiterArbiterInterface.request         = 0;
			testInterface.snoopyBusCommandInterface.commandIn        = NONE;
			testInterface.snoopySlaveReadMemoryInterface.readEnabled = 0;
			testInterface.cpuHit                                     = 0;
			testInterface.snoopyHit                                  = 0;

			//@(posedge testInterface.clock);
			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
		endtask : resetDUT

		virtual task drive();
			ConcurrencyLockSequenceItem sequenceItem;
			$cast(sequenceItem, req);

			testInterface.cpuSlaveMemoryInterface.address        = sequenceItem.address;
			testInterface.snoopySlaveReadMemoryInterface.address = sequenceItem.address;

			wait (testInterface.cpuMasterMemoryInterface.address        == testInterface.cpuSlaveMemoryInterface.address);
			wait (testInterface.snoopyMasterReadMemoryInterface.address == testInterface.snoopySlaveReadMemoryInterface.address);
			
			testInterface.concurrencyLockCase = sequenceItem.concurrencyLockCase;
			@(posedge testInterface.clock);

			case (testInterface.concurrencyLockCase)
				READ_BUS_INVALIDATE_CPU_FIRST: begin
					testInterface.cpuHit                              = 1;
					testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 1);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					testInterface.snoopyHit                                  = 1;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					testInterface.snoopyBusCommandInterface.isInvalidated = 0;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 0);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;
				end

				READ_BUS_INVALIDATE_SNOOPY_FIRST: begin
					testInterface.snoopyHit                                  = 1;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);

					@(posedge testInterface.clock);

					testInterface.cpuHit                              = 1;
					testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;
					
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end
				
				READ_BUS_READ_EXCLUSIVE_CPU_FIRST: begin
					testInterface.cpuHit                              = 1;
					testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 1);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					testInterface.snoopyHit                                  = 1;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					testInterface.snoopyBusCommandInterface.isInvalidated = 0;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 0);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;
				end

				READ_BUS_INVALIDATE_SNOOPY_FIRST: begin
					testInterface.snoopyHit                                  = 1;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					@(posedge testInterface.clock);

					testInterface.cpuHit                              = 1;
					testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;
					
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end

				WRITE_BUS_READ_CPU_FIRST: begin
					testInterface.cpuHit = 1;
					testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					testInterface.invalidateRequired = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);
					
					testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuMasterMemoryInterface.dataOut == testInterface.cpuSlaveMemoryInterface.dataOut);

					testInterface.cpuControllerCommandInterface.isInvalidated = 1;

					wait (testInterface.cpuBusCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);
					
					testInterface.cpuControllerCommandInterface.isInvalidated = 0;

					wait (testInterface.cpuBusCommandInterface.isInvalidated == 0);
	
					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					testInterface.snoopySlaveReadMemoryInterface.readEnabled = 1;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					testInterface.invalidateRequired = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ);

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 1);

					@(posedge testInterface.clock);

					testInterface.snoopyMasterReadMemoryInterface.functionComplete = 1;

					wait (testInterface.snoopySlaveReadMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					testInterface.snoopySlaveReadMemoryInterface.readEnabled = 0;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 0);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					testInterface.snoopyMasterReadMemoryInterface.functionComplete = 0;

					wait (testInterface.snoopySlaveReadMemoryInterface.functionComplete == 0);
				end

				WRITE_BUS_READ_SNOOPY_FIRST: begin
					testInterface.snoopyHit                                  = 1;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ);

					testInterface.snoopySlaveReadMemoryInterface.readEnabled = 1;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 1);
					
					@(posedge testInterface.clock);

					testInterface.snoopyMasterReadMemoryInterface.functionComplete = 1;

					wait (testInterface.snoopyMasterReadMemoryInterface.functionComplete == 1);

					testInterface.cpuHit = 1;
					
					testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataOut == testInterface.cpuMasterMemoryInterface.dataOut);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					testInterface.invalidateRequired = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.snoopySlaveReadMemoryInterface.readEnabled = 0;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.snoopyMasterReadMemoryInterface.functionComplete = 0;

					wait (testInterface.snoopySlaveReadMemoryInterface.functionComplete == 0);

					@(posedge testInterface.clock);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					testInterface.cpuControllerCommandInterface.isInvalidated = 1;
					
					wait (testInterface.cpuBusCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);
					
					testInterface.cpuControllerCommandInterface.isInvalidated = 0;
					
					wait (testInterface.cpuBusCommandInterface.isInvalidated == 0);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					testInterface.invalidateRequired = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end

				WRITE_BUS_INVALIDATE_CPU_FIRST: begin
					testInterface.cpuHit                               = 1;
					testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					testInterface.invalidateRequired                   = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					testInterface.invalidateRequired = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);
				
					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);
				end

				WRITE_BUS_INVALIDATE_SNOOPY_FIRST: begin
					testInterface.snoopyHit                                  = 1;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);

					@(posedge testInterface.clock);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuMasterMemoryInterface.dataOut == testInterface.cpuSlaveMemoryInterface.dataOut);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					testInterface.invalidateRequired = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					testInterface.invalidateRequired                   = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end

				WRITE_BUS_READ_EXCLUSIVE_CPU_FIRST: begin
					testInterface.cpuHit                               = 1;
					testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					testInterface.invalidateRequired                   = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					testInterface.invalidateRequired                   = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);
				
					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);
				end

				WRITE_BUS_READ_EXCLUSIVE_SNOOPY_FIRST: begin
					testInterface.snoopyHit                                  = 1;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					@(posedge testInterface.clock);

					testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuMasterMemoryInterface.dataOut == testInterface.cpuSlaveMemoryInterface.dataOut);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					testInterface.invalidateRequired                   = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					testInterface.invalidateRequired                   = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end
				
				BUS_INVALIDATE_LOOP_BUS_INVALIDATE: begin
					testInterface.cpuHit                                     = 1;
					testInterface.snoopyHit                                  = 1;
					testInterface.cpuBusCommandInterface.commandOut          = BUS_INVALIDATE;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;
					testInterface.cpuDeviceArbiterInterface.grant            = 1;

					wait (testInterface.snoopyBusCommandInterface.commandIn            == NONE);
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);
					
					testInterface.cpuBusCommandInterface.commandOut          = NONE;
					testInterface.snoopyControllerCommandInterface.commandIn = NONE;
					testInterface.cpuDeviceArbiterInterface.grant            = 0;
				end

				BUS_INVALIDATE_LOOP_BUS_READ_EXCLUSIVE: begin
					testInterface.cpuHit                                     = 1;
					testInterface.snoopyHit                                  = 1;
					testInterface.cpuBusCommandInterface.commandOut          = BUS_READ_EXCLUSIVE;
					testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;
					testInterface.cpuDeviceArbiterInterface.grant            = 1;

					wait (testInterface.snoopyBusCommandInterface.commandIn            == NONE);
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);
					
					testInterface.cpuBusCommandInterface.commandOut          = NONE;
					testInterface.snoopyControllerCommandInterface.commandIn = NONE;
					testInterface.cpuDeviceArbiterInterface.grant            = 0;
				end

				WRITE_BACK_LOOP: begin
					testInterface.snoopyArbiterArbiterInterface.request = 1;

					wait (testInterface.snoopyDeviceArbiterInterface.request == 1);

					testInterface.snoopyControllerCommandInterface.commandIn = BUS_WRITEBACK;
					
					wait (testInterface.snoopyDeviceArbiterInterface.request == 0);

					testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyDeviceArbiterInterface.request == 1);
					
					testInterface.snoopyArbiterArbiterInterface.request = 0;
				end
			endcase

			@(posedge testInterface.clock);
		endtask : drive
	endclass : ConcurrencyLockDriver

	class ConcurrencyLockCollectedItem extends BasicCollectedItem;
		ConcurrencyLockCase concurrencyLockCase;

		`uvm_object_utils_begin(ConcurrencyLockCollectedItem)
			`uvm_field_enum(ConcurrencyLockCase, concurrencyLockCase, UVM_ALL_ON)
		`uvm_object_utils_end
	endclass : ConcurrencyLockCollectedItem

	class ConcurrencyLockMonitor extends BasicMonitor;
		`uvm_component_utils(ConcurrencyLockMonitor)

		virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH)
		) testInterface;

		function new(string name = "ConcurrencyLockMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
				.ADDRESS_WIDTH(ADDRESS_WIDTH),
				.DATA_WIDTH(DATA_WIDTH)
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_error("NO VIRTUAL INTERFACE", "Virtual interface not set")
			end
		endfunction : build_phase

		virtual task resetDUT();
			testInterface.cpuSlaveMemoryInterface.readEnabled        = 0;
			testInterface.cpuSlaveMemoryInterface.writeEnabled       = 0;
			testInterface.cpuBusCommandInterface.commandOut          = NONE;
			testInterface.cpuArbiterArbiterInterface.request         = 0;
			testInterface.snoopyBusCommandInterface.commandIn        = NONE;
			testInterface.snoopySlaveReadMemoryInterface.readEnabled = 0;
			testInterface.cpuHit                                     = 0;
			testInterface.snoopyHit                                  = 0;

			//@(posedge testInterface.clock);
			testInterface.reset = 1;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
		endtask : resetDUT

		virtual task collect();
			ConcurrencyLockCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);

			//testInterface.cpuSlaveMemoryInterface.address        = sequenceItem.address;
			//testInterface.snoopySlaveReadMemoryInterface.address = sequenceItem.address;

			wait (testInterface.cpuMasterMemoryInterface.address        == testInterface.cpuSlaveMemoryInterface.address);
			wait (testInterface.snoopyMasterReadMemoryInterface.address == testInterface.snoopySlaveReadMemoryInterface.address);
			
			//testInterface.concurrencyLockCase = sequenceItem.concurrencyLockCase;
			@(posedge testInterface.clock);

			collectedItem.concurrencyLockCase = testInterface.concurrencyLockCase;

			case (testInterface.concurrencyLockCase)
				READ_BUS_INVALIDATE_CPU_FIRST: begin
					//testInterface.cpuHit                              = 1;
					//testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					//testInterface.snoopyHit                                  = 1;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 0;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);
				end

				READ_BUS_READ_EXCLUSIVE_CPU_FIRST: begin
					//testInterface.cpuHit                              = 1;
					//testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					//testInterface.snoopyHit                                  = 1;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 0;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;
				end

				READ_BUS_INVALIDATE_SNOOPY_FIRST: begin
					//testInterface.snoopyHit                                  = 1;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					@(posedge testInterface.clock);

					//testInterface.cpuHit                              = 1;
					//testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;
					
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end

				READ_BUS_INVALIDATE_SNOOPY_FIRST: begin
					//testInterface.snoopyHit                                  = 1;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);

					@(posedge testInterface.clock);

					//testInterface.cpuHit                              = 1;
					//testInterface.cpuSlaveMemoryInterface.readEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;
					
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.readEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

				end

				WRITE_BUS_READ_CPU_FIRST: begin
					//testInterface.cpuHit = 1;
					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					//testInterface.invalidateRequired = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);
					
					//testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuMasterMemoryInterface.dataOut == testInterface.cpuSlaveMemoryInterface.dataOut);
					
					//testInterface.cpuControllerCommandInterface.isInvalidated = 1;

					wait (testInterface.cpuBusCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);
					
					//testInterface.cpuControllerCommandInterface.isInvalidated = 0;

					wait (testInterface.cpuBusCommandInterface.isInvalidated == 0);
	
					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					//testInterface.snoopySlaveReadMemoryInterface.readEnabled = 1;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					//testInterface.invalidateRequired = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ);

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 1);

					//testInterface.cpuControllerCommandInterface.isInvalidated = 1;
					
					wait (testInterface.cpuBusCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);
					
					//testInterface.cpuControllerCommandInterface.isInvalidated = 0;
					
					wait (testInterface.cpuBusCommandInterface.isInvalidated == 0);

					//testInterface.snoopyMasterReadMemoryInterface.functionComplete = 1;

					wait (testInterface.snoopySlaveReadMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					//testInterface.snoopySlaveReadMemoryInterface.readEnabled = 0;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 0);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					//testInterface.snoopyMasterReadMemoryInterface.functionComplete = 0;

					wait (testInterface.snoopySlaveReadMemoryInterface.functionComplete == 0);
				end

				WRITE_BUS_READ_SNOOPY_FIRST: begin
					//testInterface.snoopyHit                                  = 1;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ);

					//testInterface.snoopySlaveReadMemoryInterface.readEnabled = 1;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 1);
					
					@(posedge testInterface.clock);

					//testInterface.snoopyMasterReadMemoryInterface.functionComplete = 1;

					wait (testInterface.snoopyMasterReadMemoryInterface.functionComplete == 1);

					//testInterface.cpuHit = 1;
					
					//testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataOut == testInterface.cpuMasterMemoryInterface.dataOut);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					//testInterface.invalidateRequired = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.snoopySlaveReadMemoryInterface.readEnabled = 0;

					wait (testInterface.snoopyMasterReadMemoryInterface.readEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.snoopyMasterReadMemoryInterface.functionComplete = 0;

					wait (testInterface.snoopySlaveReadMemoryInterface.functionComplete == 0);

					@(posedge testInterface.clock);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					//testInterface.invalidateRequired = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end

				WRITE_BUS_INVALIDATE_CPU_FIRST: begin
					//testInterface.cpuHit                               = 1;
					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);
				
					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);
				end

				WRITE_BUS_INVALIDATE_SNOOPY_FIRST: begin
					//testInterface.snoopyHit                                  = 1;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_INVALIDATE);
					
					@(posedge testInterface.clock);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					//testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuMasterMemoryInterface.dataOut == testInterface.cpuSlaveMemoryInterface.dataOut);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					//testInterface.invalidateRequired                   = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					//testInterface.invalidateRequired                   = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end

				WRITE_BUS_READ_EXCLUSIVE_CPU_FIRST: begin
					//testInterface.cpuHit                               = 1;
					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					//testInterface.invalidateRequired                   = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.dataIn = sequenceItem.data;

					wait (testInterface.cpuSlaveMemoryInterface.dataIn == testInterface.cpuMasterMemoryInterface.dataIn);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					//testInterface.invalidateRequired                   = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);
				
					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					@(posedge testInterface.clock);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);
				end

				WRITE_BUS_READ_EXCLUSIVE_SNOOPY_FIRST: begin
					//testInterface.snoopyHit                                  = 1;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == BUS_READ_EXCLUSIVE);

					@(posedge testInterface.clock);

					//testInterface.snoopyBusCommandInterface.isInvalidated = 1;

					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);

					//testInterface.cpuSlaveMemoryInterface.dataOut = sequenceItem.data;

					wait (testInterface.cpuMasterMemoryInterface.dataOut == testInterface.cpuSlaveMemoryInterface.dataOut);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 1;
					//testInterface.invalidateRequired                   = 1;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyBusCommandInterface.commandIn == NONE);

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 1);

					@(testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 1;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 1);

					@(posedge testInterface.clock);

					//testInterface.cpuSlaveMemoryInterface.writeEnabled = 0;
					//testInterface.invalidateRequired                   = 0;

					wait (testInterface.cpuMasterMemoryInterface.writeEnabled == 0);

					@(posedge testInterface.clock);

					//testInterface.cpuMasterMemoryInterface.functionComplete = 0;

					wait (testInterface.cpuSlaveMemoryInterface.functionComplete == 0);
				end

				BUS_INVALIDATE_LOOP_BUS_INVALIDATE: begin
					//testInterface.cpuHit                                     = 1;
					//testInterface.snoopyHit                                  = 1;
					//testInterface.cpuBusCommandInterface.commandOut          = BUS_INVALIDATE;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_INVALIDATE;
					//testInterface.cpuDeviceArbiterInterface.grant            = 1;

					wait (testInterface.snoopyBusCommandInterface.commandIn            == NONE);
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);
					
					//testInterface.cpuBusCommandInterface.commandOut          = NONE;
					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;
					//testInterface.cpuDeviceArbiterInterface.grant            = 0;
				end

				BUS_INVALIDATE_LOOP_BUS_READ_EXCLUSIVE: begin
					//testInterface.cpuHit                                     = 1;
					//testInterface.snoopyHit                                  = 1;
					//testInterface.cpuBusCommandInterface.commandOut          = BUS_READ_EXCLUSIVE;
					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_READ_EXCLUSIVE;
					//testInterface.cpuDeviceArbiterInterface.grant            = 1;

					wait (testInterface.snoopyBusCommandInterface.commandIn            == NONE);
					wait (testInterface.snoopyControllerCommandInterface.isInvalidated == 1);
					
					//testInterface.cpuBusCommandInterface.commandOut          = NONE;
					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;
					//testInterface.cpuDeviceArbiterInterface.grant            = 0;
				end

				WRITE_BACK_LOOP: begin
					//testInterface.snoopyArbiterArbiterInterface.request = 1;

					wait (testInterface.snoopyDeviceArbiterInterface.request == 1);

					//testInterface.snoopyControllerCommandInterface.commandIn = BUS_WRITEBACK;
					
					wait (testInterface.snoopyDeviceArbiterInterface.request == 0);

					//testInterface.snoopyControllerCommandInterface.commandIn = NONE;

					wait (testInterface.snoopyDeviceArbiterInterface.request == 1);
					
					//testInterface.snoopyArbiterArbiterInterface.request = 0;
				end
			endcase

			@(posedge testInterface.clock);
		endtask : collect
	endclass : ConcurrencyLockMonitor

	class ConcurrencyLockScoreboard extends BasicScoreboard;
		`uvm_component_utils(ConcurrencyLockScoreboard)

		function new(string name = "ConcurrencyLockScoreaboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void checkBehaviour();
			ConcurrencyLockCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);

			`uvm_info(collectedItem.concurrencyLockCase.name(), "TEST OK", UVM_LOW)
		endfunction : checkBehaviour 
	endclass : ConcurrencyLockScoreboard

	class ConcurrencyLockTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		`uvm_component_utils(ConcurrencyLockTest)

		function new(string name = "ConcurrencyLockTest", uvm_component parent = null);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(ConcurrencyLockSequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(ConcurrencyLockDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(ConcurrencyLockCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(ConcurrencyLockMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(ConcurrencyLockScoreboard::get_type(), 1);
		endfunction : registerReplacements
	endclass : ConcurrencyLockTest
endpackage : testPackage 
