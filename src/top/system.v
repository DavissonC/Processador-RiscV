module system(
    input clk,
    input reset,
    output [31:0] PC,
    output Ecall
);

    wire [31:0] Instr;
    wire [31:0] ReadData;
    wire [31:0] ALUResult;
    wire [31:0] WriteData;
    wire MemWrite;

    // Memoria de instrucoes
    imem im(
        .a(PC),
        .rd(Instr)
    );

    // Processador
    riscvsingle cpu(
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .Instr(Instr),
        .MemWrite(MemWrite),
        .ALUResult(ALUResult),
        .WriteData(WriteData),
        .ReadData(ReadData),
        .Ecall(Ecall)
    );

    // Memoria de dados
    dmem dm(
        .clk(clk),
        .we(MemWrite),
        .a(ALUResult),
        .wd(WriteData),
        .rd(ReadData)
    );

endmodule