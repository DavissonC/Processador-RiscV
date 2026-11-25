`timescale 1ns/1ps

module testbench_ecall;

    reg clk = 0;
    reg reset = 1;

    wire [31:0] PC;
    wire Ecall;

    integer servico;
    integer entrada;
    integer lidos;
    integer endereco;
    integer indice;
    integer deslocamento;
    integer caractere;

    integer total = 0;
    integer passou = 0;
    integer falhou = 0;

    integer chamadas_4 = 0;
    integer chamadas_5 = 0;
    integer chamadas_10 = 0;
    integer chamadas_11 = 0;

    reg entrada_ok = 0;
    reg caractere_ok = 0;
    reg string_ok = 0;
    reg encerrou = 0;

    system dut(
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .Ecall(Ecall)
    );

    always #5 clk = ~clk;

    task verificar;
        input [8*52-1:0] nome;
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

    // Simula os serviços de ambiente associados a ECALL.
    // O serviço 10 sinaliza o encerramento para que o testbench
    // possa conferir os resultados antes de finalizar a simulacao.
    always @(posedge clk) begin
        if (!reset && Ecall) begin
            servico = dut.cpu.dp.rf.rf[17];

            case (servico)
                4: begin
                    chamadas_4 = chamadas_4 + 1;
                    endereco = dut.cpu.dp.rf.rf[10];
                    caractere = 1;

                    while ((caractere != 0) && (endereco < 1024)) begin
                        indice = endereco / 4;
                        deslocamento = endereco % 4;
                        caractere =
                            (dut.dm.RAM[indice] >> (8 * deslocamento)) & 8'hFF;

                        if (caractere != 0)
                            $write("%c", caractere);

                        endereco = endereco + 1;
                    end

                    string_ok = 1;
                end

                5: begin
                    chamadas_5 = chamadas_5 + 1;
                    $write("Digite um inteiro: ");
                    lidos = $fscanf(32'h80000000, "%d", entrada);

                    if (lidos == 1) begin
                        @(negedge clk);
                        dut.cpu.dp.rf.rf[10] = entrada;
                        $display("Valor lido: %0d",
                                 dut.cpu.dp.rf.rf[10]);
                        entrada_ok = 1;
                    end else begin
                        $display("\n[FALHOU] Nao foi possivel ler inteiro da entrada.");
                        $finish;
                    end
                end

                11: begin
                    chamadas_11 = chamadas_11 + 1;
                    $write("%c", dut.cpu.dp.rf.rf[10][7:0]);
                    if (dut.cpu.dp.rf.rf[10][7:0] == 8'h41)
                        caractere_ok = 1;
                end

                10: begin
                    chamadas_10 = chamadas_10 + 1;
                    $display("\nServico ECALL 10: encerramento solicitado.");
                    encerrou = 1;
                    reset = 1'b1;
                end

                default: begin
                    $display("\n[FALHOU] Servico ECALL nao implementado: %0d",
                             servico);
                    $finish;
                end
            endcase
        end
    end

    initial begin
        $display("==============================================");
        $display("       TESTES AUTOMATIZADOS - ECALL");
        $display("==============================================");

        // Espera a ROM ser carregada pelo $readmemh e substitui
        // seu inicio por um pequeno programa de teste.
        #1;
        dut.im.ROM[0] = 32'h00b00893; // addi a7, x0, 11
        dut.im.ROM[1] = 32'h04100513; // addi a0, x0, 65 ('A')
        dut.im.ROM[2] = 32'h00000073; // ecall: imprimir caractere

        dut.im.ROM[3] = 32'h00400893; // addi a7, x0, 4
        dut.im.ROM[4] = 32'h00000513; // addi a0, x0, 0 (RAM[0])
        dut.im.ROM[5] = 32'h00000073; // ecall: imprimir string

        dut.im.ROM[6] = 32'h00500893; // addi a7, x0, 5
        dut.im.ROM[7] = 32'h00000073; // ecall: ler inteiro

        dut.im.ROM[8] = 32'h00a00893; // addi a7, x0, 10
        dut.im.ROM[9] = 32'h00000073; // ecall: encerrar

        // String "ABC" seguida de NUL, em little-endian.
        dut.dm.RAM[0] = 32'h00434241;

        #10;
        reset = 1'b0;

        wait (encerrou == 1'b1);
        #1;

        verificar("ECALL 11 foi chamado uma vez", chamadas_11 == 1);
        verificar("ECALL 11 imprimiu o caractere A", caractere_ok);
        verificar("ECALL 4 foi chamado uma vez", chamadas_4 == 1);
        verificar("ECALL 4 percorreu a string ABC", string_ok);
        verificar("ECALL 5 foi chamado uma vez", chamadas_5 == 1);
        verificar("ECALL 5 recebeu um inteiro", entrada_ok);
        verificar("ECALL 5 retornou 123 em a0",
                  dut.cpu.dp.rf.rf[10] == 32'd123);
        verificar("ECALL 10 foi chamado uma vez", chamadas_10 == 1);
        verificar("Programa sinalizou encerramento", encerrou);

        $display("----------------------------------------------");
        $display("TOTAL: %0d testes | PASSOU: %0d | FALHOU: %0d",
                 total, passou, falhou);
        if (falhou == 0)
            $display("RESULTADO: TODOS OS TESTES ECALL PASSARAM");
        else
            $display("RESULTADO: EXISTEM FALHAS NOS TESTES ECALL");
        $display("==============================================");
        $finish;
    end

    initial begin
        #10000;
        $display("\n[FALHOU] Timeout: o programa nao chegou ao ECALL 10.");
        $finish;
    end

endmodule
