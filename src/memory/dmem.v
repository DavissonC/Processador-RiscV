module dmem(
    input clk,
    input we,
    input [31:0] a,
    input [31:0] wd,
    output [31:0] rd
);

    reg [31:0] RAM [0:255];

    integer i;

    // Inicializa a memoria com zero
    initial begin
        for (i = 0; i < 256; i = i + 1)
            RAM[i] = 32'b0;
    end

    // Escrita sincronizada com o clock
    always @(posedge clk) begin
        if (we)
            RAM[a[9:2]] <= wd;
    end

    // Leitura combinacional
    assign rd = RAM[a[9:2]];

endmodule
