module datapath(
    input clk, reset,
    input [1:0] ResultSrc,
    input PCSrc, ALUSrc,
    input RegWrite,
    input [1:0] ImmSrc,
    input [2:0] ALUControl,
    output Zero,
    output[31:0] PC,
    input [31:0] Instr,
    output [31:0] ALUResult, WriteData,
    input [31:0] ReadData,
    input Jalr
    );

    wire [31:0] PCNext, PCPlus4, PCTarget;
    wire [31:0] ImmExt;
    wire [31:0] A, B;
    wire [31:0] Result;
    wire [31:0] JALRTarget;
    wire [1:0] PCSel;

    // next PC
    flopr #(32) pcreg(
        clk,
        reset,
        PCNext,
        PC
        );

    adder pcadd4(PC, 32'd4, PCPlus4);

    adder pcaddbranch(PC, ImmExt, PCTarget);

    assign JALRTarget = {ALUResult[31:1], 1'b0};

    assign PCSel = Jalr ? 2'b10 : PCSrc ? 2'b01 : 2'b00;

    mux3 #(32) pcmux(
        PCPlus4,
        PCTarget,
        JALRTarget,
        PCSel,
        PCNext
    );

    // register file
    regfile rf(
        clk,
        RegWrite,
        Instr[19:15],
        Instr[24:20],
        Instr[11:7],
        Result,
        A,
        WriteData
        ); 
    
    extend ext(Instr[31:7], ImmSrc, ImmExt);

    // ALU
    mux2 #(32) Bmux(WriteData, ImmExt, ALUSrc, B);

    alu alu(A, B, ALUControl, ALUResult, Zero);

    mux3 #(32) resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);
endmodule