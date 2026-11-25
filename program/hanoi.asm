.text
.globl main

main:

    # Le um inteiro
    addi a7, x0, 5
    ecall
    addi t0, a0, 0

    # Chama hanoi(n, A, C, B)
    addi a0, t0, 0
    addi a1, x0, 65          # A: origem
    addi a2, x0, 67          # C: destino
    addi a3, x0, 66          # B: auxiliar

    jal ra, hanoi

    # Encerra o programa
    addi a7, x0, 10
    ecall


# hanoi(a0=n, a1=origem, a2=destino, a3=auxiliar)
hanoi:
    # Caso base: n <= 0
    bge x0, a0, hanoi_fim

    # Cria stack frame de 32 bytes
    addi sp, sp, -32
    sw ra, 28(sp)
    sw a0, 24(sp)      # n
    sw a1, 20(sp)      # origem
    sw a2, 16(sp)      # destino
    sw a3, 12(sp)      # auxiliar

    # Caso base: n == 1
    addi t0, x0, 1
    beq a0, t0, hanoi_mover

    # 1. hanoi(n-1, origem, auxiliar, destino)
    addi a0, a0, -1

    addi t0, a2, 0
    addi a2, a3, 0
    addi a3, t0, 0

    jal ra, hanoi

    # Recupera os parametros originais
    lw a0, 24(sp)
    lw a1, 20(sp)
    lw a2, 16(sp)
    lw a3, 12(sp)

    # 2. Move um disco da origem para o destino
    jal ra, imprimir_movimento

    # Recupera os parametros novamente
    lw a0, 24(sp)
    lw a1, 20(sp)
    lw a2, 16(sp)
    lw a3, 12(sp)

    # 3. hanoi(n-1, auxiliar, destino, origem)
    addi a0, a0, -1

    addi t0, a1, 0
    addi a1, a3, 0
    addi a3, t0, 0

    jal ra, hanoi

    # Retorna apos as chamadas recursivas
    jal x0, hanoi_restaurar


hanoi_mover:
    # Caso base: move o unico disco
    jal ra, imprimir_movimento


hanoi_restaurar:
    # Restaura o endereco de retorno
    lw ra, 28(sp)

    # Libera o stack frame
    addi sp, sp, 32

hanoi_fim:
    jalr x0, 0(ra)

# Imprime "de X para Y"
# a1 = origem, a2 = destino
imprimir_movimento:
    addi t0, a1, 0
    addi t1, a2, 0

    # Imprime "de "
    addi a7, x0, 11
    addi a0, x0, 100       # caractere 'd'
    ecall

    addi a0, x0, 101       # caractere 'e'
    ecall

    addi a0, x0, 32        # espaço
    ecall

    # Imprime origem
    addi a0, t0, 0
    ecall

    # Imprime " para "
    addi a0, x0, 32        # espaço
    ecall

    addi a0, x0, 112       # caractere 'p'
    ecall

    addi a0, x0, 97        # caractere 'a'
    ecall

    addi a0, x0, 114       # caractere 'r'
    ecall

    addi a0, x0, 97        # caractere 'a'
    ecall

    addi a0, x0, 32        # espaço
    ecall

    # Imprime destino
    addi a0, t1, 0
    ecall

    # Imprime quebra de linha
    addi a0, x0, 10
    ecall

    jalr x0, 0(ra)
