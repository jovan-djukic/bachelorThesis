module MSI(
	CPUProtocolInterface.protocol cpuProtocolInterface,
	SnoopyProtocolInterface.protocol snoopyProtocolInterface,
	output logic ramWriteRequired
);
	import MSIStates::*;
	import commands::*;
	
	//cpu protocol table
	assign cpuProtocolInterface.writeBackRequired     = cpuProtocolInterface.writeBackState == MODIFIED ? 1 : 0;
	assign cpuProtocolInterface.invalidateRequired    = cpuProtocolInterface.stateOut == SHARED && cpuProtocolInterface.write == 1 ? 1 : 0;
	assign cpuProtocolInterface.readExclusiveRequired = cpuProtocolInterface.stateOut == INVALID && cpuProtocolInterface.write == 1 ? 1 : 0;
	
	always_comb begin
		cpuProtocolInterface.stateIn = INVALID;
		case (cpuProtocolInterface.stateOut)
			INVALID: begin
				if (cpuProtocolInterface.read == 1) begin
					cpuProtocolInterface.stateIn = SHARED;
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

			MODIFIED: begin
				cpuProtocolInterface.stateIn = MODIFIED;
			end
		endcase
	end

	//snoopy protocol table
	assign snoopyProtocolInterface.request = snoopyProtocolInterface.stateOut == MODIFIED ? 1 : 0;

	assign ramWriteRequired = snoopyProtocolInterface.stateOut == MODIFIED && snoopyProtocolInterface.commandIn == BUS_READ ? 1 : 0;
	
	always_comb begin
		if (snoopyProtocolInterface.commandIn == BUS_READ) begin
			if (snoopyProtocolInterface.stateOut == INVALID) begin
				snoopyProtocolInterface.stateIn = INVALID;
			end else begin
				snoopyProtocolInterface.stateIn = SHARED;
			end
		end else begin
			snoopyProtocolInterface.stateIn = INVALID;
		end			
	end
endmodule : MSI
