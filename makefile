VLOG     = vlog
FLAGS    = +define+UVM_NO_DPI
SRC      = src
UVM_HOME = ./$(SRC)/uvm-1.1d
INCLUDES = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv
COMMAND  = $(VLOG) $(FLAGS) $(INCLUDES)

#Replacement algorithm implementation
REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY	= $(SRC)/replacementAlgorithm
REPLACEMENT_ALGORITHM_IMPLEMENTATION  	= $(REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/*.sv
REPLACEMENT_ALGORITHM_VERIFICATION    	= $(REPLACEMENT_ALGORITHM_BASE) $(REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/verification/*.sv 

#lru
LRU_SOURCE_DIRECTORY	= $(REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/lru
LRU_IMPLEMENTATION  	= $(REPLACEMENT_ALGORITHM_IMPLEMENTATION) $(LRU_SOURCE_DIRECTORY)/implementation/*.sv
LRU_VERIFICATION    	= $(REPLACEMENT_ALGORITHM_VERIFICATION) \
												$(LRU_IMPLEMENTATION) \
											 	$(LRU_SOURCE_DIRECTORY)/verification/*.sv 

lru_implementation	: $(LRU_IMPLEMENTATION)
	$(COMMAND) $(LRU_IMPLEMENTATION)

lru_verification		: $(LRU_VERIFICATION)
	$(COMMAND) $(LRU_VERIFICATION)

#memory
MEMORY_SOURCE_DIRECTORY	= $(SRC)/memory
MEMORY_IMPLEMENTATION 	= $(MEMORY_SOURCE_DIRECTORY)/memoryInterface.sv 

memory_implementation : $(MEMORY_IMPLEMENTATION)
	$(COMMAND) $(MEMORY_IMPLEMENTATION)

#ram
RAM_SOURCE_DIRECTORY	=	$(MEMORY_SOURCE_DIRECTORY)/ram
RAM_IMPLEMENTATION		= $(MEMORY_IMPLEMENTATION) $(RAM_SOURCE_DIRECTORY)/implementation/ram.sv 
RAM_VERIFICATION			=	$(RAM_IMPLEMENTATION) $(RAM_SOURCE_DIRECTORY)/verification/*.sv

ram_implementation : $(RAM_IMPLEMENTATION)
	$(COMMAND) $(RAM_IMPLEMENTATION)
	
ram_verification : $(RAM_VERIFICATION)
	$(COMMAND) $(RAM_VERIFICATION)

#cache
CACHE_SOURCE_DIRECTORY	=	$(MEMORY_SOURCE_DIRECTORY)/cache
CACHE_IMPLEMENTATION		= $(MEMORY_IMPLEMENTATION) $(CACHE_SOURCE_DIRECTORY)/implementation/*.sv

cache_implementation	: $(CACHE_IMPLEMENTATION)
	$(COMMAND) $(CACHE_IMPLEMENTATION)
