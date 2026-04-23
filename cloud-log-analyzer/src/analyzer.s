# ───────────────────────────────────────────────
#  MINI CLOUD LOG ANALYZER · VARIANTE C
# ───────────────────────────────────────────────
#  Asignatura: Lenguajes de Interfaz
#  Autor(a): Torres Moreno Diego Antonio
#  Fecha: 2026/04/22
# ───────────────────────────────────────────────
#  Descripción: Lee códigos HTTP desde stdin (uno por línea).
#  Busca específicamente el primer código de error "503".
#  Al encontrarlo, imprime una alerta y termina la ejecución
#  inmediatamente, simulando un analizador en tiempo real.
# ───────────────────────────────────────────────

/*
PSEUDOCÓDIGO (Variante C)
1) Mientras haya bytes por leer en stdin:
   1.1) Leer un bloque con syscall read.
   1.2) Recorrer byte por byte.
   1.3) Si el byte es dígito, acumular numero_actual = numero_actual * 10 + dígito.
   1.4) Si el byte es '\n', evaluar numero_actual:
        a) Si numero_actual == 503:
           - Imprimir alerta de error crítico.
           - Salir con código 0.
        b) Si no, reiniciar acumulador y seguir.
2) Si termina de leer todo el archivo y no encuentra un 503:
   2.1) Imprimir mensaje indicando que no hubo errores críticos.
   2.2) Salir con código 0.
*/

.equ SYS_read,   63
.equ SYS_write,  64
.equ SYS_exit,   93
.equ STDIN_FD,    0
.equ STDOUT_FD,   1

.section .bss
    .align 4
buffer:         .skip 4096
num_buf:        .skip 32      // Buffer para imprimir (mantenido por si acaso)

.section .data
msg_titulo:         .asciz "=== Mini Cloud Log Analyzer (Variante C) ===\n"
msg_alerta_503:     .asciz "[!] ALERTA CRITICA: Se ha detectado un evento 503 (Service Unavailable).\n[!] Deteniendo el analisis...\n"
msg_todo_ok:        .asciz "[OK] Analisis finalizado. No se detectaron eventos 503.\n"

.section .text
.global _start

_start:
    // Imprimir el título al iniciar
    adrp x0, msg_titulo
    add x0, x0, :lo12:msg_titulo
    bl write_cstr

    // Estado del parser
    mov x22, #0                  // numero_actual
    mov x23, #0                  // tiene_digitos (0/1)

leer_bloque:
    // read(STDIN_FD, buffer, 4096)
    mov x0, #STDIN_FD
    adrp x1, buffer
    add x1, x1, :lo12:buffer
    mov x2, #4096
    mov x8, #SYS_read
    svc #0

    // x0 = bytes leídos
    cmp x0, #0
    beq fin_lectura               // EOF (Fin de archivo)
    blt salida_error              // Error de lectura

    mov x24, #0                   // índice i = 0
    mov x25, x0                   // total bytes en bloque

procesar_byte:
    cmp x24, x25
    b.ge leer_bloque              // Si procesamos todo el bloque, leer más

    adrp x1, buffer
    add x1, x1, :lo12:buffer
    ldrb w26, [x1, x24]
    add x24, x24, #1

    // Si es salto de línea, evaluar el número que acabamos de leer
    cmp w26, #10                  // '\n'
    b.eq evaluar_numero

    // Si es dígito ('0'..'9'), acumular
    cmp w26, #'0'
    b.lt procesar_byte
    cmp w26, #'9'
    b.gt procesar_byte

    // numero_actual = numero_actual * 10 + (byte - '0')
    mov x27, #10
    mul x22, x22, x27
    sub w26, w26, #'0'
    uxtw x26, w26
    add x22, x22, x26
    mov x23, #1
    b procesar_byte

evaluar_numero:
    // Solo evaluar si efectivamente hubo al menos un dígito
    cbz x23, reiniciar_numero

    // MODIFICACION VARIANTE C: ¿Es un 503?
    cmp x22, #503
    b.eq alerta_503               // Si es igual, saltar a la alerta y salir

reiniciar_numero:
    mov x22, #0
    mov x23, #0
    b procesar_byte

fin_lectura:
    // EOF con número pendiente (sin '\n' final)
    cbnz x23, evaluar_final
    b imprimir_todo_ok

evaluar_final:
    cmp x22, #503
    b.eq alerta_503

imprimir_todo_ok:
    // Si llegamos aquí, es porque leímos todo el archivo y no hubo ningún 503
    adrp x0, msg_todo_ok
    add x0, x0, :lo12:msg_todo_ok
    bl write_cstr
    b salida_ok

alerta_503:
    // Se encontró un 503, imprimir alerta y terminar (no sigue leyendo)
    adrp x0, msg_alerta_503
    add x0, x0, :lo12:msg_alerta_503
    bl write_cstr
    b salida_ok

salida_ok:
    mov x0, #0
    mov x8, #SYS_exit
    svc #0

salida_error:
    mov x0, #1
    mov x8, #SYS_exit
    svc #0

// -----------------------------------------------------------------------------
// write_cstr(x0 = puntero a string terminado en '\0')
// Imprime una cadena C usando syscall write.
// -----------------------------------------------------------------------------
write_cstr:
    mov x9, x0                    // guardar puntero inicial
    mov x10, #0                   // longitud = 0

wc_len_loop:
    ldrb w11, [x9, x10]
    cbz w11, wc_len_done
    add x10, x10, #1
    b wc_len_loop

wc_len_done:
    mov x1, x9                    // buffer
    mov x2, x10                   // tamaño
    mov x0, #STDOUT_FD            // fd
    mov x8, #SYS_write
    svc #0
    ret
