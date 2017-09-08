VLOG        = vlog
SRC         = src
UVM_HOME    = ./$(SRC)/uvm-1.1d
INCLUDES    = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv
FLAGS       = +define+UVM_NO_DPI
UVM_COMMAND = $(VLOG) $(FLAGS) $(INCLUDES)
MODELSIM_VERIFICATION_COMMAND   = vsim -c bachelorThesis.TestBench -do "run -all"
LIBRARY     = bachelorThesis

#command for verificaton

#uvm test packages
UVM_BASE_TEST_PACKAGES_SOURCE_DIRECTORY = $(SRC)/uvmBaseTestPackages

#basic uvm test package
UVM_BASIC_TEST_PACKAGE_SOURCE_DIRECTORY = $(UVM_BASE_TEST_PACKAGES_SOURCE_DIRECTORY)/basicTestPackage
UVM_BASIC_TEST_PACKAGE_SOURCE           = $(UVM_BASIC_TEST_PACKAGE_SOURCE_DIRECTORY)/basicTestPackage.sv

uvm_basic_test_package_source : $(UVM_BASIC_TEST_PACKAGE_SOURCE)
	$(UVM_COMMAND) $? 

#basic circuits
BASIC_CIRCUITS_SOURCE_DIRECTORY      = $(SRC)/basicCircuits
BASIC_CIRCUITS_IMPLEMENTATION_SOURCE = $(BASIC_CIRCUITS_SOURCE_DIRECTORY)/*.sv

basic_circuits_implementation_source : $(BASIC_CIRCUITS_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

#arbiter
ARBITER_SOURCE_DIRECTORY      = $(SRC)/arbiter
ARBITER_IMPLEMENTATION_SOURCE = $(ARBITER_SOURCE_DIRECTORY)/*.sv

arbiter_implementation_source : $(ARBITER_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

#simple arbiter
SIMPLE_ARBITER_SOURCE_DIRECTORY      = $(ARBITER_SOURCE_DIRECTORY)/simpleArbiter
SIMPLE_ARBITER_IMPLEMENTATION_SOURCE = $(SIMPLE_ARBITER_SOURCE_DIRECTORY)/implementation/*.sv
SIMPLE_ARBITER_VERIFICATION_SOURCE   = $(SIMPLE_ARBITER_SOURCE_DIRECTORY)/verification/testInterface.sv \
																		 	 $(SIMPLE_ARBITER_SOURCE_DIRECTORY)/verification/testPackage.sv \
																		 	 $(SIMPLE_ARBITER_SOURCE_DIRECTORY)/verification/testBench.sv 

simple_arbiter_implementation_source : $(SIMPLE_ARBITER_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

simple_arbiter_implementation : arbiter_implementation_source simple_arbiter_implementation_source 

simple_arbiter_test_files : $(SIMPLE_ARBITER_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

simple_arbiter_verification : simple_arbiter_implementation uvm_basic_test_package_source simple_arbiter_test_files
	$(MODELSIM_VERIFICATION_COMMAND)

#memory
MEMORY_SOURCE_DIRECTORY      = $(SRC)/memory
MEMORY_IMPLEMENTATION_SOURCE = $(MEMORY_SOURCE_DIRECTORY)/*.sv

memory_implementation_source : $(MEMORY_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

#ram
RAM_SOURCE_DIRECTORY      = $(MEMORY_SOURCE_DIRECTORY)/ram
RAM_IMPLEMENTATION_SOURCE = $(RAM_SOURCE_DIRECTORY)/implementation/*.sv
RAM_VERIFICATION_SOURCE   = $(RAM_SOURCE_DIRECTORY)/verification/testInterface.sv \
											 			$(RAM_SOURCE_DIRECTORY)/verification/testPackage.sv \
											 			$(RAM_SOURCE_DIRECTORY)/verification/testBench.sv

ram_implementation_source : $(RAM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

ram_implementation : memory_implementation_source ram_implementation_source
	
ram_test_files : $(RAM_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $? 

ram_verification : ram_implementation uvm_basic_test_package_source ram_test_files
	$(MODELSIM_VERIFICATION_COMMAND)

#width adapter
WIDTH_ADAPTER_SOURCE_DIRECTORY      = $(MEMORY_SOURCE_DIRECTORY)/widthAdapter
WIDTH_ADAPTER_IMPLEMENTATION_SOURCE = $(WIDTH_ADAPTER_SOURCE_DIRECTORY)/*.sv

width_adapter_implementation_source : $(WIDTH_ADAPTER_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

width_adapter_implementation : memory_implementation_source width_adapter_implementation_source

#snoopy cache
SNOOPY_SOURCE_DIRECTORY = $(MEMORY_SOURCE_DIRECTORY)/snoopyCache

#snoopy cache invalidate protocol 
SNOOPY_INVALIDATE_SOURCE_DIRECTORY = $(SNOOPY_SOURCE_DIRECTORY)/invalidateProtocol

#invalidate protocol operating unit
SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY     = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/cacheUnit
SNOOPY_INVALIDATE_CACHE_UNIT_IMPLEMENTAION_SOURCE = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/*.sv

snoopy_invalidate_cache_unit_implementation_source : $(SNOOPY_INVALIDATE_CACHE_UNIT_IMPLEMENTAION_SOURCE)
	$(VLOG) $?

#Replacement algorithm implementation
INVALIDATE_REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/replacementAlgorithm
INVALIDATE_REPLACEMENT_ALGORITHM_IMPLEMENTATION_SOURCE = $(INVALIDATE_REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/*.sv

invalidate_replacement_algorithm_implementation_source : $(INVALIDATE_REPLACEMENT_ALGORITHM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

#lru
INVALIDATE_LRU_SOURCE_DIRECTORY            = $(INVALIDATE_REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/lru
INVALIDATE_LRU_IMPLEMENTATION_SOURCE       = $(INVALIDATE_LRU_SOURCE_DIRECTORY)/implementation/*.sv
INVALIDATE_LRU_CLASS_IMPLEMENTATION_SOURCE = $(INVALIDATE_LRU_SOURCE_DIRECTORY)/classImplementation/*.sv
INVALIDATE_LRU_VERIFICATION_SOURCE         = $(INVALIDATE_LRU_SOURCE_DIRECTORY)/verification/testInterface.sv \
																						 $(INVALIDATE_LRU_SOURCE_DIRECTORY)/verification/testPackage.sv \
																						 $(INVALIDATE_LRU_SOURCE_DIRECTORY)/verification/testBench.sv 

invalidate_lru_implementation_source	: $(INVALIDATE_LRU_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

invalidate_lru_implementation : invalidate_replacement_algorithm_implementation_source invalidate_lru_implementation_source

invalidate_lru_class_implementation : $(INVALIDATE_LRU_CLASS_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

invalidate_lru_verification_source	: $(INVALIDATE_LRU_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $? 

invalidate_lru_verification : invalidate_lru_implementation invalidate_lru_class_implementation uvm_basic_test_package_source invalidate_lru_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#snoopy direct mapping cache unit
SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/directMappingCacheUnit
SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_direct_mapping_cache_unit_implementation_source : $(SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_direct_mapping_cache_unit_implementation : snoopy_invalidate_cache_unit_implementation_source \
																														 snoopy_invalidate_direct_mapping_cache_unit_implementation_source

#snoopy set associative cache
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY            = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/setAssociativeCacheUnit
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_IMPLEMENTATION_SOURCE       = $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/implementation/*.sv
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_CLASS_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/classImplementation/*.sv
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_VERIFICATION_SOURCE         = $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/verification/testInterface.sv \
																															 				$(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/verification/testPackage.sv \
																															 				$(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/verification/testBench.sv

snoopy_invalidate_set_associative_cache_implementation_source : $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_set_associative_cache_implementation : invalidate_lru_implementation \
																												 snoopy_invalidate_cache_unit_implementation_source \
																												 snoopy_invalidate_direct_mapping_cache_unit_implementation_source \
																												 snoopy_invalidate_set_associative_cache_implementation_source

snoopy_invalidate_set_associative_cache_class_implementation_source : $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_CLASS_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_set_associative_cache_class_implementation : invalidate_lru_class_implementation \
																												 			 snoopy_invalidate_set_associative_cache_class_implementation_source

snoopy_invalidate_set_associative_cache_verification_source : $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

snoopy_invalidate_set_associative_cache_verification : snoopy_invalidate_set_associative_cache_implementation \
																											 snoopy_invalidate_set_associative_cache_class_implementation \
																											 uvm_basic_test_package_source \
																											 snoopy_invalidate_set_associative_cache_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#snoopy invalidate commands
SNOOPY_INVALIDATE_COMMANDS_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/commands
SNOOPY_INVALIDATE_COMMANDS_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_COMMANDS_SOURCE_DIRECTORY)/commands.sv \
																						 			 $(SNOOPY_INVALIDATE_COMMANDS_SOURCE_DIRECTORY)/cpuCommandInterface.sv \
																									 $(SNOOPY_INVALIDATE_COMMANDS_SOURCE_DIRECTORY)/snoopyCommandInterface.sv

snoopy_invalidate_commands_implementation_source : $(SNOOPY_INVALIDATE_COMMANDS_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

#snoppy invalidate protocol
SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/protocol
SNOOPY_INVALIDATE_PROTOCOL_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/*.sv

snoopy_invalidate_protocol_implementation_source : $(SNOOPY_INVALIDATE_PROTOCOL_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_protocol_implementation : snoopy_invalidate_commands_implementation_source \
																						snoopy_invalidate_protocol_implementation_source

#snoopy invalidate cpu controller implementation
SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/cpuController
SNOOPY_INVALIDATE_CPU_CONTROLLER_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_cpu_controller_implementation_source : $(SNOOPY_INVALIDATE_CPU_CONTROLLER_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_cpu_controller_implementation : memory_implementation_source \
																									snoopy_invalidate_cache_unit_implementation_source \
																									snoopy_invalidate_commands_implementation_source \
																									snoopy_invalidate_protocol_implementation_source \
																									arbiter_implementation_source \
																									snoopy_invalidate_cpu_controller_implementation_source

#write through invalidate protocol for testing
SNOOPY_WRITE_THROUGH_INVALIDATE_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/writeThroughInvalidate
SNOOPY_WRITE_THROUGH_INVALIDATE_IMPLEMENTATION_SOURCE = $(SNOOPY_WRITE_THROUGH_INVALIDATE_SOURCE_DIRECTORY)/implementation/states.sv \
																									      $(SNOOPY_WRITE_THROUGH_INVALIDATE_SOURCE_DIRECTORY)/implementation/writeThroughInvalidate.sv 

snoopy_write_through_invalidate_implementation_source : $(SNOOPY_WRITE_THROUGH_INVALIDATE_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_write_through_invalidate_implementation : snoopy_invalidate_protocol_implementation \
																								 snoopy_write_through_invalidate_implementation_source

#snoopy invalidate cpu controller verification
SNOOPY_INVALIDATE_CPU_CONTROLLER_VERIFICATION_SOURCE = $(SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY)/verification/testInterface.sv \
																											 $(SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY)/verification/testPackage.sv \
																											 $(SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY)/verification/testBench.sv
	
snoopy_invalidate_cpu_controller_verification_source : $(SNOOPY_INVALIDATE_CPU_CONTROLLER_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

snoopy_invalidate_cpu_controller_verification : snoopy_invalidate_set_associative_cache_implementation \
																								snoopy_write_through_invalidate_implementation \
																								snoopy_invalidate_cpu_controller_implementation \
																								uvm_basic_test_package_source \
																								snoopy_invalidate_cpu_controller_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#snoopy invalidate cpu controller implementation
SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/snoopyController
SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_snoopy_controller_implementation_source : $(SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_snoopy_controller_implementation : memory_implementation_source \
 												 														 snoopy_invalidate_cache_unit_implementation_source \
												 														 snoopy_invalidate_commands_implementation_source \
												 														 snoopy_invalidate_protocol_implementation_source \
												 														 arbiter_implementation_source \
												 														 snoopy_invalidate_snoopy_controller_implementation_source

#snoopy controller test
SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_VERIFICATION_SOURCE = $(SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_SOURCE_DIRECTORY)/verification/testInterface.sv \
																													$(SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_SOURCE_DIRECTORY)/verification/testPackage.sv \
																													$(SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_SOURCE_DIRECTORY)/verification/testBench.sv
	
snoopy_invalidate_snoopy_controller_verification_source : $(SNOOPY_INVALIDATE_SNOOPY_CONTROLLER_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $? 

snoopy_invalidate_snoopy_controller_verification : snoopy_invalidate_set_associative_cache_implementation \
																									 snoopy_write_through_invalidate_implementation \
																									 snoopy_invalidate_snoopy_controller_implementation \
																									 uvm_basic_test_package_source \
																									 snoopy_invalidate_snoopy_controller_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#concurrency lock
SNOOPY_INVALIDATE_CONCURRENCY_LOCK_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/concurrencyLock
SNOOPY_INVALIDATE_CONCURRENCY_LOCK_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_CONCURRENCY_LOCK_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_concurrency_lock_implementation_source : $(SNOOPY_INVALIDATE_CONCURRENCY_LOCK_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_concurrency_lock_implementation : memory_implementation_source \
																										snoopy_invalidate_commands_implementation_source \
																										arbiter_implementation_source \
																										snoopy_invalidate_concurrency_lock_implementation_source
	
SNOOPY_INVALIDATE_CONCURRENCY_LOCK_VERIFICATION_SOURCE = $(SNOOPY_INVALIDATE_CONCURRENCY_LOCK_SOURCE_DIRECTORY)/verification/cases.sv \
																												 $(SNOOPY_INVALIDATE_CONCURRENCY_LOCK_SOURCE_DIRECTORY)/verification/testInterface.sv \
																												 $(SNOOPY_INVALIDATE_CONCURRENCY_LOCK_SOURCE_DIRECTORY)/verification/testPackage.sv \
																												 $(SNOOPY_INVALIDATE_CONCURRENCY_LOCK_SOURCE_DIRECTORY)/verification/testBench.sv

snoopy_invalidate_concurrency_lock_verification_source : $(SNOOPY_INVALIDATE_CONCURRENCY_LOCK_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $? 

snoopy_invalidate_concurrency_lock_verification : memory_implementation_source \
																									snoopy_invalidate_commands_implementation_source \
																									arbiter_implementation_source \
																									snoopy_invalidate_concurrency_lock_implementation \
																									uvm_basic_test_package_source \
																								  snoopy_invalidate_concurrency_lock_verification_source																									
	$(MODELSIM_VERIFICATION_COMMAND)

#snoopy bus
SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/bus
SNOOPY_INVALIDATE_BUS_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_bus_implementation_source : $(SNOOPY_INVALIDATE_BUS_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

.PHONY : clean

clean : 
	vdel -lib $(LIBRARY) -all
	vlib $(LIBRARY)
	vmap work $(LIBRARY)
