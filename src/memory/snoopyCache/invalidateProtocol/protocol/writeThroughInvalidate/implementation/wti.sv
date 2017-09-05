module WriteThroughInvalidate(
	CPUProtocolInterface.protocol cpuProtocolInterface
);
	import states::*;
	
	assign cpuProtocolInterface.writeBackRequired  = cpuProtocolInterface.stateOut == DIRTY ? 1 : 0;
	assign cpuProtocolInterface.invalidateRequired = cpuProtocolInterface.stateOut == VALID && cpuProtocolInterface.write == 1 ? 1 : 0;
	
	always_comb begin
		case (cpuProtocolInterface.stateOut)
			INVALID: begin
				cpuProtocolInterface.stateIn = VALID;
			end

			VALID: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = VALID;
				end else begin
					cpuProtocolInterface.stateIn = DIRTY;
				end
			end

			DIRTY: begin
				cpuProtocolInterface.stateIn = DIRTY;
			end
		endcase
	end
		
endmodule : WriteThroughInvalidate
