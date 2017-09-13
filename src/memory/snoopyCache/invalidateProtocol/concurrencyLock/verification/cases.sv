package cases;
	typedef enum {
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
	} ConcurrencyLockCase;
endpackage : cases
