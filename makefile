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

#msi protocol for testing
SNOOPY_MSI_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/msi
SNOOPY_MSI_IMPLEMENTATION_SOURCE = $(SNOOPY_MSI_SOURCE_DIRECTORY)/implementation/msiStates.sv \
																	 $(SNOOPY_MSI_SOURCE_DIRECTORY)/implementation/msi.sv 

snoopy_msi_implementation_source : $(SNOOPY_MSI_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_msi_implementation : snoopy_invalidate_protocol_implementation \
														snoopy_msi_implementation_source

#mesi protocl
SNOOPY_MESI_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/mesi
SNOOPY_MESI_IMPLEMENTATION_SOURCE = $(SNOOPY_MESI_SOURCE_DIRECTORY)/implementation/mesiStates.sv \
																		$(SNOOPY_MESI_SOURCE_DIRECTORY)/implementation/mesiInterface.sv \
																		$(SNOOPY_MESI_SOURCE_DIRECTORY)/implementation/mesi.sv 

snoopy_mesi_implementation_source : $(SNOOPY_MESI_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_mesi_implementation : snoopy_invalidate_protocol_implementation \
														 snoopy_mesi_implementation_source

#mesif protocl
SNOOPY_MESIF_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/mesif
SNOOPY_MESIF_IMPLEMENTATION_SOURCE = $(SNOOPY_MESIF_SOURCE_DIRECTORY)/implementation/mesifStates.sv \
																		 $(SNOOPY_MESIF_SOURCE_DIRECTORY)/implementation/mesifInterface.sv \
																		 $(SNOOPY_MESIF_SOURCE_DIRECTORY)/implementation/mesif.sv 

snoopy_mesif_implementation_source : $(SNOOPY_MESIF_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_mesif_implementation : snoopy_invalidate_protocol_implementation \
														  snoopy_mesif_implementation_source

#moesi protocl
SNOOPY_MOESI_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/moesi
SNOOPY_MOESI_IMPLEMENTATION_SOURCE = $(SNOOPY_MOESI_SOURCE_DIRECTORY)/implementation/moesiStates.sv \
																		 $(SNOOPY_MOESI_SOURCE_DIRECTORY)/implementation/moesiInterface.sv \
																		 $(SNOOPY_MOESI_SOURCE_DIRECTORY)/implementation/moesi.sv 

snoopy_moesi_implementation_source : $(SNOOPY_MOESI_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_moesi_implementation : snoopy_invalidate_protocol_implementation \
														  snoopy_moesi_implementation_source

#moesif protocol
SNOOPY_MOESIF_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/moesif
SNOOPY_MOESIF_IMPLEMENTATION_SOURCE = $(SNOOPY_MOESIF_SOURCE_DIRECTORY)/implementation/moesifStates.sv \
																			$(SNOOPY_MOESIF_SOURCE_DIRECTORY)/implementation/moesifInterface.sv \
																			$(SNOOPY_MOESIF_SOURCE_DIRECTORY)/implementation/moesif.sv 

snoopy_moesif_implementation_source : $(SNOOPY_MOESIF_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_moesif_implementation : snoopy_invalidate_protocol_implementation \
															 snoopy_moesif_implementation_source

SNOOPY_MOESIF_CLASS_IMPLEMENTATION_SOURCE = $(SNOOPY_MOESIF_SOURCE_DIRECTORY)/classImplementation/*.sv

snoopy_moesif_class_implementation_source : $(SNOOPY_MOESIF_CLASS_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

SNOOPY_MOESIF_VERIFICATION_SOURCE = $(SNOOPY_MOESIF_SOURCE_DIRECTORY)/verification/testInterface.sv \
																		$(SNOOPY_MOESIF_SOURCE_DIRECTORY)/verification/testPackage.sv \
																		$(SNOOPY_MOESIF_SOURCE_DIRECTORY)/verification/testBench.sv

snoopy_moesif_verification_source : $(SNOOPY_MOESIF_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

snoopy_moesif_verification : snoopy_moesif_implementation \
														 snoopy_moesif_class_implementation_source \
														 uvm_basic_test_package_source \
														 snoopy_moesif_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

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

#snoopy invalidate cpu controller verification
SNOOPY_INVALIDATE_CPU_CONTROLLER_VERIFICATION_SOURCE = $(SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY)/verification/testInterface.sv \
																											 $(SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY)/verification/testPackage.sv \
																											 $(SNOOPY_INVALIDATE_CPU_CONTROLLER_SOURCE_DIRECTORY)/verification/testBench.sv
	
snoopy_invalidate_cpu_controller_verification_source : $(SNOOPY_INVALIDATE_CPU_CONTROLLER_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

snoopy_invalidate_cpu_controller_verification : snoopy_invalidate_set_associative_cache_implementation \
																								snoopy_msi_implementation \
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
																									 snoopy_msi_implementation \
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
																										simple_arbiter_implementation \
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

snoopy_invalidate_bus_implementation : memory_implementation_source \
																			 snoopy_invalidate_commands_implementation_source \
																			 snoopy_invalidate_bus_implementation_source

SNOOPY_INVALIDATE_BUS_VERIFICATION_SOURCE = $(SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY)/verification/types.sv \
																						$(SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY)/verification/testInterface.sv \
																						$(SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY)/verification/testPackage.sv \
																						$(SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY)/verification/testBench.sv

snoopy_invalidate_bus_verification_source : $(SNOOPY_INVALIDATE_BUS_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

snoopy_invalidate_bus_verification : memory_implementation_source \
																		 snoopy_invalidate_commands_implementation_source \
																		 snoopy_invalidate_bus_implementation \
																		 uvm_basic_test_package_source \
																		 snoopy_invalidate_bus_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)


SNOOPY_INVALIDATE_CACHE_SOURCE_DIRECTORY      = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/cache
SNOOPY_INVALIDATE_CACHE_IMPLEMENTATION_SOURCE = $(SNOOPY_INVALIDATE_CACHE_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_cache_implementation_source : $(SNOOPY_INVALIDATE_CACHE_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

snoopy_invalidate_cache_implementation : memory_implementation_source \
																				 snoopy_invalidate_protocol_implementation \
																				 snoopy_invalidate_commands_implementation_source \
																				 arbiter_implementation_source \
																				 snoopy_invalidate_set_associative_cache_implementation \
																				 snoopy_invalidate_concurrency_lock_implementation \
																				 snoopy_invalidate_cpu_controller_implementation \
																				 snoopy_invalidate_snoopy_controller_implementation \
																				 snoopy_invalidate_cache_implementation_source
.PHONY : clean

clean : 
	vdel -lib $(LIBRARY) -all
	vlib $(LIBRARY)
	vmap work $(LIBRARY)

#memory systems
MEMORY_SYSTEMS_SOURCE_DIRECTORY = $(SRC)/memorySystems

#moesif cache system
MOESIF_CACHE_SYSTEM_SOURCE_DIRECTORY      = $(MEMORY_SYSTEMS_SOURCE_DIRECTORY)/moesifCacheSystem
MOESIF_CACHE_SYSTEM_IMPLEMENTATION_SOURCE = $(MOESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/implementation/moesifCacheSystem.sv 
MOESIF_CACHE_SYSTEM_VERIFICATION_SOURCE   = $(MOESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/dutInterface.sv \
																						$(MOESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testInterface.sv \
																						$(MOESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testPackage.sv \
																						$(MOESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testBench.sv

moesif_cache_system_implementation_source : $(MOESIF_CACHE_SYSTEM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

moesif_cache_system_implementation : memory_implementation_source \
																		 snoopy_moesif_implementation \
																		 snoopy_invalidate_commands_implementation_source \
																		 arbiter_implementation_source \
																		 snoopy_invalidate_protocol_implementation \
																		 snoopy_invalidate_cache_implementation \
																		 simple_arbiter_implementation \
																		 snoopy_invalidate_bus_implementation \
																		 moesif_cache_system_implementation_source

moesif_cache_system_verification_source : $(MOESIF_CACHE_SYSTEM_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

moesif_cache_system_verification : moesif_cache_system_implementation \
																	 memory_implementation_source \
																	 ram_implementation \
																	 moesif_cache_system_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#moesi cache system
MOESI_CACHE_SYSTEM_SOURCE_DIRECTORY      = $(MEMORY_SYSTEMS_SOURCE_DIRECTORY)/moesiCacheSystem
MOESI_CACHE_SYSTEM_IMPLEMENTATION_SOURCE = $(MOESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/implementation/moesiCacheSystem.sv 
MOESI_CACHE_SYSTEM_VERIFICATION_SOURCE   = $(MOESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/dutInterface.sv \
																					 $(MOESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testInterface.sv \
																					 $(MOESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testPackage.sv \
																					 $(MOESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testBench.sv

moesi_cache_system_implementation_source : $(MOESI_CACHE_SYSTEM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

moesi_cache_system_implementation : memory_implementation_source \
																		snoopy_moesi_implementation \
																		snoopy_invalidate_commands_implementation_source \
																		arbiter_implementation_source \
																		snoopy_invalidate_protocol_implementation \
																		snoopy_invalidate_cache_implementation \
																		simple_arbiter_implementation \
																		snoopy_invalidate_bus_implementation \
																		moesi_cache_system_implementation_source

moesi_cache_system_verification_source : $(MOESI_CACHE_SYSTEM_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

moesi_cache_system_verification : moesi_cache_system_implementation \
																	memory_implementation_source \
																	ram_implementation \
																	moesi_cache_system_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#msi cache system
MSI_CACHE_SYSTEM_SOURCE_DIRECTORY      = $(MEMORY_SYSTEMS_SOURCE_DIRECTORY)/msiCacheSystem
MSI_CACHE_SYSTEM_IMPLEMENTATION_SOURCE = $(MSI_CACHE_SYSTEM_SOURCE_DIRECTORY)/implementation/msiCacheSystem.sv 
MSI_CACHE_SYSTEM_VERIFICATION_SOURCE   = $(MSI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/dutInterface.sv \
																				 $(MSI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testInterface.sv \
																				 $(MSI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testPackage.sv \
																				 $(MSI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testBench.sv

msi_cache_system_implementation_source : $(MSI_CACHE_SYSTEM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

msi_cache_system_implementation : memory_implementation_source \
																	snoopy_msi_implementation \
																	snoopy_invalidate_commands_implementation_source \
																	arbiter_implementation_source \
																	snoopy_invalidate_protocol_implementation \
																	snoopy_invalidate_cache_implementation \
																	simple_arbiter_implementation \
																	snoopy_invalidate_bus_implementation \
																	msi_cache_system_implementation_source 


msi_cache_system_verification_source : $(MSI_CACHE_SYSTEM_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

msi_cache_system_verification : memory_implementation_source \
																ram_implementation \
																msi_cache_system_implementation \
																msi_cache_system_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#mesi cache system
MESI_CACHE_SYSTEM_SOURCE_DIRECTORY      = $(MEMORY_SYSTEMS_SOURCE_DIRECTORY)/mesiCacheSystem
MESI_CACHE_SYSTEM_IMPLEMENTATION_SOURCE = $(MESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/implementation/mesiCacheSystem.sv
MESI_CACHE_SYSTEM_VERIFICATION_SOURCE   = $(MESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/dutInterface.sv \
																					$(MESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testInterface.sv \
																					$(MESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testPackage.sv \
																					$(MESI_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testBench.sv

mesi_cache_system_implementation_source : $(MESI_CACHE_SYSTEM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

mesi_cache_system_implementation : memory_implementation_source \
																	 snoopy_mesi_implementation \
																	 snoopy_invalidate_commands_implementation_source \
																	 arbiter_implementation_source \
																	 snoopy_invalidate_protocol_implementation \
																	 snoopy_invalidate_cache_implementation \
																	 simple_arbiter_implementation \
																	 snoopy_invalidate_bus_implementation \
																	 ram_implementation \
																	 mesi_cache_system_implementation_source 

mesi_cache_system_verification_source : $(MESI_CACHE_SYSTEM_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

mesi_cache_system_verification : memory_implementation_source \
																 ram_implementation \
																 mesi_cache_system_implementation \
																 mesi_cache_system_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#mesif cache system
MESIF_CACHE_SYSTEM_SOURCE_DIRECTORY      = $(MEMORY_SYSTEMS_SOURCE_DIRECTORY)/mesifCacheSystem
MESIF_CACHE_SYSTEM_IMPLEMENTATION_SOURCE = $(MESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/implementation/mesifCacheSystem.sv
MESIF_CACHE_SYSTEM_VERIFICATION_SOURCE   = $(MESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/dutInterface.sv \
																					 $(MESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testInterface.sv \
																					 $(MESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testPackage.sv \
																					 $(MESIF_CACHE_SYSTEM_SOURCE_DIRECTORY)/verification/testBench.sv

mesif_cache_system_implementation_source : $(MESIF_CACHE_SYSTEM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

mesif_cache_system_implementation : memory_implementation_source \
																	 	snoopy_mesif_implementation \
																	 	snoopy_invalidate_commands_implementation_source \
																	 	arbiter_implementation_source \
																	 	snoopy_invalidate_protocol_implementation \
																	 	snoopy_invalidate_cache_implementation \
																	 	simple_arbiter_implementation \
																	 	snoopy_invalidate_bus_implementation \
																	 	ram_implementation \
																	 	mesif_cache_system_implementation_source 

mesif_cache_system_verification_source : $(MESIF_CACHE_SYSTEM_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

mesif_cache_system_verification : memory_implementation_source \
																  ram_implementation \
																  mesif_cache_system_implementation \
																  mesif_cache_system_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#simple bus
SIMPLE_BUS_SOURCE_DIRECTORY      = $(MEMORY_SOURCE_DIRECTORY)/bus
SIMPLE_BUS_IMPLEMENTATION_SOURCE = $(SIMPLE_BUS_SOURCE_DIRECTORY)/implementation/*.sv

simple_bus_implementation_source : $(SIMPLE_BUS_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

simple_bus_implementation : memory_implementation_source \
														arbiter_implementation_source \
														simple_bus_implementation_source

#basic memory system
BASIC_MEMORY_SYSTEM_SOURCE_DIRECTORY      = $(MEMORY_SYSTEMS_SOURCE_DIRECTORY)/basicMemorySystem
BASIC_MEMORY_SYSTEM_IMPLEMENTATION_SOURCE = $(BASIC_MEMORY_SYSTEM_SOURCE_DIRECTORY)/implementation/basicMemorySystem.sv
BASIC_MEMORY_SYSTEM_VERIFICATION_SOURCE   = $(BASIC_MEMORY_SYSTEM_SOURCE_DIRECTORY)/verification/dutInterface.sv \
																						$(BASIC_MEMORY_SYSTEM_SOURCE_DIRECTORY)/verification/testInterface.sv \
																						$(BASIC_MEMORY_SYSTEM_SOURCE_DIRECTORY)/verification/testPackage.sv \
																						$(BASIC_MEMORY_SYSTEM_SOURCE_DIRECTORY)/verification/testBench.sv

basic_memory_system_implementation_source : $(BASIC_MEMORY_SYSTEM_IMPLEMENTATION_SOURCE)
	$(VLOG) $?

basic_memory_system_implementation : memory_implementation_source \
																	 	 arbiter_implementation_source \
																	 	 simple_arbiter_implementation \
																		 simple_bus_implementation \
																	 	 basic_memory_system_implementation_source 

basic_memory_system_verification_source : $(BASIC_MEMORY_SYSTEM_VERIFICATION_SOURCE)
	$(UVM_COMMAND) $?

basic_memory_system_verification : basic_memory_system_implementation \
																	 memory_implementation_source \
																	 ram_implementation \
																	 basic_memory_system_verification_source
	$(MODELSIM_VERIFICATION_COMMAND)

#comparison simulation
COMPARISON_SIMULATION_SOURCE_DIRECTORY = $(SRC)/comparisonSimulation
COMPARISON_SIMULATION_SOURCE           = $(COMPARISON_SIMULATION_SOURCE_DIRECTORY)/dutInterface.sv \
																				 $(COMPARISON_SIMULATION_SOURCE_DIRECTORY)/testInterface.sv \
																				 $(COMPARISON_SIMULATION_SOURCE_DIRECTORY)/testPackage.sv \
																				 $(COMPARISON_SIMULATION_SOURCE_DIRECTORY)/testBench.sv

comaprison_simulation_source : $(COMPARISON_SIMULATION_SOURCE)
	$(UVM_COMMAND) $?


comparison_simulation : basic_memory_system_implementation \
												msi_cache_system_implementation \
												mesi_cache_system_implementation \
												mesif_cache_system_implementation \
												moesi_cache_system_implementation \
												moesif_cache_system_implementation \
											  memory_implementation_source \
												ram_implementation \
												comaprison_simulation_source	
	$(MODELSIM_VERIFICATION_COMMAND)
