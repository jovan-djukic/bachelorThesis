package testPackage;

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;
	
	localparam INDEX_WIDTH         = 6;
	localparam SET_ASSOCIATIVITY   = 2;
	localparam SEQUENCE_ITEM_COUNT = 1000;
	localparam TEST_INTERFACE      = "TestInterface";

	typedef enum int {
		ACCESS,
		INVALIDATE,
		ACCESS_AND_INVALIDATE	
	} ACCESS_TYPE;

	class SetAssociativeLRUSequenceItem extends BasicSequenceItem;
		//index tells us which set it is, or rather whic lru to use
		bit[INDEX_WIDTH - 1 : 0] 			 cpuIndexIn, snoopyIndexIn;
		//there are lines per lru as much as there are smaller caches
		bit[SET_ASSOCIATIVITY - 1 : 0] lastAccessedCacheLine, invalidatedCacheLine, replacementCacheLine;
		ACCESS_TYPE                    accessType;
		
		`uvm_object_utils_begin(SetAssociativeLRUSequenceItem)
			`uvm_field_int(cpuIndexIn, UVM_ALL_ON)
			`uvm_field_int(snoopyIndexIn, UVM_ALL_ON)
			`uvm_field_int(lastAccessedCacheLine, UVM_ALL_ON)
			`uvm_field_int(invalidatedCacheLine, UVM_ALL_ON)
			`uvm_field_int(replacementCacheLine, UVM_ALL_ON)
			`uvm_field_enum(ACCESS_TYPE, accessType, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SetAssociativeLRUSequenceItem");
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
	endclass : SetAssociativeLRUSequenceItem

	class SetAssociativeLRUDriver extends BasicDriver;
		`uvm_component_utils(SetAssociativeLRUDriver)

		protected virtual TestInterface#(
			.INDEX_WIDTH(INDEX_WIDTH), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testInterface;

		function new(string name = "SetAssociativeLRUDriver", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
																		.INDEX_WIDTH(INDEX_WIDTH), 
																		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
																	))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase

		virtual task resetDUT();
			testInterface.reset = 1;
			repeat(2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
		endtask : resetDUT

		virtual task drive();
				SetAssociativeLRUSequenceItem sequenceItem;
				$cast(sequenceItem, req);

				case (sequenceItem.accessType)
					ACCESS:                begin
						testInterface.cpuIndexIn                                          = sequenceItem.cpuIndexIn;
						testInterface.replacementAlgorithmInterface.lastAccessedCacheLine = sequenceItem.lastAccessedCacheLine;
						testInterface.replacementAlgorithmInterface.accessEnable          = 1;
					end
					INVALIDATE:            begin
						testInterface.snoopyIndexIn                                       = sequenceItem.snoopyIndexIn;
						testInterface.replacementAlgorithmInterface.invalidatedCacheLine  = sequenceItem.invalidatedCacheLine;
						testInterface.replacementAlgorithmInterface.invalidateEnable      = 1;
					end
					ACCESS_AND_INVALIDATE: begin
						testInterface.cpuIndexIn                                          = sequenceItem.cpuIndexIn;
						testInterface.snoopyIndexIn                                       = sequenceItem.snoopyIndexIn;
						testInterface.replacementAlgorithmInterface.lastAccessedCacheLine = sequenceItem.lastAccessedCacheLine;
						testInterface.replacementAlgorithmInterface.invalidatedCacheLine  = sequenceItem.invalidatedCacheLine;
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
	
	class SetAssociativeLRUCollectedItem extends BasicCollectedItem;
		//index tells us which set it is, or rather whic lru to use
		bit[INDEX_WIDTH - 1 : 0] 			 cpuIndexIn, snoopyIndexIn;
		//there are lines per lru as much as there are smaller caches
		bit[SET_ASSOCIATIVITY - 1 : 0] lastAccessedCacheLine, invalidatedCacheLine, replacementCacheLine;
		ACCESS_TYPE                    accessType;
		
		`uvm_object_utils_begin(SetAssociativeLRUCollectedItem)
			`uvm_field_int(cpuIndexIn, UVM_ALL_ON)
			`uvm_field_int(snoopyIndexIn, UVM_ALL_ON)
			`uvm_field_int(lastAccessedCacheLine, UVM_ALL_ON)
			`uvm_field_int(invalidatedCacheLine, UVM_ALL_ON)
			`uvm_field_int(replacementCacheLine, UVM_ALL_ON)
			`uvm_field_enum(ACCESS_TYPE, accessType, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "SetAssociativeLRUCollectedItem");
			super.new(.name(name));
		endfunction : new
	endclass : SetAssociativeLRUCollectedItem

	class SetAssociativeLRUMonitor extends BasicMonitor;
		`uvm_component_utils(SetAssociativeLRUMonitor)

		protected virtual TestInterface#(
			.INDEX_WIDTH(INDEX_WIDTH), 
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) testInterface;

		function new(string name = "SetAssociativeLRUMonitor", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			if (!uvm_config_db#(virtual TestInterface#(
					.INDEX_WIDTH(INDEX_WIDTH), 
					.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
					))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"});
			end
		endfunction : build_phase

		virtual task resetDUT();
			//restart module
			repeat(2) begin
				@(posedge testInterface.clock);
			end
		endtask : resetDUT

		virtual task collect();
			SetAssociativeLRUCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);

			//wait for write to sync in
			repeat (2) begin
				@(posedge testInterface.clock);
			end

			//colect data
			//case (req.accessType)
			if (testInterface.replacementAlgorithmInterface.accessEnable == 1 && testInterface.replacementAlgorithmInterface.invalidateEnable == 1) begin
				//ACCESS_AND_INVALIDATE	
				collectedItem.accessType            = ACCESS_AND_INVALIDATE;
				collectedItem.cpuIndexIn            = testInterface.cpuIndexIn;
				collectedItem.snoopyIndexIn         = testInterface.snoopyIndexIn;
				collectedItem.invalidatedCacheLine  = testInterface.replacementAlgorithmInterface.invalidatedCacheLine;
				collectedItem.lastAccessedCacheLine = testInterface.replacementAlgorithmInterface.lastAccessedCacheLine;
				collectedItem.replacementCacheLine  = testInterface.replacementAlgorithmInterface.replacementCacheLine;
			end else if (testInterface.replacementAlgorithmInterface.accessEnable == 1) begin
				//ACCESS
				collectedItem.accessType            = ACCESS;
				collectedItem.cpuIndexIn            = testInterface.cpuIndexIn;
				collectedItem.lastAccessedCacheLine = testInterface.replacementAlgorithmInterface.lastAccessedCacheLine;
				collectedItem.replacementCacheLine  = testInterface.replacementAlgorithmInterface.replacementCacheLine;
			end else begin
				//INVALIDATE
				collectedItem.accessType           = INVALIDATE;
				collectedItem.snoopyIndexIn        = testInterface.snoopyIndexIn;
				collectedItem.invalidatedCacheLine = testInterface.replacementAlgorithmInterface.invalidatedCacheLine;
				collectedItem.replacementCacheLine = testInterface.replacementAlgorithmInterface.replacementCacheLine;
			end

			//write data
			@(posedge testInterface.clock);
			//wait for turning off of access and invalidate
			@(posedge testInterface.clock);
		endtask : collect
	endclass : SetAssociativeLRUMonitor

	class SetAssociativeLRUScoreboard extends BasicScoreboard;
		`uvm_component_utils(SetAssociativeLRUScoreboard)

		//data needed for checking lru
		setAssociativeLRUClassImplementationPackage::SetAssociativeLRUClassImplementation#(
			.INDEX_WIDTH(INDEX_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY)
		) lruImplementation;

		function new(string name = "SetAssociativeLRUScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			lruImplementation = new();
		endfunction : build_phase

		virtual function void checkBehaviour();
			SetAssociativeLRUCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);
			begin
				//helper variables
				int cpuIndexIn            = collectedItem.cpuIndexIn;
				int snoopyIndexIn         = collectedItem.snoopyIndexIn;
				int lastAccessedCacheLine = collectedItem.lastAccessedCacheLine;
				int invalidatedCacheLine  = collectedItem.invalidatedCacheLine;
				int replacementCacheLine  = collectedItem.replacementCacheLine;
				ACCESS_TYPE accessType    = collectedItem.accessType;
				
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
					`uvm_error("ERROR", $sformatf("\nINDEX=%d, EXPECTED_LINE=%d, LRU_LINE=%d, TYPE=%s", cpuIndexIn, lruImplementation.getReplacementCacheLine(cpuIndexIn), replacementCacheLine, accessType.name()))
				end else begin
					`uvm_info("OK", $sformatf("\nINDEX=%d, EXPECTED_LINE=%d, LRU_LINE=%d, TYPE=%s", cpuIndexIn, lruImplementation.getReplacementCacheLine(cpuIndexIn), replacementCacheLine, accessType.name()), UVM_LOW)
				end
			end
		endfunction : checkBehaviour
	endclass : SetAssociativeLRUScoreboard

	class SetAssociativeLRUTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		
		`uvm_component_utils(SetAssociativeLRUTest)

		function new(string name = "SetAssociativeLRUTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(SetAssociativeLRUSequenceItem::get_type(), 1);
			BasicDriver::type_id::set_type_override(SetAssociativeLRUDriver::get_type(), 1);
			BasicCollectedItem::type_id::set_type_override(SetAssociativeLRUCollectedItem::get_type(), 1);
			BasicMonitor::type_id::set_type_override(SetAssociativeLRUMonitor::get_type(), 1);
			BasicScoreboard::type_id::set_type_override(SetAssociativeLRUScoreboard::get_type(), 1);
		endfunction : registerReplacements
	endclass : SetAssociativeLRUTest
endpackage : testPackage
