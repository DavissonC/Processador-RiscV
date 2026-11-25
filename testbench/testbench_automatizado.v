`timescale 1ns/1ps

module testbench_automatizado;

    reg clk = 0;
    reg reset = 0;

    wire [31:0] PC;
    wire [31:0] Instr;
    wire MemWrite;
    wire [31:0] ALUResult;
    wire [31:0] WriteData;
    wire [31:0] ReadData;
    wire Ecall;

    reg [31:0] ROM [0:255];

    integer i;
    integer passou;
    integer falhou;

    always #5 clk = ~clk;

    // Busca de instrucoes independente do arquivo programa.hex.
    assign Instr = ROM[PC[9:2]];

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

    dmem dm(
        .clk(clk),
        .we(MemWrite),
        .a(ALUResult),
        .wd(WriteData),
        .rd(ReadData)
    );

    task verificar_reg;
        input [4:0] numero;
        input [31:0] esperado;
        input [8*24-1:0] nome;
        begin
            if (numero == 0) begin
                if (32'b0 === esperado) begin
                    $display("[PASSOU] %0s", nome);
                    passou = passou + 1;
                end else begin
                    $display("[FALHOU] %0s: esperado=%h obtido=00000000",
                             nome, esperado);
                    falhou = falhou + 1;
                end
            end else if (cpu.dp.rf.rf[numero] === esperado) begin
                $display("[PASSOU] %0s", nome);
                passou = passou + 1;
            end else begin
                $display("[FALHOU] %0s: esperado=%h obtido=%h",
                         nome, esperado, cpu.dp.rf.rf[numero]);
                falhou = falhou + 1;
            end
        end
    endtask

    task verificar_mem;
        input [7:0] endereco_palavra;
        input [31:0] esperado;
        input [8*24-1:0] nome;
        begin
            if (dm.RAM[endereco_palavra] === esperado) begin
                $display("[PASSOU] %0s", nome);
                passou = passou + 1;
            end else begin
                $display("[FALHOU] %0s: esperado=%h obtido=%h",
                         nome, esperado, dm.RAM[endereco_palavra]);
                falhou = falhou + 1;
            end
        end
    endtask

    initial begin
        passou = 0;
        falhou = 0;

        // NOP em toda a ROM; o programa de teste e carregado abaixo.
        for (i = 0; i < 256; i = i + 1)
            ROM[i] = 32'h00000013;

        // x1=10; x2=20
        ROM[0]  = 32'h00a00093; // addi x1,x0,10
        ROM[1]  = 32'h01400113; // addi x2,x0,20

        // Operacoes R-type
        ROM[2]  = 32'h002081b3; // add x3,x1,x2 = 30
        ROM[3]  = 32'h40110233; // sub x4,x2,x1 = 10
        ROM[4]  = 32'h0020f2b3; // and x5,x1,x2 = 0
        ROM[5]  = 32'h0020e333; // or  x6,x1,x2 = 30
        ROM[6]  = 32'h0020a3b3; // slt x7,x1,x2 = 1

        // Imediato negativo, SW e LW
        ROM[7]  = 32'hfff00413; // addi x8,x0,-1
        ROM[8]  = 32'h00302023; // sw x3,0(x0)
        ROM[9]  = 32'h00002483; // lw x9,0(x0)

        // BEQ tomado: deve pular a escrita de 99 em x12.
        ROM[10] = 32'h00100513; // addi x10,x0,1
        ROM[11] = 32'h00100593; // addi x11,x0,1
        ROM[12] = 32'h00b50463; // beq x10,x11,+8
        ROM[13] = 32'h06300613; // addi x12,x0,99 (nao executa)
        ROM[14] = 32'h00700613; // addi x12,x0,7

        // BGE tomado: 10 >= -1; deve pular x14=99.
        ROM[15] = 32'h0080d463; // bge x1,x8,+8
        ROM[16] = 32'h06300713; // addi x14,x0,99 (nao executa)
        ROM[17] = 32'h00700713; // addi x14,x0,7

        // JAL: link em x15 e salto sobre x16=99.
        ROM[18] = 32'h008007ef; // jal x15,+8
        ROM[19] = 32'h06300813; // addi x16,x0,99 (nao executa)
        ROM[20] = 32'h00700813; // addi x16,x0,7

        // JALR: alvo 97 deve ser alinhado para 96; link em x20.
        ROM[21] = 32'h06100893; // addi x17,x0,97
        ROM[22] = 32'h00088a67; // jalr x20,0(x17)
        ROM[23] = 32'h06300a93; // addi x21,x0,99 (nao executa)
        ROM[24] = 32'h00700a93; // addi x21,x0,7

        // BGE nao tomado: -1 >= 10 e falso.
        ROM[25] = 32'h00145463; // bge x8,x1,+8
        ROM[26] = 32'h00b00d13; // addi x26,x0,11
        ROM[27] = 32'h01600d93; // addi x27,x0,22

        // x0 deve permanecer zero mesmo apos tentativa de escrita.
        ROM[28] = 32'h07b00013; // addi x0,x0,123
        ROM[29] = 32'h00000c13; // addi x24,x0,0
        ROM[30] = 32'h02a00c93; // addi x25,x0,42

        // Pulso de reset explicito para inicializar o PC.
        #1 reset = 1;
        #11 reset = 0;

        // Caminho dinamico: 27 instrucoes sao executadas.
        repeat (27) @(posedge clk);
        #1;

        $display("");
        $display("==============================================");
        $display("       BATERIA AUTOMATIZADA - RISC-V");
        $display("==============================================");

        verificar_reg(1,  32'd10,       "ADDI positivo");
        verificar_reg(2,  32'd20,       "ADDI imediato");
        verificar_reg(3,  32'd30,       "ADD");
        verificar_reg(4,  32'd10,       "SUB");
        verificar_reg(5,  32'd0,        "AND");
        verificar_reg(6,  32'd30,       "OR");
        verificar_reg(7,  32'd1,        "SLT signed");
        verificar_reg(8,  32'hFFFFFFFF, "ADDI negativo");
        verificar_reg(9,  32'd30,       "LW");
        verificar_mem(0,  32'd30,       "SW");
        verificar_reg(12, 32'd7,        "BEQ tomado");
        verificar_reg(14, 32'd7,        "BGE tomado");
        verificar_reg(15, 32'd76,       "JAL link PC+4");
        verificar_reg(16, 32'd7,        "JAL salto");
        verificar_reg(17, 32'd97,       "JALR endereco impar");
        verificar_reg(20, 32'd92,       "JALR link PC+4");
        verificar_reg(21, 32'd7,        "JALR salto/alinhamento");
        verificar_reg(26, 32'd11,       "BGE nao tomado");
        verificar_reg(27, 32'd22,       "Fluxo apos BGE");
        verificar_reg(0,  32'd0,        "x0 hardwired zero");
        verificar_reg(24, 32'd0,        "Leitura de x0");
        verificar_reg(25, 32'd42,       "Execucao final");

        if (PC === 32'd124) begin
            $display("[PASSOU] PC final");
            passou = passou + 1;
        end else begin
            $display("[FALHOU] PC final: esperado=0000007c obtido=%h", PC);
            falhou = falhou + 1;
        end

        $display("----------------------------------------------");
        $display("TOTAL: %0d testes | PASSOU: %0d | FALHOU: %0d",
                 passou + falhou, passou, falhou);

        if (falhou == 0)
            $display("RESULTADO: TODOS OS TESTES PASSARAM");
        else
            $display("RESULTADO: EXISTEM FALHAS");

        $display("==============================================");
        $finish;
    end

    // Protecao contra simulacao travada.
    initial begin
        #10000;
        $display("[ERRO] Timeout da bateria automatizada.");
        $finish;
    end

endmodule
