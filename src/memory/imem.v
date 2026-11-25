module imem(
    input  [31:0] a,
    output [31:0] rd
);

    reg [31:0] ROM [0:255];

    // Carrega as instrucoes do arquivo hexadecimal
    initial begin
        $readmemh("program/programa.hex", ROM);
    end

    // Cada instrucao ocupa 4 bytes
    assign rd = ROM[a[9:2]];

endmodule