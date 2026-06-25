# Estructura de programas COBOL y copybooks

Universidad Nacional de La Matanza - DIIT  
Electiva I - Lenguaje Orientado a Negocios (COBOL)  
Documentación técnica para el TP Integrador Final

---

## 1. Introducción

Un programa COBOL se organiza en divisiones fijas y en un orden específico. Esta estructura es importante porque el compilador espera encontrar cada parte en una posición lógica determinada.

Las cuatro divisiones principales son:

```cobol
IDENTIFICATION DIVISION.
ENVIRONMENT DIVISION.
DATA DIVISION.
PROCEDURE DIVISION.
```

Resumen:

| División | Propósito |
|---|---|
| `IDENTIFICATION DIVISION` | Identifica el programa. |
| `ENVIRONMENT DIVISION` | Define entorno, archivos y dispositivos. |
| `DATA DIVISION` | Declara archivos, variables y estructuras. |
| `PROCEDURE DIVISION` | Contiene la lógica ejecutable. |

---

## 2. Formato fijo COBOL

En mainframe es común usar COBOL de **formato fijo**.

Distribución de columnas:

| Columnas | Área | Uso |
|---:|---|---|
| 1-6 | Secuencia | Numeración opcional. |
| 7 | Indicador | Comentario, continuación, debug, salto de página. |
| 8-11 | Area A | Divisiones, secciones, párrafos, niveles `01`, `FD`, `SD`. |
| 12-72 | Area B | Sentencias, cláusulas, niveles subordinados. |
| 73-80 | Identificación | Opcional. |

Indicadores comunes en columna 7:

| Indicador | Significado |
|---|---|
| `*` | Comentario. |
| `-` | Continuación de línea. |
| `D` | Línea de debugging. |
| `/` | Salto de página en listado. |

Ejemplo correcto:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CARGINI.
      *
       PROCEDURE DIVISION.
       MAIN-PROGRAM.
           DISPLAY 'INICIO'
           STOP RUN.
```

Error típico:

```text
The SELECT clause must begin in Area B
```

Causa: una sentencia como `SELECT`, `MOVE`, `PERFORM`, `DISPLAY`, etc. empezó en Area A cuando debía comenzar en Area B.

---

## 3. IDENTIFICATION DIVISION

Define la información identificatoria del programa.

Ejemplo:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CARGINI.
       AUTHOR. ESTUDIANTE KC03G24.
       DATE-WRITTEN. 15/03/2025.
       DATE-COMPILED.
```

Elemento requerido:

- `PROGRAM-ID`: nombre del programa. En z/OS conviene mantenerlo con máximo 8 caracteres.

Elementos recomendados:

- `AUTHOR`.
- `DATE-WRITTEN`.
- `DATE-COMPILED`.
- `SECURITY`, si aplica.

Programas del proyecto:

| Programa | Propósito |
|---|---|
| `CARGINI` | Carga inicial de libros. |
| `USUMANT` | Mantenimiento de usuarios. |
| `PRESTAM` | Procesamiento de préstamos/devoluciones. |
| `REPORTES` | Generación de reportes. |

---

## 4. ENVIRONMENT DIVISION

Define la configuración de ejecución y la relación entre nombres lógicos COBOL y DD names del JCL.

Estructura típica:

```cobol
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-3090.
       OBJECT-COMPUTER. IBM-3090.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARCHIVO-ENTRADA ASSIGN TO ENTRADA
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-STATUS-ENTRADA.
```

Relación importante:

```cobol
SELECT ARCHIVO-ENTRADA ASSIGN TO ENTRADA
```

se conecta con el JCL:

```jcl
//ENTRADA DD DSN=KC03G24.GRUPO6.DATA.INPUT2,DISP=SHR
```

## 4.1 Archivos secuenciales

```cobol
           SELECT ARCHIVO-ENTRADA ASSIGN TO ENTRADA
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-STATUS-ENTRADA.
```

Uso:

- Archivos de entrada batch.
- Reportes.
- Logs.

## 4.2 Archivos indexados / VSAM KSDS

```cobol
           SELECT ARCHIVO-MAESTRO ASSIGN TO MAESTRO
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS LIB-CODIGO
               FILE STATUS IS WS-STATUS-MAESTRO.
```

Uso:

- Archivos maestros.
- Acceso por clave.
- Lectura secuencial y directa.

## 4.3 Reportes

```cobol
           SELECT ARCHIVO-REPORTE ASSIGN TO REPORTE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-STATUS-REPORTE.
```

---

## 5. DATA DIVISION

Define todos los datos del programa.

Secciones principales:

```cobol
       DATA DIVISION.
       FILE SECTION.
       WORKING-STORAGE SECTION.
       LOCAL-STORAGE SECTION.
       LINKAGE SECTION.
```

| Sección | Uso |
|---|---|
| `FILE SECTION` | Layout de archivos externos definidos en `FILE-CONTROL`. |
| `WORKING-STORAGE SECTION` | Variables globales del programa. |
| `LOCAL-STORAGE SECTION` | Variables reinicializadas en cada invocación, útil en subprogramas. |
| `LINKAGE SECTION` | Parámetros recibidos desde otros programas. |

---

## 6. FILE SECTION

Define la estructura física/lógica de archivos.

Ejemplo de entrada secuencial:

```cobol
       FILE SECTION.
       FD  ARCHIVO-ENTRADA
           RECORD CONTAINS 229 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           DATA RECORD IS REG-ENTRADA.
       01  REG-ENTRADA                 PIC X(229).
```

La longitud debe coincidir con el dataset:

```text
RECFM=FB
LRECL=229
```

Ejemplo de reporte:

```cobol
       FD  ARCHIVO-REPORTE
           RECORDING MODE IS F
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           DATA RECORD IS REG-REPORTE.
       01  REG-REPORTE                 PIC X(133).
```

---

## 7. WORKING-STORAGE SECTION

Contiene variables, constantes, contadores, flags, estructuras internas y copybooks.

Ejemplo:

```cobol
       WORKING-STORAGE SECTION.
      *
      * CONSTANTES Y MENSAJES
      *
           COPY CONSTANT.
           COPY MENSAJES.
      *
      * CONTADORES
      *
       01  WS-CONTADORES.
           05 WS-CONT-LEIDOS          PIC 9(7) VALUE ZERO.
           05 WS-CONT-PROCESADOS      PIC 9(7) VALUE ZERO.
           05 WS-CONT-ERRORES         PIC 9(7) VALUE ZERO.
      *
      * CONTROL
      *
       01  WS-CONTROL.
           05 WS-FIN-ARCHIVO          PIC X VALUE 'N'.
              88 WS-FIN-ARCHIVO-SI    VALUE 'S'.
           05 WS-RESULTADO            PIC X VALUE 'N'.
              88 WS-RESULTADO-OK      VALUE 'S'.
```

## 7.1 Niveles de datos

| Nivel | Uso |
|---:|---|
| `01` | Estructura principal. |
| `05`, `10`, etc. | Campos subordinados. |
| `77` | Variable elemental independiente. |
| `88` | Nombre de condición. |

Ejemplo de nivel `88`:

```cobol
       05 WS-FIN-ARCHIVO              PIC X VALUE 'N'.
          88 WS-FIN-ARCHIVO-SI        VALUE 'S'.
```

Uso:

```cobol
           IF WS-FIN-ARCHIVO-SI
               DISPLAY 'FIN'
           END-IF
```

---

## 8. PROCEDURE DIVISION

Contiene la lógica ejecutable.

Estructura recomendada:

```cobol
       PROCEDURE DIVISION.
      *
       MAIN-PROGRAM.
           PERFORM INICIALIZAR
           PERFORM PROCESAR-ARCHIVO
           PERFORM FINALIZAR
           STOP RUN.
```

Patrón batch típico:

```cobol
       PROCESAR-ARCHIVO.
           PERFORM LEER-ENTRADA
           PERFORM UNTIL WS-FIN-ARCHIVO-SI
               PERFORM VALIDAR-REGISTRO
               IF WS-RESULTADO-OK
                   PERFORM PROCESAR-REGISTRO
               ELSE
                   PERFORM ESCRIBIR-ERROR
               END-IF
               PERFORM LEER-ENTRADA
           END-PERFORM.
```

---

## 9. Gestión de archivos en PROCEDURE DIVISION

## 9.1 Abrir archivos

```cobol
       ABRIR-ARCHIVOS.
           OPEN INPUT ARCHIVO-ENTRADA
           IF NOT WS-ENTRADA-OK
               DISPLAY 'ERROR AL ABRIR ENTRADA: '
                       WS-STATUS-ENTRADA
               STOP RUN
           END-IF

           OPEN OUTPUT ARCHIVO-REPORTE
           IF NOT WS-REPORTE-OK
               DISPLAY 'ERROR AL ABRIR REPORTE: '
                       WS-STATUS-REPORTE
               STOP RUN
           END-IF.
```

## 9.2 Leer archivo secuencial

```cobol
       LEER-ENTRADA.
           READ ARCHIVO-ENTRADA INTO WS-REGISTRO-ENTRADA
               AT END
                   MOVE 'S' TO WS-FIN-ARCHIVO
               NOT AT END
                   ADD 1 TO WS-CONT-LEIDOS
           END-READ.
```

## 9.3 Escribir reporte

```cobol
       EMITIR-LINEA.
           DISPLAY WS-LINEA-REPORTE
           WRITE REG-REPORTE FROM WS-LINEA-REPORTE.
```

## 9.4 Cerrar archivos

```cobol
       CERRAR-ARCHIVOS.
           CLOSE ARCHIVO-ENTRADA
           CLOSE ARCHIVO-REPORTE.
```

---

## 10. Copybooks

Los copybooks son archivos COBOL reutilizables incluidos con `COPY`.

Propósito:

- Evitar duplicación de estructuras.
- Mantener consistencia entre programas.
- Centralizar cambios.
- Documentar layouts comunes.

Ubicación esperada:

```text
KC03G24.GRUPO6.COBOL.COPYLIB
```

En el repo:

```text
COBOL.COPYLIB/
```

Uso:

```cobol
           COPY USUARIO.
```

En JCL, la copylib debe estar en `SYSLIB`:

```jcl
//COBOL.SYSLIB DD DSN=KC02814.GRUPO6.COBOL.COPYLIB,DISP=SHR
```

---

## 11. Copybooks del proyecto

## 11.1 LIBRO / LIBROS

Estructura de libro.

Campos principales:

```cobol
       01 REG-LIBRO.
          05 LIB-CODIGO              PIC X(10).
          05 LIB-TITULO              PIC X(60).
          05 LIB-AUTOR               PIC X(40).
          05 LIB-EDITORIAL           PIC X(30).
          05 LIB-ANIO-PUBLICACION    PIC 9(4).
          05 LIB-CATEGORIA           PIC X(20).
          05 LIB-STOCK-TOTAL         PIC 9(3).
          05 LIB-STOCK-DISPONIBLE    PIC 9(3).
          05 LIB-UBICACION           PIC X(10).
          05 LIB-FECHA-ALTA          PIC X(10).
          05 LIB-USUARIO-ALTA        PIC X(8).
          05 LIB-ESTADO              PIC X(1).
             88 LIB-ACTIVO           VALUE 'A'.
             88 LIB-INACTIVO         VALUE 'I'.
             88 LIB-BAJA             VALUE 'B'.
```

## 11.2 USUARIO

Estructura de usuario.

Campos principales:

```cobol
       01 REG-USUARIO.
          05 USU-CODIGO              PIC X(10).
          05 USU-NOMBRE              PIC X(30).
          05 USU-APELLIDO            PIC X(30).
          05 USU-TIPO-USUARIO        PIC X(1).
             88 USU-ESTUDIANTE       VALUE 'E'.
             88 USU-DOCENTE          VALUE 'D'.
             88 USU-ADMINISTRATIVO   VALUE 'A'.
          05 USU-EMAIL               PIC X(50).
          05 USU-TELEFONO            PIC X(20).
          05 USU-DIRECCION           PIC X(60).
          05 USU-FECHA-ALTA          PIC X(10).
          05 USU-FECHA-BAJA          PIC X(10).
          05 USU-ESTADO              PIC X(1).
             88 USU-ACTIVO           VALUE 'A'.
             88 USU-INACTIVO         VALUE 'I'.
```

Nota del proyecto: la tabla DB2 real de usuarios puede usar nombres SQL sin prefijo (`COD_USUARIO`, `NOMBRE`, `EMAIL`, etc.), aunque el copybook use prefijos COBOL (`USU-CODIGO`, `USU-NOMBRE`, `USU-EMAIL`).

## 11.3 PRESTAMO

Estructura de préstamo.

Campos principales:

```cobol
       01 REG-PRESTAMO.
          05 PRES-NUMERO             PIC 9(8).
          05 PRES-CODIGO-LIBRO       PIC X(10).
          05 PRES-CODIGO-USUARIO     PIC X(10).
          05 PRES-FECHA-PRESTAMO     PIC X(10).
          05 PRES-FECHA-DEVOLUCION   PIC X(10).
          05 PRES-FECHA-LIMITE       PIC X(10).
          05 PRES-ESTADO             PIC X(1).
             88 PRES-PENDIENTE       VALUE 'P'.
             88 PRES-DEVUELTO        VALUE 'D'.
             88 PRES-VENCIDO         VALUE 'V'.
          05 PRES-MULTA              PIC 9(5)V99.
          05 PRES-OBSERVACIONES      PIC X(100).
```

## 11.4 CONSTANT

Constantes generales y reglas de negocio.

Ejemplos:

```cobol
       01 CONSTANTES-SISTEMA.
          05 CONST-NOMBRE-SISTEMA    PIC X(30)
             VALUE 'SISTEMA BIBLIOTECA UNLAM'.
          05 CONST-VERSION           PIC X(5) VALUE 'V1.0'.

       01 CONSTANTES-NEGOCIO.
          05 CONST-DIAS-PRESTAMO-EST PIC 9(2) VALUE 15.
          05 CONST-DIAS-PRESTAMO-DOC PIC 9(2) VALUE 30.
          05 CONST-MAX-LIBROS-EST    PIC 9(2) VALUE 03.
          05 CONST-MAX-LIBROS-DOC    PIC 9(2) VALUE 10.
          05 CONST-MULTA-DIA         PIC 9(3)V99 VALUE 50.00.
```

## 11.5 MENSAJES

Mensajes centralizados.

Ejemplos:

```cobol
       01 MENSAJES-ERROR.
          05 MSG-ERR-001 PIC X(60)
             VALUE 'ERROR: CODIGO DE LIBRO INVALIDO O VACIO'.
          05 MSG-ERR-007 PIC X(60)
             VALUE 'ERROR: USUARIO NO ENCONTRADO'.

       01 MENSAJES-INFO.
          05 MSG-INFO-001 PIC X(60)
             VALUE 'LIBRO CARGADO EXITOSAMENTE'.
          05 MSG-INFO-002 PIC X(60)
             VALUE 'USUARIO REGISTRADO EXITOSAMENTE'.
```

## 11.6 LINREP

Layouts de líneas de reporte.

Ejemplos:

```cobol
       01 LINEA-SEPARADOR            PIC X(133) VALUE ALL '-'.

       01 LINEA-TOTAL-REGISTROS.
          05 FILLER                  PIC X(20)
             VALUE 'TOTAL DE REGISTROS: '.
          05 LIN-TOTAL-REGISTROS     PIC ZZZ,ZZZ,ZZ9.
          05 FILLER                  PIC X(102) VALUE SPACES.
```

---

## 12. COBOL con DB2 embebido

Los programas COBOL con DB2 usan SQL embebido:

```cobol
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.
```

Las host variables deben declararse dentro de:

```cobol
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

       01 HV-USUARIO.
          05 HV-USU-CODIGO           PIC X(10).
          05 HV-USU-NOMBRE           PIC X(30).

           EXEC SQL END DECLARE SECTION END-EXEC.
```

Ejemplo de `SELECT`:

```cobol
           EXEC SQL
               SELECT COUNT(*)
                 INTO :HV-CANT-USUARIO
                 FROM KC03G24.USUARIOS
                WHERE COD_USUARIO = :HV-USU-CODIGO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
```

Ejemplo de `INSERT`:

```cobol
           EXEC SQL
               INSERT INTO KC03G24.USUARIOS
                   (COD_USUARIO, NOMBRE, APELLIDO, TIPO_USUARIO,
                    EMAIL, TELEFONO, DIRECCION, FECHA_ALTA,
                    FECHA_BAJA, ESTADO)
               VALUES
                   (:HV-USU-CODIGO, :HV-USU-NOMBRE,
                    :HV-USU-APELLIDO, :HV-USU-TIPO-USUARIO,
                    :HV-USU-EMAIL, :HV-USU-TELEFONO,
                    :HV-USU-DIRECCION, :HV-USU-FECHA-ALTA,
                    :HV-USU-FECHA-BAJA, :HV-USU-ESTADO)
           END-EXEC.
```

Errores DB2 frecuentes:

| SQLCODE | Significado |
|---:|---|
| `0` | Operación exitosa. |
| `100` | No encontrado. |
| `-204` | Objeto no existe o schema incorrecto. |
| `-206` | Columna inexistente. |
| `-803` | Violación de índice único / duplicado. |

---

## 13. Programa batch base

Esqueleto recomendado:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROGRAMA.
      *
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARCHIVO-ENTRADA ASSIGN TO ENTRADA
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-STATUS-ENTRADA.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  ARCHIVO-ENTRADA
           RECORD CONTAINS 200 CHARACTERS.
       01  REG-ENTRADA               PIC X(200).
      *
       WORKING-STORAGE SECTION.
       01  WS-STATUS-ENTRADA         PIC X(2) VALUE '00'.
           88 WS-ENTRADA-OK          VALUE '00'.
           88 WS-ENTRADA-EOF         VALUE '10'.
       01  WS-FIN-ARCHIVO            PIC X VALUE 'N'.
           88 WS-FIN-ARCHIVO-SI      VALUE 'S'.
      *
       PROCEDURE DIVISION.
       MAIN-PROGRAM.
           OPEN INPUT ARCHIVO-ENTRADA
           PERFORM LEER-ENTRADA
           PERFORM UNTIL WS-FIN-ARCHIVO-SI
               DISPLAY REG-ENTRADA
               PERFORM LEER-ENTRADA
           END-PERFORM
           CLOSE ARCHIVO-ENTRADA
           STOP RUN.
      *
       LEER-ENTRADA.
           READ ARCHIVO-ENTRADA
               AT END
                   MOVE 'S' TO WS-FIN-ARCHIVO
           END-READ.
```

---

## 14. Buenas prácticas

## 14.1 Programas COBOL

- Mantener las cuatro divisiones en orden.
- Respetar Area A y Area B en formato fijo.
- Usar nombres descriptivos.
- Centralizar constantes y mensajes en copybooks.
- Validar datos antes de mover a campos numéricos.
- Usar `FILE STATUS` para todos los archivos.
- Cerrar todos los archivos abiertos.
- Separar el programa en párrafos claros: inicialización, proceso, finalización.
- Mantener una rutina única para lectura de archivos.
- Reportar totales al final.

## 14.2 Copybooks

- Usar nombres de máximo 8 caracteres para compatibilidad.
- Documentar propósito, autor, fecha y versión.
- Mantener prefijos consistentes (`LIB-`, `USU-`, `PRES-`, `WS-`, `HV-`).
- Usar `FILLER` para completar longitudes exactas cuando el layout lo requiere.
- Evaluar impacto antes de modificar un copybook usado por varios programas.

## 14.3 DB2

- Comparar siempre el SQL embebido contra el DDL real.
- No asumir que el nombre del campo COBOL coincide con la columna DB2.
- Recompilar y bindear después de cambiar SQL embebido.
- Guardar `SQLCODE` antes de ejecutar `COMMIT` o `ROLLBACK` si se va a reportar el error original.
- Usar indicadores para columnas DB2 nullable, especialmente fechas.

---

## 15. Checklist de desarrollo

## 15.1 Estructura del programa

- [ ] `IDENTIFICATION DIVISION` completa.
- [ ] `ENVIRONMENT DIVISION` con `FILE-CONTROL`.
- [ ] `DATA DIVISION` con `FILE SECTION` y `WORKING-STORAGE`.
- [ ] `PROCEDURE DIVISION` estructurada.
- [ ] Sentencias en Area B.
- [ ] Párrafos en Area A.
- [ ] Comentarios útiles por sección.

## 15.2 Archivos

- [ ] Cada `SELECT` tiene DD correspondiente en JCL.
- [ ] Cada archivo tiene `FILE STATUS`.
- [ ] `FD RECORD CONTAINS` coincide con `LRECL`.
- [ ] Se manejan apertura, lectura, EOF, escritura y cierre.

## 15.3 Copybooks

- [ ] Copybooks necesarios creados.
- [ ] `COPY` ubicado en la sección correcta.
- [ ] `SYSLIB` del JCL apunta a la copylib.
- [ ] Prefijos consistentes.
- [ ] Longitudes de layout verificadas.

## 15.4 Validación

- [ ] Programa compila sin errores.
- [ ] No hay errores de Area A / Area B.
- [ ] Datos obligatorios validados.
- [ ] Campos numéricos validados antes de mover.
- [ ] `SQLCODE` manejado en operaciones DB2.
- [ ] Reporte final muestra leídos, procesados y errores.

---

## 16. Errores comunes

| Error | Causa probable | Corrección |
|---|---|---|
| `SELECT clause must begin in Area B` | `SELECT` empieza en Area A | Indentar a columna 12 o más. |
| Copybook no encontrado | `SYSLIB` incorrecto | Revisar JCL de compilación. |
| `FILE STATUS 35` | Dataset no existe | Crear dataset o corregir DD. |
| `FILE STATUS 39` | Atributos físicos incompatibles | Revisar `LRECL`, `RECFM`, `FD`. |
| `S0C7` | Dato no numérico en campo numérico | Validar con `NUMERIC`. |
| `SQLCODE -204` | Tabla/schema inexistente | Revisar owner y nombre de tabla. |
| `SQLCODE -206` | Columna inexistente | Alinear SQL con DDL real. |
| `SQLCODE -803` | Duplicado en índice único | Manejar como error funcional. |
