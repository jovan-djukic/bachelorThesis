module MOESIF(
	CPUProtocolInterface.protocol cpuProtocolInterface,
	SnoopyProtocolInterface.protocol snoopyProtocolInterface,
	MOESIFInterface.protocol moesifInterface
);
	import states::*;
	import commands::*;

	//cpu controller
	assign cpuProtocolInterface.writeBackRequired     = cpuProtocolInterface.stateOut == MODIFIED || cpuProtocolInterface.stateOut == OWNED ? 1 : 0;
	assign cpuProtocolInterface.invalidateRequired    = cpuProtocolInterface.stateOut != MODIFIED && cpuProtocolInterface.stateOut != EXCLUSIVE ? 1 : 0;
	assign cpuProtocolInterface.readExclusiveRequired = cpuProtocolInterface.stateOut == INVALID && cpuProtocolInterface.write == 1 ? 1 : 0;

	always_comb begin
		cpuProtocolInterface.stateIn = INVALID;
		case (cpuProtocolInterface.stateOut)
			MODIFIED: begin
				cpuProtocolInterface.stateIn = MODIFIED;
			end

			OWNED: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = OWNED;
				end else if (cpuProtocolInterface.write == 1) begin
					cpuProtocolInterface.stateIn = MODIFIED;
				end
			end

			EXCLUSIVE: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = EXCLUSIVE;
				end else if (cpuProtocolInterface.write == 1) begin
					cpuProtocolInterface.stateIn = MODIFIED;
				end
			end

			SHARED: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = SHARED;
				end else if (cpuProtocolInterface.write == 1) begin
					cpuProtocolInterface.stateIn = MODIFIED;
				end
			end

			INVALID: begin
				if (cpuProtocolInterface.read == 1) begin
					if (moesifInterface.sharedIn == 1) begin
						cpuProtocolInterface.stateIn = FORWARD;
					end else begin
						cpuProtocolInterface.stateIn = EXCLUSIVE;
					end
				end else if (cpuProtocolInterface.write == 1) begin
					cpuProtocolInterface.stateIn = MODIFIED;
				end
			end

			FORWARD: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = FORWARD;
				end else if (cpuProtocolInterface.write == 1) begin
					cpuProtocolInterface.stateIn = MODIFIED;
				end
			end
		endcase
	end

	//snoopy protocol
	assign snoopyProtocolInterface.request = snoopyProtocolInterface.stateOut == MODIFIED ||
																					 snoopyProtocolInterface.stateOut == EXCLUSIVE ||
																					 snoopyProtocolInterface.stateOut == FORWARD ? 1 : 0;		
	
	assign moesifInterface.sharedOut = snoopyProtocolInterface.stateOut != INVALID ? 1 : 0;

	always_comb begin
		snoopyProtocolInterface.stateIn = INVALID;
		case (snoopyProtocolInterface.stateOut)
			MODIFIED: begin
				if (snoopyProtocolInterface.commandIn == BUS_READ) begin
					snoopyProtocolInterface.stateIn = OWNED;
				end else if (snoopyProtocolInterface.commandIn == BUS_INVALIDATE) begin
					snoopyProtocolInterface.stateIn = INVALID;
				end else if (snoopyProtocolInterface.commandIn == BUS_READ_EXCLUSIVE)	begin
					snoopyProtocolInterface.stateIn = INVALID;
				end
			end

			OWNED: begin
				if (snoopyProtocolInterface.commandIn == BUS_READ) begin
					snoopyProtocolInterface.stateIn = OWNED;
				end else if (snoopyProtocolInterface.commandIn == BUS_INVALIDATE) begin
					snoopyProtocolInterface.stateIn = INVALID;
				end else if (snoopyProtocolInterface.commandIn == BUS_READ_EXCLUSIVE)	begin
					snoopyProtocolInterface.stateIn = INVALID;
				end
			end

			EXCLUSIVE: begin
				if (snoopyProtocolInterface.commandIn == BUS_READ) begin
					snoopyProtocolInterface.stateIn = SHARED;
				end else if (snoopyProtocolInterface.commandIn == BUS_INVALIDATE) begin
					snoopyProtocolInterface.stateIn = INVALID;
				end else if (snoopyProtocolInterface.commandIn == BUS_READ_EXCLUSIVE)	begin
					snoopyProtocolInterface.stateIn = INVALID;
				end
			end

			SHARED: begin
				if (snoopyProtocolInterface.commandIn == BUS_READ) begin
					snoopyProtocolInterface.stateIn = SHARED;
				end else if (snoopyProtocolInterface.commandIn == BUS_INVALIDATE) begin
					snoopyProtocolInterface.stateIn = INVALID;
				end else if (snoopyProtocolInterface.commandIn == BUS_READ_EXCLUSIVE)	begin
					snoopyProtocolInterface.stateIn = INVALID;
				end
			end

			INVALID: begin
				snoopyProtocolInterface.stateIn = INVALID;
			end

			FORWARD: begin
				if (snoopyProtocolInterface.commandIn == BUS_READ) begin
					snoopyProtocolInterface.stateIn = SHARED;
				end else if (snoopyProtocolInterface.commandIn == BUS_INVALIDATE) begin
					snoopyProtocolInterface.stateIn = INVALID;
				end else if (snoopyProtocolInterface.commandIn == BUS_READ_EXCLUSIVE)	begin
					snoopyProtocolInterface.stateIn = INVALID;
				end
			end
		endcase
	end
endmodule : MOESIF
