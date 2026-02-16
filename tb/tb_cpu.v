module tb;
    reg clk = 0;
    reg rst = 1;
    wire halted;
    wire [7:0] pc;

    // instantation of CPU
    cpu uut(.clk(clk), .rst(rst), .halted(halted), .pc_out(pc));

    // toggling clock
    always #5 clk = ~clk; // period 10 time units

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, tb);
        #12 rst = 0; // take out reset
        // Simulation during a limited time
        #1000;
        $finish;
    end
endmodule

