// 8 registers de 8 bits amb 2 ports de lectura i 1 port d'escriptura síncron
module regfile(
  input clk,
  input wen,
  input [2:0] waddr,
  input [7:0] wdata,
  input [2:0] raddr1,
  input [2:0] raddr2,
  output [7:0] rdata1,
  output [7:0] rdata2
);
  reg [7:0] regs [0:7];
  integer i;
  initial begin
    for (i=0;i<8;i=i+1) regs[i] = 8'b0;
  end


  // lectures combinacionals
  assign rdata1 = regs[raddr1];
  assign rdata2 = regs[raddr2];


  // escriptura sincrona
  always @(posedge clk) begin
    if (wen) begin
      regs[waddr] <= wdata;
    end
  end
endmodule
