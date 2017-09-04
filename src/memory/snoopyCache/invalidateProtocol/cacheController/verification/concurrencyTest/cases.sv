/*
	There are several cases where race condition appears:
	1) READ_BUS_INVALIDATE
		In this case a bus invalidate appears simultaneously with a processor. In this we wait for cpu to finish read the lock and invalidate.
	2) WRITE_BUS_READ_NO_INVALIDATE
		In this case a bus read appears simultaneously with a cpu write, but block is in the EXCLUSIVE state so we do not need to invalidate. Here we let processor to 
		finish the operation and the invalidate.
	3) WRITE_BUS_READ_INVALIDATE
		In this case a bus read appears simultaneously with a cpu write, but block is not in the EXCLUSIVE state so we do need to invalidate. Here we have to invalidate
		and reset the processor to the begining since the bus is occupied
	4) WRITE_BUS_INVALIDATE
		In this case a bus write appears simulatenously with invalidate. The block cannot be in EXCLUSIVE since invalidate message is received so we have to reset 
		processor controller and invalidate then write. The processor will be stuck on bus wait in invalidate method.
	5) WRITE_BACK_BUS_READ
		In this case a bus read appears simultaneously with a writeback. Here we first serve read the allow write back.
	6) WRITE_BACK_BUS_INVALIDATE
		In this case a bs invalidate appears simultaneously with a writeback. This is not a race condition. Here we simply invalidate and speed up cpu controller 
		request by reseting it to idle.
*/
package cases;
	typedef enum {
			READ_BUS_INVALIDATE,
			WRITE_BUS_READ_NO_INVALIDATE,
			WRITE_BUS_READ_INVALIDATE,
			WRITE_BUS_INVALIDATE,
			WRITE_BACK_BUS_READ,
			WRITE_BACK_BUS_INVALIDATE
	} ConcurrencyCase;
endpackage : cases
