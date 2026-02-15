// States: FETCH -> DECODE -> EXEC -> MEM -> WB -> FETCH

module cpu(
    input clk,
    input rst,
    output reg halted,
    output [7:0] pc_out
);
    // components
    wire [15:0] imem_cur, imem_nextw;
    reg [7:0] pc;
    assign pc_out = pc;

    // two IMEM instances, one to read the actual instruction, another one to read the next one
    imem imem0(.addr(pc), .dout(imem_cur));
    wire [7:0] pc_plus1 = pc + 8'd1;
    imem imem1(.addr(pc_plus1), .dout(imem_nextw));

    // regfile
    reg rf_wen;
    reg [2:0] rf_waddr;
    reg [7:0] rf_wdata;
    reg [2:0] rf_raddr1, rf_raddr2;
    wire [7:0] rf_rdata1, rf_rdata2;
    regfile rf(.clk(clk), .wen(rf_wen), .waddr(rf_waddr), .wdata(rf_wdata), .raddr1(rf_raddr1), .raddr2(rf_raddr2), .rdata1(rf_rdata1), .rdata2(rf_rdata2));

    // data memory
    reg dm_wen;
    reg [7:0] dm_waddr;
    reg [7:0] dm_wdata;
    reg [7:0] dm_raddr;
    wire [7:0] dm_rdata;
    dmem dm(.clk(clk), .wen(dm_wen), .waddr(dm_waddr), .wdata(dm_wdata), .raddr(dm_raddr), .rdata(dm_rdata));

    // ALU
    reg [2:0] alu_op;
    reg [7:0] alu_a, alu_b;
    wire [7:0] alu_y;
    wire alu_zero;
    alu ualu(.op(alu_op), .a(alu_a), .b(alu_b), .y(alu_y), .zero(alu_zero));

    // microcontrol
    reg [2:0] state;
    localparam S_FETCH  = 3'd0;
    localparam S_DECODE = 3'd1;
    localparam S_EXEC   = 3'd2; // ALU ops
    localparam S_MEM    = 3'd3; // memory access (LD/ST)
    localparam S_WB     = 3'd4; // writeback to regfile
    localparam S_HALT   = 3'd5;

    // registers for the instruction camps
    reg [3:0] opcode_reg;
    reg [2:0] rd_reg, rs1_reg, rs2_reg;
    reg [7:0] imm_reg; // immediat (baixa part de la segona paraula)

    // Reset & FSM
    always @(posedge clk) begin
        // as default we clean the control signal
        rf_wen <= 1'b0;
        dm_wen <= 1'b0;

        if (rst) begin
            pc <= 8'b0;
            state <= S_FETCH;
            halted <= 1'b0;
            // clean control registers
            rf_waddr <= 3'b0;
            rf_wdata <= 8'b0;
            dm_waddr <= 8'b0;
            dm_wdata <= 8'b0;
            dm_raddr <= 8'b0;
            rf_raddr1 <= 3'b0;
            rf_raddr2 <= 3'b0;
        end else begin
            case (state)
                S_FETCH: begin
                    // Imem_cur contains the 16 bit word
                    // We move to DECODE and prepare imem + 1 in the case we have to read an inmediate
                    state <= S_DECODE;
                end

                S_DECODE: begin
                    // Capture instruction camps (combinationals saved in regs)
                    opcode_reg <= imem_cur[15:12];
                    rd_reg <= imem_cur[11:9];
                    rs1_reg <= imem_cur[8:6];
                    rs2_reg <= imem_cur[5:3];
                    // next word (inmediat) is imem_nextw[7:0]
                    imm_reg <= imem_nextw[7:0];

                    // Configure read ports of regfile for posible usage
                    rf_raddr1 <= imem_cur[8:6];
                    rf_raddr2 <= imem_cur[5:3];

                    // Decide next state depending on the opcode
                    case (imem_cur[15:12])
                        4'h0: begin // NOP
                            pc <= pc + 8'd1;
                            state <= S_FETCH;
                        end
                        4'h1, 4'h2, 4'h3, 4'h4: begin // R-type: ADD,SUB,AND,OR
                            // prepare ALU and go to EXEC
                            alu_a <= rf_rdata1;
                            alu_b <= rf_rdata2;
                            case (imem_cur[15:12])
                                4'h1: alu_op <= 3'b000; // ADD
                                4'h2: alu_op <= 3'b001; // SUB
                                4'h3: alu_op <= 3'b010; // AND
                                4'h4: alu_op <= 3'b011; // OR
                                default: alu_op <= 3'b000;
                            endcase
                            state <= S_EXEC;
                        end
                        4'h5: begin // LDI rd, imm8 (inmediat to next word)
                            // write inmediate at register directy in this step (síncron at clk)
                            rf_wen <= 1'b1;
                            rf_waddr <= imem_cur[11:9];
                            rf_wdata <= imem_nextw[7:0];
                            // We go up to two PC words (instrucció + immediat)
                            pc <= pc + 8'd2;
                            state <= S_FETCH;
                        end
                        4'h6: begin // LD rd, addr8
                            // cofigure the read from memory, we move to MEM state
                            dm_raddr <= imem_nextw[7:0];
                            // safe rd_reg (ja capturat en rd_reg)
                            pc <= pc + 8'd2; // jump instrucció + immediat
                            state <= S_MEM;
                        end
                        4'h7: begin // ST rs1, addr8
                            // write at memory the data of the register rs1 (rf_rdata1)
                            dm_wen <= 1'b1;
                            dm_waddr <= imem_nextw[7:0];
                            dm_wdata <= rf_rdata1;
                            pc <= pc + 8'd2;
                            state <= S_FETCH; // the write is made of the same clock flanc
                        end
                        4'h8: begin // JMP addr8
                            pc <= imem_nextw[7:0];
                            state <= S_FETCH;
                        end
                        4'hF: begin // HALT
                            halted <= 1'b1;
                            state <= S_HALT;
                        end
                        default: begin
                            // non-known instruction -> NOP behaviour
                            pc <= pc + 8'd1;
                            state <= S_FETCH;
                        end
                    endcase
                end

                S_EXEC: begin
                    // alu_y is the combinational result of the ALU
                    // we do writeback on the next flanc (síncron)
                    rf_wen <= 1'b1;
                    rf_waddr <= rd_reg;
                    rf_wdata <= alu_y;
                    pc <= pc + 8'd1;
                    state <= S_FETCH;
                end

                S_MEM: begin
                    // We are here for a memory read (LD). dmem provides rdata on the next edge.
                    // On this edge we activate the read request (we already set dm_raddr to DECODE)
                    // Now we go to WB to write the read value to the register
                    state <= S_WB;
                end

                S_WB: begin
                    // We write the read data of DMEM to destination register (rd_reg)
                    rf_wen <= 1'b1;
                    rf_waddr <= rd_reg;
                    rf_wdata <= dm_rdata;
                    state <= S_FETCH;
                end

                S_HALT: begin
                    // We stop here (infinite time, or until we stop the program)
                    state <= S_HALT;
                end

                default: begin
                    state <= S_FETCH;
                end
            endcase
        end
    end
endmodule
