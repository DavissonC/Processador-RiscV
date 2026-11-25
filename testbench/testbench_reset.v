`timescale 1ns/1ps

module testbench_reset;

    reg clk = 0;
    reg reset = 0;

    reg [31:0] Instr;
    wire [31:0] PC;
    wire MemWrite;
    wire [31:0] ALUResult;
    wire [31:0] WriteData;
    wire [31:0] ReadData;
    wire Ecall;

    integer total = 0;
    integer passou = 0;
    integer falhou = 0;

    always #5 clk = ~clk;

    riscvsingle dut(
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

    dmem memoria(
        .clk(clk),
        .we(MemWrite),
        .a(ALUResult),
        .wd(WriteData),
        .rd(ReadData)
    );

    task verificar;
        input [8*48-1:0] nome;
        input condicao;
        begin
            total = total + 1;
            if (condicao === 1'b1) begin
                passou = passou + 1;
                $display("[PASSOU] %0s", nome);
            end else begin
                falhou = falhou + 1;
                $display("[FALHOU] %0s", nome);
            end
        end
    endtask

    task aguardar_clock;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $display("==============================================");
        $display("       TESTES AUTOMATIZADOS - RESET");
        $display("==============================================");

        // Estado inicial e primeiro ciclo: x1 = 55
        Instr = 32'h03700093; // addi x1, x0, 55
        reset = 1'b1;
        #2;
        verificar("PC vai para zero com reset", PC == 32'd0);
        aguardar_clock;
        verificar("PC permanece zero durante reset", PC == 32'd0);

        reset = 1'b0;
        aguardar_clock;
        verificar("PC avanca apos liberar reset", PC == 32'd4);
        verificar("ADDI grava x1 = 55", dut.dp.rf.rf[1] == 32'd55);

        // Grava 55 na RAM[0], para depois verificar bloqueio de escrita.
        Instr = 32'h00102023; // sw x1, 0(x0)
        aguardar_clock;
        verificar("SW grava valor inicial na memoria", memoria.RAM[0] == 32'd55);

        // Assertiva assincrona do reset entre bordas de clock.
        #2;
        reset = 1'b1;
        #1;
        verificar("Reset assincrono zera PC sem esperar clock", PC == 32'd0);

        // Tenta alterar x1 durante o reset.
        Instr = 32'h06300093; // addi x1, x0, 99
        #1;
        verificar("RegWrite bloqueado durante reset", dut.RegWrite == 1'b0);
        aguardar_clock;
        verificar("Registrador nao e alterado durante reset", dut.dp.rf.rf[1] == 32'd55);
        verificar("PC continua zerado durante reset", PC == 32'd0);

        // Tenta escrever na memoria durante o reset.
        Instr = 32'h00102223; // sw x1, 4(x0)
        #1;
        verificar("MemWrite bloqueado durante reset", MemWrite == 1'b0);
        aguardar_clock;
        verificar("Memoria nao recebe escrita durante reset", memoria.RAM[1] == 32'd0);
        verificar("Dado anterior da memoria e preservado", memoria.RAM[0] == 32'd55);

        // Libera reset e confirma que o processador volta a executar.
        reset = 1'b0;
        Instr = 32'h00700113; // addi x2, x0, 7
        aguardar_clock;
        verificar("PC volta a avancar apos reset", PC == 32'd4);
        verificar("Processador executa instrucao apos reset", dut.dp.rf.rf[2] == 32'd7);
        verificar("x1 preserva valor anterior ao reset", dut.dp.rf.rf[1] == 32'd55);
        verificar("RAM preserva valor anterior ao reset", memoria.RAM[0] == 32'd55);
        verificar("RAM nao foi alterada durante reset", memoria.RAM[1] == 32'd0);

        $display("----------------------------------------------");
        $display("TOTAL: %0d testes | PASSOU: %0d | FALHOU: %0d",
                 total, passou, falhou);
        if (falhou == 0)
            $display("RESULTADO: TODOS OS TESTES DE RESET PASSARAM");
        else
            $display("RESULTADO: EXISTEM FALHAS NOS TESTES DE RESET");
        $display("==============================================");
        $finish;
    end

    initial begin
        #1000;
        $display("[FALHOU] Timeout do testbench de reset");
        $finish;
    end

endmodule
