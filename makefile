VLOG				 = vlog
SRC					 = src
UVM_HOME		 = ./$(SRC)/uvm-1.1d
INCLUDES		 = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv
FLAGS				 = +define+UVM_NO_DPI
UVM_COMMAND  = $(VLOG) $(FLAGS) $(INCLUDES)

#basic circuits
BASIC_CIRCUITS_SOURCE_DIRECTORY	= $(SRC)/basicCircuits
BASIC_CIRCUITS_IMPLEMENTATION		= $(BASIC_CIRCUITS_SOURCE_DIRECTORY)/*.sv

basic_circuits : $(BASIC_CIRCUITS_IMPLEMENTATION)
	$(VLOG) $(BASIC_CIRCUITS_IMPLEMENTATION)

#Replacement algorithm implementation
REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY	= $(SRC)/replacementAlgorithm
REPLACEMENT_ALGORITHM_IMPLEMENTATION  	= $(REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/*.sv
REPLACEMENT_ALGORITHM_VERIFICATION    	= $(REPLACEMENT_ALGORITHM_IMPLEMENTATION) $(REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/verification/*.sv 

#lru
LRU_SOURCE_DIRECTORY	= $(REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/lru
LRU_IMPLEMENTATION  	= $(REPLACEMENT_ALGORITHM_IMPLEMENTATION) $(LRU_SOURCE_DIRECTORY)/implementation/*.sv
LRU_VERIFICATION    	= $(REPLACEMENT_ALGORITHM_VERIFICATION) \
												$(LRU_IMPLEMENTATION) \
											 	$(LRU_SOURCE_DIRECTORY)/verification/*.sv 

lru_implementation	: $(LRU_IMPLEMENTATION)
	$(VLOG) $(LRU_IMPLEMENTATION)

lru_verification		: $(LRU_VERIFICATION)
	$(UVM_COMMAND) $(LRU_VERIFICATION)

#memory
MEMORY_SOURCE_DIRECTORY	= $(SRC)/memory
MEMORY_IMPLEMENTATION 	= $(MEMORY_SOURCE_DIRECTORY)/memoryInterface.sv 

memory_implementation : $(MEMORY_IMPLEMENTATION)
	$(VLOG) $(MEMORY_IMPLEMENTATION)

#ram
RAM_SOURCE_DIRECTORY	=	$(MEMORY_SOURCE_DIRECTORY)/ram
RAM_IMPLEMENTATION		= $(MEMORY_IMPLEMENTATION) $(RAM_SOURCE_DIRECTORY)/implementation/ram.sv 
RAM_VERIFICATION			=	$(RAM_IMPLEMENTATION) $(RAM_SOURCE_DIRECTORY)/verification/*.sv

ram_implementation : $(RAM_IMPLEMENTATION)
	$(VLOG) $(RAM_IMPLEMENTATION)
	
ram_verification : $(RAM_VERIFICATION)
	$(UVM_COMMAND) $(RAM_VERIFICATION)

#cache memory
CACHE_MEMORY_SOURCE_DIRECTORY	=	$(MEMORY_SOURCE_DIRECTORY)/cache
CACHE_MEMORY_IMPLEMENTATION		= $(CACHE_MEMORY_SOURCE_DIRECTORY)/*.sv

#tag memory
TAG_MEMORY_SOURCE_DIRECTORY	=	$(CACHE_MEMORY_SOURCE_DIRECTORY)/tagMemory
TAG_MEMORY_IMPLEMENTATION		= $(CACHE_MEMORY_IMPLEMENTATION) $(TAG_MEMORY_SOURCE_DIRECTORY)/implementation/*.sv
TAG_MEMORY_VERIFIACTION			= $(TAG_MEMORY_IMPLEMENTATION) $(TAG_MEMORY_SOURCE_DIRECTORY)/verification/*.sv

tag_memory_implementation : $(TAG_MEMORY_IMPLEMENTATION)
	$(VLOG) $(TAG_MEMORY_IMPLEMENTATION)

tag_memory_verification	:	$(TAG_MEMORY_VERIFIACTION)
	$(UVM_COMMAND) $(TAG_MEMORY_VERIFIACTION)
