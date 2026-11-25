module testbench_system;

    reg clk;
    reg reset;

    wire [31:0] PC;

    wire Ecall;

    integer servico;
    integer entrada;
    integer lidos;

    integer endereco;
    integer indice;
    integer deslocamento;
    integer caractere;

    system dut(
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .Ecall(Ecall)
    );

    always #5 clk = ~clk;

    // Tratamento dos serviços ECALL
    always @(posedge clk) begin
        if (!reset && Ecall) begin

            servico = dut.cpu.dp.rf.rf[17];

            case (servico)
                // Serviço 4: imprimir string
                4: begin

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

                end

                // Serviço 5: ler inteiro
                5: begin
                    $write("Digite um inteiro: ");

                    lidos = $fscanf(32'h80000000, "%d", entrada);

                    if (lidos == 1) begin

                        @(negedge clk);

                        dut.cpu.dp.rf.rf[10] = entrada;

                        $display("Valor lido: %0d",
                                 dut.cpu.dp.rf.rf[10]);
                    end
                    else begin
                        $display("Erro: entrada invalida.");
                        $finish;
                    end
                end

                // Serviço 11: imprimir caractere
                11: begin
                    $write("%c",
                           dut.cpu.dp.rf.rf[10][7:0]);
                end

                // Serviço 10: encerrar programa
                10: begin
                    $display("\nPrograma encerrado.");
                    $finish;
                end

                default: begin
                    $display("Servico ECALL nao implementado: %0d",
                             servico);
                end

            endcase
        end
    end

    // Clock, reset e timeout
    initial begin
    clk = 0;
    reset = 1;

    #1;
    dut.cpu.dp.rf.rf[2] = 32'd1024;

    #11;
    reset = 0;

    #4000000;
    $display("Timeout: programa nao encerrou.");
    $finish;
end
endmodule