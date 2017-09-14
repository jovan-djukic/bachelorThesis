module WidthAdapter#(
	int MASTER_ADDRESS_WIDTH,
	int MASTER_DATA_WIDTH,
	int SLAVE_ADDRESS_WIDTH,
	int SLAVE_DATA_WIDTH
)(
	MemoryInterface.slave slaveInterface,
	MemoryInterface.master masterInterface,
	input logic clock, reset
);

	localparam MASTER_SLAVE_WORD_RATIO = (MASTER_DATA_WIDTH + SLAVE_DATA_WIDTH - 1) / SLAVE_DATA_WIDTH;
	localparam ADDRESS_DIFFERENCE      = SLAVE_ADDRESS_WITDH - MASTER_ADDRESS_WITDH;

	logic[SLAVE_DATA_WIDTH - 1     : 0] dataBuffer[MASTER_SLAVE_WORD_RATIO];
	logic[MASTER_ADDRESS_WITDH - 1 : 0] addressBuffer;
	logic															  writeEnabled, isReset;

	assign slaveInterface.dataIn = dataBuffer[slaveInterface.address[ADDRESS_DIFFERENCE - 1 : 0]];
	assign masterInterface.address = addressBuffer;
	assign masterInterface.dataOut = dataBuffer;

	typedef enum logic {
		READ_REQUEST,
		WAITING_FOR_READ_COMPLETE	
	} ReadState;
	ReadState readState;

	task read();
		case (readState) 
			READ_REQUEST: begin
				masterInterface.readEnabled <= 1;
				addressBuffer               <= slaveInterface.address[slaveInterface.ADDRESS_WITDH - 1 : ADDRESS_DIFFERENCE];
				readState                   <= WAITING_FOR_READ_COMPLETE;
			end

			WAITING_FOR_READ_COMPLETE: begin
				if (masterInterface.functionComplete == 1) begin
					masterInterface.readEnabled <= 0;
					readState                   <= READ_REQUEST;

					for (int i = 0; i < MASTER_SLAVE_WORD_RATIO; i++) begin
						dataBuffer[i] <= masterInterface.dataIn[i * slaveInterface.DATA_WIDTH +: slaveInterface.DATA_WIDTH];
					end

					addressBuffer <= masterInterface.address;
				end
			end
		endcase
	endtask : read

	typedef enum logic {
		WRITE_REQUEST,
		WAITING_FOR_WRITE_COMPLETE	
	} WriteState;
	WriteState writeState;

	task write();
		dataBuffer[slaveInterface.address[ADDRESS_DIFFERENCE - 1 : 0]] <= slaveInterface.dataOut;
		addressBuffer <= slaveInterface.addressBuffer[slaveInterface.ADDRESS_WITDH - 1 : ADDRESS_DIFFERENCE];

		if ((& slaveInterface.address[ADDRESS_DIFFERENCE - 1 : 0]) == 1) begin
			case (writeState)
				WRITE_REQUEST: begin
					masterInterface.writeEnabled <= 1;
					writeState <= WAITING_FOR_WRITE_COMPLETE;
				end

				WAITING_FOR_WRITE_COMPLETE: begin
					if (masterInterface.functionComplete == 1) begin
						masterInterface.writeEnabled <= 0;
						writeState <= WRITE_REQUEST;
						slaveInterface.functionComplete <= 1;
					end
				end
			endcase
		end else begin
			slaveInterface.functionComplete <= 1;
		end
	endtask : write

	task adapterReset();
		readState  <= READ_REQUEST;
		writeState <= WRITE_REQUEST;
		isReset    <= 1;
	endtask : adapterReset

	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			adapterReset();
		end else begin
			slaveInterface.functionComplete <= 0;
			if (slaveInterface.readEnabled == 1) begin
				if (addressBuffer == slaveInterface.addressBuffer[SLAVE_ADDRESS_WIDTH - 1 : ADDRESS_DIFFERENCE] && isReset == 0) begin
					isReset                         <= 0;
					slaveInterface.functionComplete <= 1;
				end else begin
					read();
				end	
			end else if (slaveInterface.writeEnabled == 1) begin
				if (addressBuffer == slaveInterface.addressBuffer[SLAVE_ADDRESS_WIDTH - 1 : ADDRESS_DIFFERENCE] && isReset == 0) begin
					isReset                         <= 0;
					slaveInterface.functionComplete <= 1;
				end else begin
					write();
				end	
			end
		end
	end
endmodule : WidthAdapter
