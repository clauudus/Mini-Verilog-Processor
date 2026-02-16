// ALU simple: operacions sobre 8-bit
module alu(
	input [2:0] op, // petit codi intern
	input [7:0] a,
	input [7:0] b,
	output reg [7:0] y,
	output zero
);

	// op encodings (interns): 3'b000 ADD, 001 SUB, 010 AND, 011 OR
	assign zero = (y == 8'b0);
	always @(*) begin
		case(op)
			3'b000: y = a + b; // ADD
			3'b001: y = a - b; // SUB
			3'b010: y = a & b; // AND
			3'b011: y = a | b; // OR
			3'b100: y = a != 0; //JNZ = Jump Not Zero
			default: y = 8'b0;
		endcase
	end
endmodule

