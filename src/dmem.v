// RAM de dades 256 x 8 bits. Lectura síncrona i escriptura síncrona.
module dmem(
  input clk,
  input wen,
  input [7:0] waddr,
  input [7:0] wdata,
  input [7:0] raddr,
  output reg [7:0] rdata
);
  
  reg [7:0] mem [0:255];
  integer i;
  initial begin
    for (i=0;i<256;i=i+1) mem[i] = 8'b0;
  end
    
  always @(posedge clk) begin
    if (wen) mem[waddr] <= wdata;
    rdata <= mem[raddr];
  end
endmodule
