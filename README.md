# Práctica 4.2: Mini Cloud Log Analyzer - Variante C

## Autor
* **Nombre:** Torres Moreno Diego Antonio
* **Matrícula:** 23212077
* **Asignatura:** Lenguajes de Interfaz
* **Institución:** TECNM Campus ITT
* **Fecha:** 22 de abril de 2026

.

---

## 1. Variante Asignada y Solución Implementada
**Variante C: Detectar la primera aparición de 503.**

La solución requerida modifica el comportamiento de un analizador de logs HTTP tradicional. En lugar de contar y clasificar todos los códigos hasta el final del archivo, este analizador se maneja en modo de **monitoreo crítico (Early Exit)**. Lee el flujo de datos y, al detectar el primer evento `503 Service Unavailable`, detiene inmediatamente la ejecución y manda una alerta, ignorando cualquier registro posterior.

---

## 2. Diseño y Lógica Utilizada (A nivel Ensamblador)
El código fue escrito exclusivamente en ensamblador ARM64, evitando la biblioteca estándar de C (`libc`) y comunicándose directamente con el kernel de Linux a través de llamadas al sistema (*syscalls*).

### Máquina de Estados y Flujo de Control:
1. **Lectura en Bloques:** Se utiliza la syscall `read` (x8 = 63) para cargar hasta 4096 bytes de la entrada estándar (`stdin`) a un buffer en memoria, optimizando las operaciones de E/S.
 
2. **Parser de Enteros Cíclico:** El programa itera byte por byte. Si el carácter ASCII está entre '0' y '9', lo convierte a su valor decimal y lo acumula usando desplazamientos en base 10 (`numero_actual = numero_actual * 10 + digito`).

3. **Condición de Alerta (Branching):** Al detectar un salto de línea (`\n`), el analizador evalúa el número parseado:
   - Se ejecuta una comparación directa: `cmp x22, #503`.
   - Si coincide (`b.eq`), el flujo salta inmediatamente a la etiqueta `alerta_503`, la cual invoca la syscall `write` (x8 = 64) para imprimir la alerta crítica y luego ejecuta `exit` (x8 = 93), garantizando que se cumpla la condición de **"primera aparición"**.
    
4. **Manejo de Casos Borde:** Si la syscall `read` devuelve `0` (EOF - Fin de archivo) sin haber detectado un 503, el programa imprime un mensaje de estado `[OK]` y finaliza limpiamente.

---

## 3. Archivo Fuente Funcional y Arquitectura

* **Archivo fuente:** El código se encuentra en `src/analyzer.s`.
* **Adaptación a Entorno Termux (Android):** Durante el desarrollo, se me presentó el error de arquitectura `unexpected e_type: 2`. Llegue a la conclusión de que las políticas de seguridad del sistema necesitaban que los ejecutables sean independientes de la posición. Lo pude solucionar enlazando el binario con el flag `-pie` (`ld -pie -o analyzer analyzer.o`).
* 

**Proceso de compilación y enlazado en entorno ARM64:**

<img width="1055" height="145" alt="Captura de pantalla 2026-04-22 025422" src="https://github.com/user-attachments/assets/53a9876f-036f-4c4a-a7a7-4c5307744f05" />

---

## 4. Evidencia de Ejecución

Generación de archivos de prueba personalizados ('test_ok.txt' y 'test_error.txt') mediante el comando echo:**

<img width="918" height="39" alt="Captura de pantalla 2026-04-22 025910" src="https://github.com/user-attachments/assets/038dc454-736b-449d-95ae-1d11514b471c" />

<br>

**Prueba de Caso Negativo. Al procesar el archivo 'test_ok.txt', el analizador recorre la secuencia completa sin activar alertas, confirmando que no se detectaron eventos 503 y finalizando con un estado de éxito [OK]:**

<img width="718" height="86" alt="Captura de pantalla 2026-04-22 031652" src="https://github.com/user-attachments/assets/6b669f13-e5e3-4d65-b8f3-b5d5dfe9515a" />

<br>

A continuación, se presenta la validación manual utilizando los datos de prueba asignados (`data/logs_C.txt`):

**Comando ejecutado:**

``` cat data/logs_C.txt | ./analyzer ```

<img width="797" height="100" alt="Captura de pantalla 2026-04-22 033443" src="https://github.com/user-attachments/assets/4f746f12-c9a7-4c2a-a307-2828c5d373eb" />

---

## 5. Trazabilidad y Commits en GitHub Classroom

Realice el desarrollo de esta solución utilizando control de versiones. Todo el progreso, refactorización de la lógica base a la Variante C, y ajustes de compilación para ARM64 quedaron registrados por medio de commits con descripción enviados directamente desde la terminal de Termux hasta este repositorio.

<img width="703" height="583" alt="Captura de pantalla 2026-04-22 023202" src="https://github.com/user-attachments/assets/30abef62-0086-4334-a894-4eb2b7908763" />

<br>

<img width="746" height="259" alt="Captura de pantalla 2026-04-22 031441" src="https://github.com/user-attachments/assets/8030436b-8b61-4948-876d-ab81424b03d4" />
