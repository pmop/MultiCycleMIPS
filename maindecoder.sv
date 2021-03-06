module maindec(	input logic clk, reset,
		input logic [5:0] op,
		output logic IorD, IRwrite, memwrite, memtoreg,
		output logic branch, pcwrite, regwrite, regdst,
		output logic alusrcA,
		output logic [1:0] alusrcB, aluop, pcsrc);

	logic [14:0] controlWord;
	logic [3:0] state;
	initial	state = 4'b0000;

	always_ff @(posedge clk)
		if (~reset)
		begin
			case (state)
				4'b0000: assign state = 4'b0001;
				4'b0001:
				begin
					case (op)
						6'b000000: assign state = 4'b0110; // RTYPE
						6'b100011: assign state = 4'b0010; // LW
						6'b101011: assign state = 4'b0010; // SW
						6'b000100: assign state = 4'b1000; // BEQ
						6'b001000: assign state = 4'b1001; // ADDI
						6'b000010: assign state = 4'b1011; // J
						default:   assign state = 4'bzzzz; // illegal op
					endcase
				end
	
				4'b0010: 
				begin
					case (op)
							6'b100011: assign state = 4'b0011; // LW
						6'b101011: assign state = 4'b0101; // SW
					endcase
				end
				
				4'b0011: assign state = 4'b0100;
				4'b0100: assign state = 4'b0000;
				4'b0101: assign state = 4'b0000;
				4'b0110: assign state = 4'b0111;
				4'b0111: assign state = 4'b0000;
				4'b1000: assign state = 4'b0000;
				4'b1001: assign state = 4'b1010;
				4'b1010: assign state = 4'b0000;
				4'b1011: assign state = 4'b0000;
			endcase 
		end

	always_comb
	begin
		case(state)
			4'b0000: //fetch
			begin
				assign IorD = 0;
				assign alusrcA = 0;
				assign alusrcB = 2'b01;
				assign aluop = 2'b00;
				assign pcsrc = 2'b00;
				assign IRwrite = 1;
				assign pcwrite = 1;
				assign regwrite = 0;
				assign branch = 0;
				assign memwrite = 0;
				assign regdst = 0;
				assign memtoreg = 0;
			end

			4'b0001: //decode
			begin
				assign alusrcA = 0;
				assign alusrcB = 2'b11;
				assign aluop = 2'b00;
				assign IRwrite = 0;
				assign pcwrite = 0;
			end
			
			4'b0010: //MemAdr (SW and LW)
			begin
				assign alusrcA = 1;
				assign alusrcB = 2'b10;
				assign aluop = 2'b00;
			end

			4'b0011: 
			begin //MemRead (LW)
				assign IorD = 1; 
			end
			4'b0100: //WriteBack (LW)
			begin
				assign regdst = 0;
				assign memtoreg = 1;
				assign regwrite = 1;
			end

			4'b0101: //MemWrite (SW)
			begin
				assign IorD = 1;
				assign memwrite = 1;
			end

			4'b0110: //Execute (R-type)
			begin
				assign alusrcA = 1;
				assign alusrcB = 2'b00;
				assign aluop = 2'b10;
			end

			4'b0111: //Write back (R-type)
			begin
				assign regdst = 1;
				assign memtoreg = 0;
				assign regwrite = 1;
			end 

			4'b1000: //Branch (BEQ)
			begin
				assign alusrcA = 1;
				assign alusrcB = 2'b00;
				assign aluop = 2'b01;
				assign pcsrc = 2'b01;
				assign branch = 1;
			end

			4'b1001: //Execute (ADDI)
			begin
				assign alusrcA = 1;
				assign alusrcB = 2'b10;
				assign aluop = 2'b00;
			end

			4'b1010: //Writeback (ADDI)
			begin
				assign regdst = 0;
				assign memtoreg = 0;
				assign regwrite = 1;
			end
		
			4'b1011: //Jump
			begin
				assign pcsrc = 2'b10;
				assign pcwrite = 1;
			end
		endcase
		assign controlWord = {pcwrite, memwrite, IRwrite, regwrite, alusrcA, branch, IorD, memtoreg, regdst, alusrcB, pcsrc, aluop};
	end
endmodule
