module WriteThroughInvalidate(
	CPUProtocolInterface.protocol cpuProtocolInterface,
	SnoopyProtocolInterface.protocol snoopyProtocolInterface
);
	import states::*;
	import commands::*;
	
	//cpu protocol table
	assign cpuProtocolInterface.writeBackRequired     = cpuProtocolInterface.stateOut == DIRTY ? 1 : 0;
	assign cpuProtocolInterface.invalidateRequired    = cpuProtocolInterface.stateOut == VALID && cpuProtocolInterface.write == 1 ? 1 : 0;
	assign cpuProtocolInterface.readExclusiveRequired = cpuProtocolInterface.stateOut == INVALID && cpuProtocolInterface.write == 1 ? 1 : 0;
	
	always_comb begin
		cpuProtocolInterface.stateIn = INVALID;
		case (cpuProtocolInterface.stateOut)
			INVALID: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = VALID;
				end else if (cpuProtocolInterface.write == 1) begin
					cpuProtocolInterface.stateIn = DIRTY;
				end
			end

			VALID: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = VALID;
				end else if (cpuProtocolInterface.write == 1) begin
					cpuProtocolInterface.stateIn = DIRTY;
				end
			end

			DIRTY: begin
				cpuProtocolInterface.stateIn = DIRTY;
			end
		endcase
	end

	//snoopy protocol table
	assign snoopyProtocolInterface.request = snoopyProtocolInterface.stateOut != INVALID ? 1 : 0;
	
	always_comb begin
		if (snoopyProtocolInterface.commandIn == BUS_READ) begin
			if (snoopyProtocolInterface.stateOut == INVALID) begin
				snoopyProtocolInterface.stateIn = INVALID;
			end else begin
				snoopyProtocolInterface.stateIn = VALID;
			end
		end else begin
			snoopyProtocolInterface.stateIn = INVALID;
		end			
	end
		
endmodule : WriteThroughInvalidate
