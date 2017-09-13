package classImplementation;
	import commands::*;
	import states::*;

	class MOESIFClassImplementation;
		function int writeBackRequired(CacheLineState state);
			return state == MODIFIED || state == OWNED ? 1 : 0;
		endfunction : writeBackRequired

		function int invalidateRequired(CacheLineState state, int write);
			return state != MODIFIED && state != EXCLUSIVE && write == 1 ? 1 : 0;
		endfunction : invalidateRequired

		function int readExclusiveRequired(CacheLineState state, int write);
			return state == INVALID && write == 1 ? 1 : 0;
		endfunction : readExclusiveRequired

		function CacheLineState cpuStateIn(CacheLineState state, int read, int write, int sharedIn, int ownedIn);
			CacheLineState returnState = INVALID;
			case (state)
				MODIFIED: begin
					return MODIFIED;
				end

				OWNED: begin
					if (read == 1) begin
						returnState = OWNED;
					end else if (write == 1) begin
						returnState = MODIFIED;
					end
				end

				EXCLUSIVE: begin
					if (read == 1) begin
						returnState = EXCLUSIVE;
					end else if (write == 1) begin
						returnState = MODIFIED;
					end
				end

				SHARED: begin
					if (read == 1) begin
						returnState = SHARED;
					end else if (write == 1) begin
						returnState = MODIFIED;
					end
				end

				INVALID: begin
					if (read == 1) begin
						if (ownedIn == 1) begin
						 	returnState = SHARED;
						end else if (sharedIn == 1) begin
							returnState = FORWARD;
						end else begin
							returnState = EXCLUSIVE;
						end
					end else if (write == 1) begin
						returnState = MODIFIED;
					end
				end

				FORWARD: begin
					if (read == 1) begin
						returnState = FORWARD;
					end else if (write == 1) begin
						returnState = MODIFIED;
					end
				end
			endcase
			return returnState;
		endfunction : cpuStateIn

		function int request(CacheLineState state);
			return state == MODIFIED || state == EXCLUSIVE || state == FORWARD || state == OWNED ? 1 : 0;
		endfunction : request

		function int sharedOut(CacheLineState state);
			return state != INVALID ? 1 : 0;
		endfunction : sharedOut

		function int ownedOut(CacheLineState state);
			return state ==  OWNED ? 1 : 0;
		endfunction : ownedOut

		function CacheLineState snoopyStateIn(CacheLineState state, Command command);
			CacheLineState returnState = INVALID;
			case (state)
				MODIFIED: begin
					if (command == BUS_READ) begin
						returnState = OWNED;
					end else if (command == BUS_INVALIDATE) begin
						returnState = INVALID;
					end else if (command == BUS_READ_EXCLUSIVE)	begin
						returnState = INVALID;
					end
				end

				OWNED: begin
					if (command == BUS_READ) begin
						returnState = OWNED;
					end else if (command == BUS_INVALIDATE) begin
						returnState = INVALID;
					end else if (command == BUS_READ_EXCLUSIVE)	begin
						returnState = INVALID;
					end
				end

				EXCLUSIVE: begin
					if (command == BUS_READ) begin
						returnState = SHARED;
					end else if (command == BUS_INVALIDATE) begin
						returnState = INVALID;
					end else if (command == BUS_READ_EXCLUSIVE)	begin
						returnState = INVALID;
					end
				end

				SHARED: begin
					if (command == BUS_READ) begin
						returnState = SHARED;
					end else if (command == BUS_INVALIDATE) begin
						returnState = INVALID;
					end else if (command == BUS_READ_EXCLUSIVE)	begin
						returnState = INVALID;
					end
				end

				INVALID: begin
					returnState = INVALID;
				end

				FORWARD: begin
					if (command == BUS_READ) begin
						returnState = SHARED;
					end else if (command == BUS_INVALIDATE) begin
						returnState = INVALID;
					end else if (command == BUS_READ_EXCLUSIVE)	begin
						returnState = INVALID;
					end
				end
			endcase
			return returnState;
		endfunction : snoopyStateIn
	endclass;
endpackage : classImplementation
