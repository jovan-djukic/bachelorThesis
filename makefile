VLOG     = vlog
FLAGS    = +define+UVM_NO_DPI
SRC      = src
UVM_HOME = ./$(SRC)/uvm-1.1d
INCLUDES = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv
COMMAND  = $(VLOG) $(FLAGS) $(INCLUDES)

#Replacement algorithm implementation
REPLACEMENT_ALGORITHM_IMPLEMENTATION  = $(SRC)/replacementAlgorithm/replacementAlgorithmInterface.sv
REPLACEMENT_ALGORITHM_VERIFICATION    = $(REPLACEMENT_ALGORITHM_BASE) $(SRC)/replacementAlgorithm/verification/replacementAlgorithmVerification.sv 

#lru
LRU_IMPLEMENTATION  = $(REPLACEMENT_ALGORITHM_IMPLEMENTATION) $(SRC)/replacementAlgorithm/lru/implementation/lru.sv
LRU_VERIFICATION    = $(REPLACEMENT_ALGORITHM_VERIFICATION) $(SRC)/replacementAlgorithm/lru/verification/lruVerification.sv $(SRC)/replacementAlgorithm/lru/verification/TestBench.sv

lru_implementation	: $(LRU_IMPLEMENTATION)
	$(COMMAND) $(LRU_IMPLEMENTATION)

lru_verification		: $(LRU_VERIFICATION)
	$(COMMAND) $(LRU_VERIFICATION)
