
module testbench_hanoi #(
    parameter N_DISCOS = 10
);

    reg clk;
    reg reset;

    wire [31:0] PC;
    wire Ecall;

    integer servico;
    integer caractere;
    integer movimentos_capturados;
    integer movimentos_esperados;
    integer posicao;
    integer i;

    reg [7:0] saida_capturada [0:20479];
    reg [7:0] saida_esperada [0:20479];

    reg [7:0] origem_esperada [0:1022];
    reg [7:0] destino_esperado [0:1022];

    integer tamanho_capturado;
    integer tamanho_esperado;

    integer falhas;

    system dut(
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .Ecall(Ecall)
    );

    always #5 clk = ~clk;

    // Gera a sequência esperada.
    task automatic gerar_esperado(
        input integer n,
        input [7:0] origem,
        input [7:0] destino,
        input [7:0] auxiliar
    );
    begin
        if (n > 0) begin

            gerar_esperado(n - 1, origem, auxiliar, destino);

            origem_esperada[movimentos_esperados] = origem;
            destino_esperado[movimentos_esperados] = destino;

            saida_esperada[tamanho_esperado] = "d";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = "e";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = " ";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = origem;
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = " ";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = "p";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = "a";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = "r";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = "a";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = " ";
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = destino;
            tamanho_esperado = tamanho_esperado + 1;

            saida_esperada[tamanho_esperado] = 10;
            tamanho_esperado = tamanho_esperado + 1;

            movimentos_esperados = movimentos_esperados + 1;

            gerar_esperado(n - 1, auxiliar, destino, origem);

        end
    end
    endtask

    // Captura os serviços ECALL.
    always @(posedge clk) begin

        if (!reset && Ecall) begin

            servico = dut.cpu.dp.rf.rf[17];

            case (servico)

                5: begin
                    @(negedge clk);
                    dut.cpu.dp.rf.rf[10] = N_DISCOS;
                end

                11: begin

                    caractere = dut.cpu.dp.rf.rf[10][7:0];

                    if (tamanho_capturado < 20480) begin
                        saida_capturada[tamanho_capturado] = caractere[7:0];
                        tamanho_capturado = tamanho_capturado + 1;
                    end else begin
                        $fatal(1, "Buffer de saida excedido.");
                    end

                    if (caractere == 10)
                        movimentos_capturados =
                            movimentos_capturados + 1;

                end

                10: begin

                    falhas = 0;

                    $display("");
                    $display("========================================");
                    $display(" TESTE TORRE DE HANOI");
                    $display("========================================");

                    $display("Discos: %0d", N_DISCOS);
                    $display("Movimentos esperados: %0d", movimentos_esperados);
                    $display("Movimentos capturados: %0d", movimentos_capturados);

                    $display(
                        "Ultimo movimento esperado: %c para %c",
                        origem_esperada[movimentos_esperados - 1],
                        destino_esperado[movimentos_esperados - 1]
                    );

                    if (movimentos_capturados != movimentos_esperados) begin
                        $display("FALHA: quantidade de movimentos incorreta.");
                        falhas = falhas + 1;
                    end

                    if (tamanho_capturado != tamanho_esperado) begin
                        $display("FALHA: quantidade de caracteres incorreta.");
                        falhas = falhas + 1;
                    end else begin

                        for (i = 0; i < tamanho_esperado; i = i + 1) begin
                            if (saida_capturada[i] != saida_esperada[i]) begin
                                if (falhas == 0)
                                    $display("FALHA: sequencia de movimentos incorreta na posicao %0d.", i);

                                falhas = falhas + 1;
                            end
                        end

                    end

                    if (falhas == 0) begin
                        $display("");
                        $display("RESULTADO: PASSOU");
                        $display("Sequencia completa correta!");
                        $display("========================================");
                        $finish;
                    end else begin
                        $display("");
                        $display("RESULTADO: FALHOU");
                        $display("Total de falhas: %0d", falhas);
                        $display("========================================");
                        $fatal(1, "Teste da Torre de Hanoi falhou.");
                    end

                end

                default: begin
                    $display("Servico ECALL inesperado: %0d", servico);
                end

            endcase

        end

    end

    // Inicialização.
    initial begin

        clk = 0;
        reset = 1;

        movimentos_esperados = 0;
        movimentos_capturados = 0;

        tamanho_capturado = 0;
        tamanho_esperado = 0;

        falhas = 0;

        if (N_DISCOS < 1 || N_DISCOS > 10)
            $fatal(1, "Quantidade de discos fora do intervalo.");

        gerar_esperado(
            N_DISCOS,
            8'h41,
            8'h43,
            8'h42
        );

        #1;
        dut.cpu.dp.rf.rf[2] = 32'd1024;

        #10;
        reset = 0;

        #10000000;

        $fatal(1, "TIMEOUT: programa nao encerrou.");

    end

endmodule
