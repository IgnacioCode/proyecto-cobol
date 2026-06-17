       IDENTIFICATION DIVISION.
       PROGRAM-ID. CARGINI.
       AUTHOR. FACUNDO-CARBALLO.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ENTRADA ASSIGN TO ENTRADA
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS FS-ENTRADA.

           SELECT REPORTE ASSIGN TO REPORTE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS FS-REPORTE.

       DATA DIVISION.
       FILE SECTION.
       FD  ENTRADA.
       01  REG-ENTRADA-CSV           PIC X(200).

       FD  REPORTE
           RECORDING MODE IS F
           RECORD CONTAINS 133 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  REG-REPORTE-SAL           PIC X(133).

       WORKING-STORAGE SECTION.
      *--- AREA DE COMUNICACION CON DB2 SQLCA ----------------------
           EXEC SQL INCLUDE SQLCA END-EXEC.

      *--- VARIABLES HOST PARA DB2 ---------------------------------
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

       01  REG-LIBRO.
           05  LIB-ID                PIC X(10).
           05  LIB-TITULO            PIC X(50).
           05  LIB-AUTOR             PIC X(30).
           05  LIB-EDITORIAL         PIC X(30).
           05  LIB-CATEGORIA         PIC X(20).
           05  LIB-STOCK-TOTAL       PIC S9(4) COMP.
           05  LIB-STOCK-DISP        PIC S9(4) COMP.
           05  LIB-UBICACION         PIC X(15).

           EXEC SQL END DECLARE SECTION END-EXEC.

      *--- VARIABLES DE CONTROL -----------------------------------
       01  FS-ENTRADA                PIC XX.
       01  FS-REPORTE                PIC XX.
       01  W-FIN-ARCHIVO             PIC X VALUE 'N'.
           88  FIN-SI                VALUE 'S'.

      *--- VARIABLES PARA EL UNSTRING CSV --------------------------
       01  W-CAMPOS-CSV.
           05  W-CSV-ID              PIC X(10).
           05  W-CSV-TITULO          PIC X(50).
           05  W-CSV-AUTOR           PIC X(30).
           05  W-CSV-EDITORIAL       PIC X(30).
           05  W-CSV-CATEGORIA       PIC X(20).
           05  W-CSV-STOCK-T         PIC 9(04).
           05  W-CSV-STOCK-D         PIC 9(04).
           05  W-CSV-UBIC            PIC X(15).

       PROCEDURE DIVISION.
       1000-PRINCIPAL.
           PERFORM 2000-ABRIR-ARCHIVOS.
           PERFORM 3000-PROCESAR-CARGA
               UNTIL FIN-SI.
           PERFORM 4000-CERRAR-ARCHIVOS.
           GOBACK.

       2000-ABRIR-ARCHIVOS.
           OPEN INPUT  ENTRADA.
           OPEN OUTPUT REPORTE.

           IF FS-ENTRADA NOT = '00'
               DISPLAY 'ERROR AL ABRIR ARCHIVO ENTRADA'
               DISPLAY '  DDNAME.............: ENTRADA'
               DISPLAY '  FILE STATUS........: ' FS-ENTRADA
               DISPLAY '  DATASET ESPERADO...: '
                   'KC02814.GRUPO6.DATA.INPUT'
               DISPLAY '  ATRIBUTOS ESPERADOS: PS FB LRECL=200'
               STOP RUN
           END-IF.

           IF FS-REPORTE NOT = '00'
               DISPLAY 'ERROR AL ABRIR ARCHIVO REPORTE'
               DISPLAY '  DDNAME.............: REPORTE'
               DISPLAY '  FILE STATUS........: ' FS-REPORTE
               DISPLAY '  DATASET ESPERADO...: '
                   'KC02814.GRUPO6.REPORTES.OUTPUT'
               DISPLAY '  ATRIBUTOS ESPERADOS: PS FBA LRECL=133'
               DISPLAY '  FD COBOL...........: RECORDING F, LRECL=133'
               STOP RUN
           END-IF.

      *    SALTAR ENCABEZADO SI EXISTE.
           READ ENTRADA NEXT RECORD
               AT END
                   SET FIN-SI TO TRUE
           END-READ.

           IF NOT FIN-SI
               PERFORM 2100-LEER-ENTRADA
           END-IF.

       2100-LEER-ENTRADA.
           READ ENTRADA
               AT END
                   SET FIN-SI TO TRUE
           END-READ.

       3000-PROCESAR-CARGA.
      *--- DESCOMPONER EL CSV USANDO COMA COMO DELIMITADOR ---------
           INITIALIZE W-CAMPOS-CSV.

           UNSTRING REG-ENTRADA-CSV DELIMITED BY ','
               INTO W-CSV-ID
                    W-CSV-TITULO
                    W-CSV-AUTOR
                    W-CSV-EDITORIAL
                    W-CSV-CATEGORIA
                    W-CSV-STOCK-T
                    W-CSV-STOCK-D
                    W-CSV-UBIC
           END-UNSTRING.

      *--- MOVER A LA ESTRUCTURA DEL COPYBOOK Y DB2 ----------------
           MOVE W-CSV-ID             TO LIB-ID.
           MOVE W-CSV-TITULO         TO LIB-TITULO.
           MOVE W-CSV-AUTOR          TO LIB-AUTOR.
           MOVE W-CSV-EDITORIAL      TO LIB-EDITORIAL.
           MOVE W-CSV-CATEGORIA      TO LIB-CATEGORIA.
           MOVE W-CSV-STOCK-T        TO LIB-STOCK-TOTAL.
           MOVE W-CSV-STOCK-D        TO LIB-STOCK-DISP.
           MOVE W-CSV-UBIC           TO LIB-UBICACION.

      *--- INSERTAR EN DB2 -----------------------------------------
           EXEC SQL
               INSERT INTO LIBROS
                   (ID,
                    TITULO,
                    AUTOR,
                    EDITORIAL,
                    CATEGORIA,
                    STOCK_TOTAL,
                    STOCK_DISPONIBLE,
                    UBICACION)
               VALUES
                   (:LIB-ID,
                    :LIB-TITULO,
                    :LIB-AUTOR,
                    :LIB-EDITORIAL,
                    :LIB-CATEGORIA,
                    :LIB-STOCK-TOTAL,
                    :LIB-STOCK-DISP,
                    :LIB-UBICACION)
           END-EXEC.

           IF SQLCODE = 0
               STRING 'CARGA EXITOSA: '
                      LIB-ID
                   DELIMITED BY SIZE
                   INTO REG-REPORTE-SAL
               END-STRING
               WRITE REG-REPORTE-SAL
           ELSE
               STRING 'ERROR DB2 EN ID: '
                      LIB-ID
                   DELIMITED BY SIZE
                   INTO REG-REPORTE-SAL
               END-STRING
               WRITE REG-REPORTE-SAL
               DISPLAY 'SQLCODE ERROR: ' SQLCODE
           END-IF.

           PERFORM 2100-LEER-ENTRADA.

       4000-CERRAR-ARCHIVOS.
           CLOSE ENTRADA.
           CLOSE REPORTE.
