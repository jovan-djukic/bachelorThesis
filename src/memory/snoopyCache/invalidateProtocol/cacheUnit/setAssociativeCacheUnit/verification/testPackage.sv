package testPackage;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import basicTestPackage::*;

	typedef enum logic[1 : 0] {
		STATE_0,
		STATE_1,
		STATE_2,
		STATE_3	
	} State;

	localparam TAG_WIDTH                                            = 8;
	localparam INDEX_WIDTH                                          = 4;
	localparam OFFSET_WIDTH                                         = 4;
	localparam SET_ASSOCIATIVITY                                    = 2;
	localparam DATA_WIDTH                                           = 8;
	localparam type STATE_TYPE                                      = State;
	localparam CPU_STATE_SET_LENGTH                                 = 3;
	localparam STATE_TYPE CPU_STATE_SET[CPU_STATE_SET_LENGTH]       = {STATE_1, STATE_2, STATE_3};
	localparam SNOOPY_STATE_SET_LENGTH                              = 4;
	localparam STATE_TYPE SNOOPY_STATE_SET[SNOOPY_STATE_SET_LENGTH] = {STATE_0, STATE_1, STATE_2, STATE_3};
	localparam STATE_TYPE INVALID_STATE                             = STATE_0;
	localparam SEQUENCE_ITEM_COUNT                                  = 1000;
	localparam TEST_INTERFACE                                       = "TestInterface";

	//cache unit sequence item
	class CacheUnitSequenceItem extends BasicSequenceItem;		
		//cpu controller signals
		bit[INDEX_WIDTH - 1       : 0] cpuIndex;
		bit[TAG_WIDTH - 1         : 0] cpuTagIn;
		bit[DATA_WIDTH - 1        : 0] cpuDataIn;
		STATE_TYPE                  	 cpuStateIn;

		//snoopy controller signals
		bit[INDEX_WIDTH - 1       : 0] snoopyIndex;
		bit[TAG_WIDTH - 1         : 0] snoopyTagIn;
		STATE_TYPE                  	 snoopyStateIn;
		
		`uvm_object_utils_begin(CacheUnitSequenceItem)	
			//cpu fields
			`uvm_field_int(cpuIndex, UVM_ALL_ON)
			`uvm_field_int(cpuTagIn, UVM_ALL_ON)
			`uvm_field_int(cpuDataIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, cpuStateIn, UVM_ALL_ON)

			//snoopy fields
			`uvm_field_int(snoopyIndex, UVM_ALL_ON)
			`uvm_field_int(snoopyTagIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateIn, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "CacheUnitSequenceItem");
			super.new(.name(name));
		endfunction : new		

		virtual function void myRandomize();
			//cpu randomized data
			cpuIndex   = $urandom();
			cpuTagIn   = $urandom();
			cpuDataIn  = $urandom();
			cpuStateIn = CPU_STATE_SET[$urandom() % CPU_STATE_SET_LENGTH];

			//snoopy randomized data
			snoopyIndex   = $urandom(); 
			snoopyTagIn   = $urandom();
			snoopyStateIn = SNOOPY_STATE_SET[$urandom() % SNOOPY_STATE_SET_LENGTH];
		endfunction : myRandomize
	endclass : CacheUnitSequenceItem

	//cahce unit driver
	class CacheUnitDriver extends BasicDriver;
		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		`uvm_component_utils(CacheUnitDriver)

		protected virtual interface TestInterface#(
			.STATE_TYPE(STATE_TYPE),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.INVALID_STATE(INVALID_STATE)
		) testInterface;

		function new(string name = "CacheUnitDriver", uvm_component parent);
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
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"})
			end
		endfunction : build_phase

		virtual task resetDUT();
			testInterface.reset            = 1;
			testInterface.accessEnable     = 0;
			testInterface.invalidateEnable = 0;
			repeat (2) begin
				@(posedge testInterface.clock);
			end
			testInterface.reset = 0;
		endtask : resetDUT

		virtual task drive();
			CacheUnitSequenceItem sequenceItem;
			$cast(sequenceItem, req);
			//drive cpu controller signals
			testInterface.cpuCacheInterface.index   = sequenceItem.cpuIndex;
			testInterface.cpuCacheInterface.offset  = 0;
			testInterface.cpuCacheInterface.tagIn   = sequenceItem.cpuTagIn;
			testInterface.cpuCacheInterface.stateIn = sequenceItem.cpuStateIn;
			testInterface.cpuCacheInterface.dataIn  = sequenceItem.cpuDataIn;

			//wait for data to sync in
			@(posedge testInterface.clock);

			//if not hit write data
			if (testInterface.cpuCacheInterface.hit == 0) begin
				testInterface.cpuCacheInterface.writeTag   = 1;
				testInterface.cpuCacheInterface.writeState = 1;
				testInterface.cpuCacheInterface.writeData  = 1;

				for (int i = 0; i < NUMBER_OF_WORDS; i++) begin
					testInterface.cpuCacheInterface.offset    = i;
					repeat (2) begin
						@(posedge testInterface.clock);
					end
				end	

				testInterface.cpuCacheInterface.writeTag   = 0;
				testInterface.cpuCacheInterface.writeState = 0;
				testInterface.cpuCacheInterface.writeData  = 0;
			end

			testInterface.accessEnable = 1;
			@(posedge testInterface.clock);
			testInterface.accessEnable = 0;
			@(posedge testInterface.clock);

			//drive snoopy controller signals
			testInterface.snoopyCacheInterface.index   = sequenceItem.snoopyIndex;
			testInterface.snoopyCacheInterface.tagIn   = sequenceItem.snoopyTagIn;
			testInterface.snoopyCacheInterface.offset  = 0;
			testInterface.snoopyCacheInterface.stateIn = sequenceItem.snoopyStateIn;

			//wait for data to sync in
			@(posedge testInterface.clock);

			//change state if hit
			if (testInterface.snoopyCacheInterface.hit == 1) begin
				//invalidate block if new state is invalida state
				if (testInterface.snoopyCacheInterface.stateIn == INVALID_STATE) begin
					//first invalidate line 
					testInterface.invalidateEnable = 1;
					repeat(2) begin
						@(posedge testInterface.clock);
					end
					testInterface.invalidateEnable = 0;
				end

				testInterface.snoopyCacheInterface.writeState = 1;
				repeat (2) begin
					@(posedge testInterface.clock);
				end
				testInterface.snoopyCacheInterface.writeState = 0;
			end

			@(posedge testInterface.clock);
		endtask : drive
	endclass : CacheUnitDriver

	//cache unit collected item
	class CacheUnitCollectedItem extends BasicCollectedItem;		
		//cpu controller signals
		bit[INDEX_WIDTH - 1       : 0] cpuIndex;
		bit[TAG_WIDTH - 1         : 0] cpuTagIn, cpuTagOut;
		bit[DATA_WIDTH - 1        : 0] cpuDataIn, cpuDataOut;
		bit[SET_ASSOCIATIVITY - 1 : 0] cpuCacheNumber;
		STATE_TYPE                  	 cpuStateIn, cpuStateOut;
		bit                       		 cpuHit;

		//snoopy controller ports
		bit[INDEX_WIDTH - 1       : 0] snoopyIndex;
		bit[TAG_WIDTH - 1         : 0] snoopyTagIn;
		bit[DATA_WIDTH - 1        : 0] snoopyDataOut;
		bit[SET_ASSOCIATIVITY - 1 : 0] snoopyCacheNumber, snoopyInvalidatedCacheNumber;
		STATE_TYPE                  	 snoopyStateIn, snoopyStateOut;
		bit                       		 snoopyHit, isInvalidated;
		
		`uvm_object_utils_begin(CacheUnitCollectedItem)	
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
			`uvm_field_int(snoopyInvalidatedCacheNumber, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateIn, UVM_ALL_ON)
			`uvm_field_enum(STATE_TYPE, snoopyStateOut, UVM_ALL_ON)
			`uvm_field_int(snoopyHit, UVM_ALL_ON)
			`uvm_field_int(isInvalidated, UVM_ALL_ON)
		`uvm_object_utils_end

		function new(string name = "CacheUnitCollectedItem");
			super.new(.name(name));
		endfunction : new		
	endclass : CacheUnitCollectedItem

	//cache unit monitor
	class CacheUnitMonitor extends BasicMonitor;
		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		`uvm_component_utils(CacheUnitMonitor)
		protected virtual interface TestInterface#(
			.STATE_TYPE(STATE_TYPE),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.INVALID_STATE(INVALID_STATE)
		) testInterface;

		function new(string name = "CacheUnitMonitor", uvm_component parent);
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
			))::get(this, "", TEST_INTERFACE, testInterface)) begin
				`uvm_fatal("NO VIRTUAL INTERFACE", {"virtual interface must be set for: ", get_full_name(), ".vif"})
			end
		endfunction : build_phase

		virtual task resetDUT();
			repeat (2) begin
				@(posedge testInterface.clock);
			end
		endtask : resetDUT

		virtual task collect();
			CacheUnitCollectedItem collectedItem;
			$cast(collectedItem, super.basicCollectedItem);

			//wait for driver to drive cpu controller signals
			@(posedge testInterface.clock);
			
			//collect cpu controller signals
			collectedItem.cpuIndex       = testInterface.cpuCacheInterface.index;
			collectedItem.cpuTagIn       = testInterface.cpuCacheInterface.tagIn;
			collectedItem.cpuStateIn     = testInterface.cpuCacheInterface.stateIn;
			collectedItem.cpuDataIn      = testInterface.cpuCacheInterface.dataIn;
			collectedItem.cpuHit         = testInterface.cpuCacheInterface.hit;
			collectedItem.cpuCacheNumber = testInterface.cpuCacheInterface.cacheNumber;

			//if not hit write data
			if (collectedItem.cpuHit == 0) begin
				for (int i = 0; i < NUMBER_OF_WORDS; i++) begin
					repeat (2) begin
						@(posedge testInterface.clock);
					end
				end	
			end
			
			@(posedge testInterface.clock);

			//collect output signals
			collectedItem.cpuTagOut      = testInterface.cpuCacheInterface.tagOut;
			collectedItem.cpuDataOut     = testInterface.cpuCacheInterface.dataOut;
			collectedItem.cpuStateOut    = testInterface.cpuCacheInterface.stateOut;
			
			//synchronize with monitor
			@(posedge testInterface.clock);

			//wait for driver to drive snoopy controller signals
			@(posedge testInterface.clock);
			//collect snoopy controller signals
			collectedItem.snoopyIndex       = testInterface.snoopyCacheInterface.index;
			collectedItem.snoopyTagIn       = testInterface.snoopyCacheInterface.tagIn;
			collectedItem.snoopyStateIn     = testInterface.snoopyCacheInterface.stateIn;
			collectedItem.snoopyHit         = testInterface.snoopyCacheInterface.hit;
			collectedItem.snoopyDataOut     = testInterface.snoopyCacheInterface.dataOut;
			collectedItem.snoopyCacheNumber = testInterface.snoopyCacheInterface.cacheNumber;

			//change state if hit
			if (testInterface.snoopyCacheInterface.hit == 1) begin
				//invalidate block if new state is invalida state
				if (testInterface.snoopyCacheInterface.stateIn == INVALID_STATE) begin
					repeat(2) begin
						@(posedge testInterface.clock);
					end
				end

				repeat (2) begin
					@(posedge testInterface.clock);
				end

				collectedItem.snoopyStateOut = testInterface.snoopyCacheInterface.stateOut;
				if (testInterface.snoopyCacheInterface.stateIn == INVALID_STATE) begin
					collectedItem.snoopyInvalidatedCacheNumber =  testInterface.snoopyCacheInterface.cacheNumber;
					collectedItem.isInvalidated                = ~testInterface.snoopyCacheInterface.hit;
				end
			end

			@(posedge testInterface.clock);
		endtask : collect
	endclass : CacheUnitMonitor

	//cache unti scoreboard
	class CacheUnitScoreboard extends BasicScoreboard;
		localparam NUMBER_OF_WORDS = 1 << OFFSET_WIDTH;

		`uvm_component_utils(CacheUnitScoreboard)

		setAssociativeCacheUnitClassImplementationPackage::SetAssociativeCacheUnitClassImplementation#(
			.TAG_WIDTH(TAG_WIDTH), 
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.DATA_WIDTH(DATA_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)
		) classImplementation;

		function new(string name = "CacheUnitScoreboard", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(.phase(phase));

			classImplementation = new();
		endfunction : build_phase

		virtual function void checkBehaviour();
			int errorCounter = 0;

			CacheUnitCollectedItem collectedItem;
			$cast(collectedItem, super.collectedItem);

			begin
				//helper variables
				int cpuHit         = classImplementation.isHit(.index(collectedItem.cpuIndex), .tag(collectedItem.cpuTagIn));
				int cpuCacheNumber = classImplementation.getCPUCacheNumber(.index(collectedItem.cpuIndex), .tag(collectedItem.cpuTagIn));
				if (collectedItem.cpuHit != cpuHit) begin
					`uvm_info("CPU_HIT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", cpuHit, collectedItem.cpuHit), UVM_LOW);
				end

				if (collectedItem.cpuCacheNumber != cpuCacheNumber) begin
					`uvm_info("CPU_CACHE_NUMBER_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", cpuCacheNumber, collectedItem.cpuCacheNumber), UVM_LOW)
				end

				if (collectedItem.cpuHit == 0) begin
					classImplementation.writeTag(.index(collectedItem.cpuIndex), .tag(collectedItem.cpuTagIn));
					classImplementation.writeState(.index(collectedItem.cpuIndex), .tag(collectedItem.cpuTagIn), .state(collectedItem.cpuStateIn));
					classImplementation.writeDataToWholeLine(.index(collectedItem.cpuIndex), .tag(collectedItem.cpuTagIn), .data(collectedItem.cpuDataIn));
				end
				classImplementation.access(.index(collectedItem.cpuIndex), .tag(collectedItem.cpuTagIn));
			end

			begin
				//helper variables
				logic[SET_ASSOCIATIVITY - 1 : 0] cacheNumber  = classImplementation.getCPUCacheNumber(.index(collectedItem.cpuIndex), .tag(collectedItem.cpuTagIn));
				logic[TAG_WIDTH - 1         : 0] tagOut       = classImplementation.getTag(.cacheNumber(cacheNumber), .index(collectedItem.cpuIndex));
				logic[DATA_WIDTH - 1        : 0] dataOut      = classImplementation.getData(.cacheNumber(cacheNumber), .index(collectedItem.cpuIndex));
				STATE_TYPE											 stateOut     = classImplementation.getState(.cacheNumber(cacheNumber), .index(collectedItem.cpuIndex));
				//check if it is in the right cache Number
				if (collectedItem.cpuCacheNumber != cacheNumber) begin
					`uvm_info("CACHE_NUMBER_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", cacheNumber, collectedItem.cpuCacheNumber), UVM_LOW)
					errorCounter++;
				end
				//check if tagOuts match
				if (collectedItem.cpuTagOut != tagOut) begin
					`uvm_info("CPU_TAG_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", tagOut, collectedItem.cpuTagOut), UVM_LOW)
					errorCounter++;
				end
				//check if dataOuts match
				if (collectedItem.cpuDataOut != dataOut) begin
					`uvm_info("CPU_DATA_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", dataOut, collectedItem.cpuDataOut), UVM_LOW)
					errorCounter++;
				end
				//check if stateOuts match
				if (collectedItem.cpuStateOut != stateOut) begin
					`uvm_info("CPU_STATE_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", stateOut, collectedItem.cpuStateOut), UVM_LOW)
					errorCounter++;
				end
			end
	
			begin
				logic snoopyHit                                    = classImplementation.isHit(.index(collectedItem.snoopyIndex), .tag(collectedItem.snoopyTagIn));
				logic[SET_ASSOCIATIVITY - 1 : 0] snoopyCacheNumber = classImplementation.getSnoopyCacheNumber(
																																										.index(collectedItem.snoopyIndex), 
																																										.tag(collectedItem.snoopyTagIn)
																																									);
				logic[DATA_WIDTH - 1        : 0] snoopyDataOut     = classImplementation.getData(.cacheNumber(snoopyCacheNumber), .index(collectedItem.snoopyIndex));
				//check snoopy hit
				if (collectedItem.snoopyHit != snoopyHit) begin
					`uvm_info("SNOOPY_HIT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", ~collectedItem.snoopyHit, collectedItem.snoopyHit), UVM_LOW);
					errorCounter++;
				end
				
				if (collectedItem.snoopyCacheNumber != snoopyCacheNumber) begin
					`uvm_info("SNOOPY_CACHE_NUMBER_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", snoopyCacheNumber, collectedItem.snoopyCacheNumber), UVM_LOW);
					errorCounter++;
				end	

				if (collectedItem.snoopyDataOut != snoopyDataOut) begin
					`uvm_info("SNOOPY_DATA_OUT_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", snoopyDataOut, collectedItem.snoopyDataOut), UVM_LOW);
					errorCounter++;
				end	

				//if snoopy hit write and check state
				if (snoopyHit == 1) begin
					if (collectedItem.snoopyStateIn == INVALID_STATE) begin
						//invalidate
						classImplementation.invalidate(.index(collectedItem.snoopyIndex), .tag(collectedItem.snoopyTagIn));
					end

					classImplementation.writeState(.index(collectedItem.snoopyIndex), .tag(collectedItem.snoopyTagIn), .state(collectedItem.snoopyStateIn));	

					if (collectedItem.snoopyStateOut != classImplementation.getState(.cacheNumber(snoopyCacheNumber), .index(collectedItem.snoopyIndex))) begin
						int snoopyStateOut = classImplementation.getState(.cacheNumber(snoopyCacheNumber), .index(collectedItem.snoopyIndex));
						`uvm_info("SNOOPY_STATE_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", snoopyStateOut, collectedItem.snoopyStateOut), UVM_LOW);
						errorCounter++;
					end

					if (collectedItem.snoopyStateIn == INVALID_STATE) begin
						int snoopyInvalidatedCacheNumber = classImplementation.getSnoopyCacheNumber(.index(collectedItem.snoopyIndex), .tag(collectedItem.snoopyTagIn));
						bit isInvalidated                = ~classImplementation.isHit(.index(collectedItem.snoopyIndex), .tag(collectedItem.snoopyTagIn));
						if (collectedItem.isInvalidated != isInvalidated) begin
							`uvm_info("SNOOPY_INVALIDATE_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", 1, collectedItem.isInvalidated), UVM_LOW);
							errorCounter++;
						end	
						if (collectedItem.snoopyInvalidatedCacheNumber != snoopyInvalidatedCacheNumber) begin
							`uvm_info("SNOOPY_INVALIDATED_CACHE_NUMBER_ERROR", $sformatf("SCOREBOARD=%d, CACHE=%d", snoopyInvalidatedCacheNumber, collectedItem.snoopyInvalidatedCacheNumber), UVM_LOW);
							errorCounter++;
						end	
					end
				end
			end

			if (errorCounter == 0) begin
				`uvm_info("TEST_OK", "", UVM_LOW)
			end
		endfunction : checkBehaviour
	endclass : CacheUnitScoreboard

	class CacheUnitTest extends BasicTest#(
		.SEQUENCE_ITEM_COUNT(SEQUENCE_ITEM_COUNT)
	);
		`uvm_component_utils(CacheUnitTest)
		
		function new(string name = "CacheUnitTest", uvm_component parent);
			super.new(.name(name), .parent(parent));
		endfunction : new

		virtual function void registerReplacements();
			BasicSequenceItem::type_id::set_type_override(CacheUnitSequenceItem::get_type(), 1);	
			BasicDriver::type_id::set_type_override(CacheUnitDriver::get_type(), 1);	
			BasicCollectedItem::type_id::set_type_override(CacheUnitCollectedItem::get_type(), 1);	
			BasicMonitor::type_id::set_type_override(CacheUnitMonitor::get_type(), 1);	
			BasicScoreboard::type_id::set_type_override(CacheUnitScoreboard::get_type(), 1);	
		endfunction : registerReplacements
	endclass : CacheUnitTest
endpackage : testPackage
