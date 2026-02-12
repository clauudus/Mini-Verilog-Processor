// ROM d'instruccions (paraules de 16 bits). S'inicialitza amb un fitxer hex.
module imem(
  input [7:0] addr, // index a paraules de 16 bits
  output [15:0] dout
);
    reg [15:0] mem [0:255];
  initial begin
    // llegir fitxer program.hex (columna de paraules hex de 16-bit)
    $readmemh("programs/program.hex", mem);
  end
  assign dout = mem[addr];
endmodule
