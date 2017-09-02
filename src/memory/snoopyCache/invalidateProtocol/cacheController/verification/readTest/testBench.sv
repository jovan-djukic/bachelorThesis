module TestBench();
	
	import uvm_pkg::*;
	import testPackage::*;

	TestInterface#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.INDEX_WIDTH(INDEX_WIDTH),
		.OFFSET_WIDTH(OFFSET_WIDTH),
		.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
		.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
		.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
		.STATE_TYPE(STATE_TYPE),
		.INVALID_STATE(INVALID_STATE)
	) testInterface();

	always #5 testInterface.clock = ~testInterface.clock;

	CacheController cacheController(
		.cpuSlaveInterface(testInterface.cpuSlaveInterface),
		.cpuMasterInterface(testInterface.cpuMasterInterface),
		.snoopySlaveInterface(testInterface.snoopySlaveInterface),
		.cacheInterface(testInterface.cacheInterface),
		.protocolInterface(testInterface.protocolInterface),
		.busInterface(testInterface.busInterface),
		.cpuArbiterInterface(testInterface.cpuArbiterInterface),
		.snoopyArbiterInterface(testInterface.snoopyArbiterInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);

	SetAssociativeCacheUnit#(
		.STATE_TYPE(STATE_TYPE)
	) setAssociativeCacheUnit(
		.cacheInterface(testInterface.cacheInterface),
		.accessEnable(testInterface.accessEnable),
		.invalidateEnable(testInterface.invalidateEnable),
		.clock(testInterface.clock),
		.reset(testInterface.reset)
	);


	//these two are needed because protocl is combo logic
	assign testInterface.protocolInterface.writeBackRequired  = testInterface.protocolInterface.cpuStateOut == DIRTY ? 1 : 0;
	assign testInterface.protocolInterface.invalidateRequired = testInterface.protocolInterface.cpuStateOut == VALID ? 1 : 0;

	always_comb begin
		testInterface.protocolInterface.cpuStateIn = INVALID;
		case (testInterface.protocolInterface.cpuStateOut)
			INVALID: begin
				if (testInterface.protocolInterface.cpuRead == 1 || testInterface.protocolInterface.cpuWrite == 1) begin
					testInterface.protocolInterface.cpuStateIn = VALID;				
				end 		
			end

			VALID: begin
				if (testInterface.protocolInterface.cpuRead == 1) begin
					testInterface.protocolInterface.cpuStateIn = VALID;				
				end else if (testInterface.protocolInterface.cpuWrite == 1) begin
					testInterface.protocolInterface.cpuStateIn = DIRTY;				
				end
			end

			DIRTY: begin
				if (testInterface.protocolInterface.cpuRead == 1 || testInterface.protocolInterface.cpuWrite == 1) begin
					testInterface.protocolInterface.cpuStateIn = DIRTY;				
				end 		
			end
		endcase	
	end

	initial begin
			
		uvm_config_db#(virtual TestInterface#(
			.ADDRESS_WIDTH(ADDRESS_WIDTH),
			.DATA_WIDTH(DATA_WIDTH),
			.TAG_WIDTH(TAG_WIDTH),
			.INDEX_WIDTH(INDEX_WIDTH),
			.OFFSET_WIDTH(OFFSET_WIDTH),
			.SET_ASSOCIATIVITY(SET_ASSOCIATIVITY),
			.NUMBER_OF_CACHES(NUMBER_OF_CACHES),
			.CACHE_NUMBER_WIDTH(CACHE_NUMBER_WIDTH),
			.STATE_TYPE(STATE_TYPE),
			.INVALID_STATE(INVALID_STATE)
		))::set(uvm_root::get(), "*", TEST_INTERFACE, testInterface);

		run_test("CPUControllerTest");
	end
endmodule : TestBench
