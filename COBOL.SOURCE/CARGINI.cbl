      ***************************************************************
      * PROGRAMA: CARGINI - CARGA INICIAL DE LIBROS EN DB2         *
      *                                                            *
      * CONSIDERACIONES PARA ADAPTAR A OTROS PROGRAMAS:            *
      * I)   REEMPLAZAR KC03XXX EN EL INSERT POR EL USUARIO OWNER  *
      *      DEL GRUPO (EL MISMO QUE CREO LAS TABLAS)              *
      * II)  EL ARCHIVO DE ENTRADA DEBE TENER LRECL=200 Y LOS      *
      *      CAMPOS SEPARADOS POR UN ESPACIO ENTRE CADA UNO        *
      * III) PARA CARGAR USUARIOS O PRESTAMOS CAMBIAR:             *
      *      - LAS HOST VARIABLES HV- POR LAS DE LA TABLA          *
      *      - EL WS-REGISTRO-ENTRADA POR LOS CAMPOS DE ESA TABLA  *
      *      - EL INSERT EN INSERTAR-EN-DB2                        *
      *      - EL MOVER-DATOS-HOST-VARIABLES                       *
      *      - LAS VALIDACIONES EN VALIDAR-REGISTRO                *
      * IV)  NO MODIFICAR LA ESTRUCTURA DE ARCHIVOS NI EL SQLCA    *
      * V)   EL COMMIT SE HACE REGISTRO POR REGISTRO               *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CARGINI.
       AUTHOR. ESTUDIANTE KC03G24.
       DATE-WRITTEN. 15/03/2025.
       DATE-COMPILED.
      *
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
           SELECT ARCHIVO-REPORTE ASSIGN TO REPORTE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-STATUS-REPORTE.
      *
       DATA DIVISION.
       FILE SECTION.
       FD ARCHIVO-ENTRADA
           RECORD CONTAINS 200 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           DATA RECORD IS REG-ENTRADA.
       01 REG-ENTRADA                 PIC X(200).
      *
       FD ARCHIVO-REPORTE
           RECORDING MODE IS F
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           DATA RECORD IS REG-REPORTE.
       01 REG-REPORTE                 PIC X(133).
      *
       WORKING-STORAGE SECTION.
      *
      * AREA DE COMUNICACION SQL
      *
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.
      *
      * HOST VARIABLES
      *
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
      *
       01 HV-LIBRO.
           05 HV-LIB-CODIGO           PIC X(10).
           05 HV-LIB-TITULO           PIC X(60).
           05 HV-LIB-AUTOR            PIC X(40).
           05 HV-LIB-EDITORIAL        PIC X(30).
           05 HV-LIB-ANIO             PIC S9(4) COMP.
           05 HV-LIB-CATEGORIA        PIC X(20).
           05 HV-LIB-STOCK-TOTAL      PIC S9(3) COMP-3.
           05 HV-LIB-STOCK-DISP       PIC S9(3) COMP-3.
           05 HV-LIB-UBICACION        PIC X(10).
           05 HV-LIB-ESTADO           PIC X(1).
      *
           EXEC SQL END DECLARE SECTION END-EXEC.
      *
      * CONSTANTES Y MENSAJES
      *
           COPY CONSTANT.
           COPY MENSAJES.
      *
      * CONTADORES
      *
       01 WS-CONTADORES.
           05 WS-CONT-LEIDOS          PIC 9(7) VALUE ZERO.
           05 WS-CONT-PROCESADOS      PIC 9(7) VALUE ZERO.
           05 WS-CONT-ERRORES         PIC 9(7) VALUE ZERO.
      *
      * VARIABLES DE CONTROL
      *
       01 WS-CONTROL.
           05 WS-FIN-ARCHIVO          PIC X(1) VALUE 'N'.
               88 WS-FIN-ARCHIVO-SI   VALUE 'S'.
           05 WS-RESULTADO            PIC X(1) VALUE 'N'.
               88 WS-RESULTADO-OK     VALUE 'S'.
      *
      * FILE STATUS
      *
       01 WS-FILE-STATUS.
           05 WS-STATUS-ENTRADA       PIC X(2) VALUE '00'.
               88 WS-ENTRADA-OK       VALUE '00'.
               88 WS-ENTRADA-EOF      VALUE '10'.
           05 WS-STATUS-REPORTE       PIC X(2) VALUE '00'.
               88 WS-REPORTE-OK       VALUE '00'.
      *
      * SQL STATUS
      *
       01 WS-SQL-STATUS.
           05 WS-SQLCODE              PIC S9(9) COMP.
               88 SQL-OK              VALUE 0.
               88 SQL-NOT-FOUND       VALUE 100.
               88 SQL-DUPLICATE       VALUE -803.
      *
      * REGISTRO DE ENTRADA
      *
       01 WS-REGISTRO-ENTRADA.
           05 WS-ENT-CODIGO           PIC X(10).
           05 FILLER                  PIC X(1).
           05 WS-ENT-TITULO           PIC X(60).
           05 FILLER                  PIC X(1).
           05 WS-ENT-AUTOR            PIC X(40).
           05 FILLER                  PIC X(1).
           05 WS-ENT-EDITORIAL        PIC X(30).
           05 FILLER                  PIC X(1).
           05 WS-ENT-ANIO             PIC X(4).
           05 FILLER                  PIC X(1).
           05 WS-ENT-CATEGORIA        PIC X(20).
           05 FILLER                  PIC X(1).
           05 WS-ENT-STOCK            PIC X(3).
           05 FILLER                  PIC X(1).
           05 WS-ENT-UBICACION        PIC X(10).
           05 FILLER                  PIC X(15).
      *
      * LINEAS DE REPORTE
      *
           COPY LINREP.
      *
       01 WS-FECHA-PROCESO            PIC X(10).
       01 WS-NUMERO-PAGINA            PIC 9(3) VALUE 1.
       01 WS-CONTADOR-LINEAS          PIC 9(2) VALUE 99.
      *
       PROCEDURE DIVISION.
      *
       MAIN-PROGRAM.
           PERFORM INICIALIZAR
           PERFORM PROCESAR-ARCHIVO
           PERFORM FINALIZAR
           STOP RUN.
      *
       INICIALIZAR.
           DISPLAY 'INICIANDO PROGRAMA CARGINI'
           PERFORM OBTENER-FECHA-PROCESO
           PERFORM ABRIR-ARCHIVOS
           PERFORM ESCRIBIR-CABECERA-REPORTE.
      *
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
      *
       FINALIZAR.
           PERFORM ESCRIBIR-TOTALES
           PERFORM CERRAR-ARCHIVOS
           DISPLAY 'REGISTROS LEIDOS:     ' WS-CONT-LEIDOS
           DISPLAY 'REGISTROS PROCESADOS: ' WS-CONT-PROCESADOS
           DISPLAY 'REGISTROS CON ERROR:  ' WS-CONT-ERRORES
           DISPLAY 'PROGRAMA TERMINADO NORMALMENTE'.
      *
      * RUTINAS DE ARCHIVO
      *
       ABRIR-ARCHIVOS.
           OPEN INPUT ARCHIVO-ENTRADA
           IF NOT WS-ENTRADA-OK
               DISPLAY 'ERROR AL ABRIR ARCHIVO ENTRADA: '
                       WS-STATUS-ENTRADA
               STOP RUN
           END-IF
           OPEN OUTPUT ARCHIVO-REPORTE
           IF NOT WS-REPORTE-OK
               DISPLAY 'ERROR AL ABRIR ARCHIVO REPORTE: '
                       WS-STATUS-REPORTE
               STOP RUN
           END-IF.
      *
       LEER-ENTRADA.
           READ ARCHIVO-ENTRADA INTO WS-REGISTRO-ENTRADA
               AT END MOVE 'S' TO WS-FIN-ARCHIVO
               NOT AT END ADD 1 TO WS-CONT-LEIDOS
           END-READ.
      *
       CERRAR-ARCHIVOS.
           CLOSE ARCHIVO-ENTRADA
           CLOSE ARCHIVO-REPORTE.
      *
      * RUTINAS DE PROCESO
      *
       VALIDAR-REGISTRO.
           MOVE 'S' TO WS-RESULTADO
           IF WS-ENT-CODIGO = SPACES
               MOVE 'N' TO WS-RESULTADO
           END-IF
           IF WS-ENT-TITULO = SPACES
               MOVE 'N' TO WS-RESULTADO
           END-IF
           IF WS-ENT-AUTOR = SPACES
               MOVE 'N' TO WS-RESULTADO
           END-IF
           IF WS-ENT-ANIO NOT NUMERIC
               MOVE 'N' TO WS-RESULTADO
           END-IF
           IF WS-ENT-STOCK NOT NUMERIC
               MOVE 'N' TO WS-RESULTADO
           END-IF.
      *
       PROCESAR-REGISTRO.
           PERFORM MOVER-DATOS-HOST-VARIABLES
           PERFORM INSERTAR-EN-DB2
           PERFORM ESCRIBIR-DETALLE-REPORTE
           ADD 1 TO WS-CONT-PROCESADOS.
      *
       MOVER-DATOS-HOST-VARIABLES.
           MOVE WS-ENT-CODIGO         TO HV-LIB-CODIGO
           MOVE WS-ENT-TITULO         TO HV-LIB-TITULO
           MOVE WS-ENT-AUTOR          TO HV-LIB-AUTOR
           MOVE WS-ENT-EDITORIAL      TO HV-LIB-EDITORIAL
           MOVE WS-ENT-ANIO           TO HV-LIB-ANIO
           MOVE WS-ENT-CATEGORIA      TO HV-LIB-CATEGORIA
           MOVE WS-ENT-STOCK          TO HV-LIB-STOCK-TOTAL
           MOVE WS-ENT-STOCK          TO HV-LIB-STOCK-DISP
           MOVE WS-ENT-UBICACION      TO HV-LIB-UBICACION
           MOVE 'A'                   TO HV-LIB-ESTADO.
      *
       INSERTAR-EN-DB2.
           EXEC SQL
               INSERT INTO KC03G24.LIBROS
                   (COD_LIBRO, TITULO, AUTOR, EDITORIAL,
                    ANIO_PUBLICACION, CATEGORIA,
                    STOCK_TOTAL, STOCK_DISPONIBLE,
                    UBICACION, ESTADO)
               VALUES
                   (:HV-LIB-CODIGO, :HV-LIB-TITULO,
                    :HV-LIB-AUTOR, :HV-LIB-EDITORIAL,
                    :HV-LIB-ANIO, :HV-LIB-CATEGORIA,
                    :HV-LIB-STOCK-TOTAL, :HV-LIB-STOCK-DISP,
                    :HV-LIB-UBICACION, :HV-LIB-ESTADO)
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE TRUE
               WHEN SQL-OK
                   PERFORM COMMIT-TRANSACCION
               WHEN SQL-DUPLICATE
                   DISPLAY 'LIBRO YA EXISTE: ' HV-LIB-CODIGO
                   ADD 1 TO WS-CONT-ERRORES
               WHEN OTHER
                   DISPLAY 'ERROR SQL: ' SQLCODE
                   PERFORM ROLLBACK-TRANSACCION
                   ADD 1 TO WS-CONT-ERRORES
           END-EVALUATE.
      *
       COMMIT-TRANSACCION.
           EXEC SQL COMMIT END-EXEC.
      *
       ROLLBACK-TRANSACCION.
           EXEC SQL ROLLBACK END-EXEC.
      *
       ESCRIBIR-ERROR.
           DISPLAY 'REGISTRO CON ERROR - LINEA: ' WS-CONT-LEIDOS
           DISPLAY 'CODIGO: ' WS-ENT-CODIGO
           ADD 1 TO WS-CONT-ERRORES.
      *
      * RUTINAS DE REPORTE
      *
       ESCRIBIR-CABECERA-REPORTE.
           IF WS-CONTADOR-LINEAS > 55
               PERFORM SALTO-PAGINA
           END-IF.
      *
       SALTO-PAGINA.
           WRITE REG-REPORTE FROM LINEA-CABECERA-1
               AFTER ADVANCING PAGE
           WRITE REG-REPORTE FROM LINEA-CABECERA-2
               AFTER ADVANCING 1 LINE
           MOVE WS-FECHA-PROCESO      TO LIN-FECHA
           MOVE 'REPORTE DE CARGA DE LIBROS'
                                      TO LIN-TITULO-REPORTE
           MOVE WS-NUMERO-PAGINA      TO LIN-NUMERO-PAGINA
           WRITE REG-REPORTE FROM LINEA-CABECERA-3
               AFTER ADVANCING 2 LINES
           WRITE REG-REPORTE FROM LINEA-SEPARADOR
               AFTER ADVANCING 1 LINE
           WRITE REG-REPORTE FROM LINEA-TITULO-LIBROS
               AFTER ADVANCING 2 LINES
           WRITE REG-REPORTE FROM LINEA-SEPARADOR
               AFTER ADVANCING 1 LINE
           MOVE 1                     TO WS-CONTADOR-LINEAS
           ADD 1                      TO WS-NUMERO-PAGINA.
      *
       ESCRIBIR-DETALLE-REPORTE.
           IF WS-CONTADOR-LINEAS > 55
               PERFORM SALTO-PAGINA
           END-IF
           MOVE HV-LIB-CODIGO         TO LIN-LIB-CODIGO
           MOVE HV-LIB-TITULO         TO LIN-LIB-TITULO
           MOVE HV-LIB-AUTOR          TO LIN-LIB-AUTOR
           MOVE HV-LIB-EDITORIAL      TO LIN-LIB-EDITORIAL
           MOVE HV-LIB-ANIO           TO LIN-LIB-ANIO
           MOVE HV-LIB-STOCK-TOTAL    TO LIN-LIB-STOCK
           MOVE HV-LIB-UBICACION      TO LIN-LIB-UBICACION
           WRITE REG-REPORTE FROM LINEA-DETALLE-LIBRO
               AFTER ADVANCING 1 LINE
           ADD 1                      TO WS-CONTADOR-LINEAS.
      *
       ESCRIBIR-TOTALES.
           MOVE WS-CONT-LEIDOS        TO LIN-TOTAL-REGISTROS
           WRITE REG-REPORTE FROM LINEA-TOTAL-REGISTROS
               AFTER ADVANCING 3 LINES
           MOVE WS-CONT-ERRORES       TO LIN-TOTAL-ERRORES
           WRITE REG-REPORTE FROM LINEA-TOTAL-ERRORES
               AFTER ADVANCING 1 LINE.
      *
       OBTENER-FECHA-PROCESO.
           ACCEPT WS-FECHA-PROCESO FROM DATE YYYYMMDD
           INSPECT WS-FECHA-PROCESO
               REPLACING ALL '/' BY '-'.
