module riscvsingle(
    input clk,
    input reset,
    output [31:0] PC,
    input [31:0] Instr,
    output MemWrite,
    output [31:0] ALUResult,
    output [31:0] WriteData,
    input [31:0] ReadData,
    output Ecall
);

    wire ALUSrc;
    wire RegWriteCtrl;
    wire RegWrite;
    wire Jump;
    wire Zero;
    wire PCSrc;
    wire Jalr;

    wire MemWriteCtrl;

    wire [1:0] ResultSrc;
    wire [1:0] ImmSrc;
    wire [2:0] ALUControl;

    assign Ecall = (Instr == 32'h00000073);

    // Bloqueia escritas durante o reset
    assign RegWrite = RegWriteCtrl & ~reset;
    assign MemWrite = MemWriteCtrl & ~reset;

    controller c(
        Instr[6:0],
        Instr[14:12],
        Instr[30],
        Zero,
        ResultSrc,
        MemWriteCtrl,
        PCSrc,
        ALUSrc,
        RegWriteCtrl,
        Jump,
        ImmSrc,
        ALUControl,
        Jalr
    );

    datapath dp(
        clk,
        reset,
        ResultSrc,
        PCSrc,
        ALUSrc,
        RegWrite,
        ImmSrc,
        ALUControl,
        Zero,
        PC,
        Instr,
        ALUResult,
        WriteData,
        ReadData,
        Jalr
    );

endmodule