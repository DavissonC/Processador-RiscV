# Processador RISC-V em Verilog

Projeto acadêmico para a disciplina de Arquitetura de Computadores, ministrada pelo professor Calebe Micael (DCOMP-UFS). Trata-se de um processador RISC-V de ciclo único, desenvolvido em Verilog. Implementa um subconjunto de instruções da arquitetura RV32I e possui módulos de controle, datapath, registradores e memórias.

Como demonstração, o processador executa o algoritmo recursivo **Torre de Hanói**, utilizando chamadas de função, pilha, desvios e operações de entrada e saída.

## Torre de Hanói

A Torre de Hanói é um problema matemático recursivo em que discos de tamanhos diferentes devem ser transferidos de uma haste de origem para uma haste de destino, utilizando uma haste auxiliar.

Regras:
- Mover apenas um disco por vez.
- Nunca colocar um disco maior sobre um menor.
- Utilizar a haste auxiliar para realizar a transferência.


O número mínimo de movimentos é:

**M(n) = 2^n - 1**

O programa solicita a quantidade de discos e imprime os movimentos necessários.

## Estrutura do projeto

- `src/`: módulos Verilog do processador.
- `program/`: programa da Torre de Hanói em código hexadecimal.
- `testbench/`: testes automatizados e de integração.
- `build/`: arquivos gerados durante a compilação.

## Requisitos

- Icarus Verilog (`iverilog` e `vvp`).
- PowerShell ou terminal compatível.

## Como executar

Na pasta raiz do projeto, compile:

```powershell
iverilog -g2012 -s testbench_system -o build/torre_hanoi src/top/*.v src/control/*.v src/datapath/*.v src/components/*.v src/memory/*.v testbench/testbench_system.v
```

Execute:

```powershell
vvp build/torre_hanoi
```

Digite a quantidade de discos quando solicitado.

## Testes automatizados

O arquivo `testbench_hanoi.v` verifica automaticamente a execução com 1, 2, 3, 5 e 10 discos, comparando a quantidade e a sequência completa dos movimentos.

Execute o seguinte bloco no PowerShell:

```powershell
$discos = 1, 2, 3, 5, 10

foreach ($n in $discos) {
    Write-Host ""
    Write-Host "Executando teste com $n disco(s)..."

    iverilog -g2012 -s testbench_hanoi "-Ptestbench_hanoi.N_DISCOS=$n" -o build/teste_hanoi src/top/*.v src/control/*.v src/datapath/*.v src/components/*.v src/memory/*.v testbench/testbench_hanoi.v

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO NA COMPILACAO!"
        break
    }

    vvp build/teste_hanoi

    if ($LASTEXITCODE -ne 0) {
        Write-Host "TESTE FALHOU!"
        break
    }
}
```

### Resultados

Todos os cinco testes foram aprovados:

| Discos | Movimentos | Resultado |
|---:|---:|---|
| 1 | 1 | PASSOU |
| 2 | 3 | PASSOU |
| 3 | 7 | PASSOU |
| 5 | 31 | PASSOU |
| 10 | 1023 | PASSOU |

O testbench compara a sequência completa de movimentos com a sequência esperada.
