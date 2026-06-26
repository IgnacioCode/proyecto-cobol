      ***************************************************************
      * PROGRAMA: REPORTES - REPORTES ESTADISTICOS DB2             *
      * FUNCION : GENERA REPORTES DE USO E INVENTARIO              *
      * ENTRADA : KC03G24.GRUPO6.DATA.INPUT4                      *
      * SALIDA  : CONSOLA Y KC03G24.GRUPO6.REPORTES.OUTPUT4       *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REPORTES.
       AUTHOR. ESTUDIANTE KC03G24.
       DATE-WRITTEN. 26/06/2026.
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
           RECORD CONTAINS 80 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           DATA RECORD IS REG-ENTRADA.
       01 REG-ENTRADA                 PIC X(80).
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
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.
      *
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
      *
       01 HV-PARAMETROS.
           05 HV-FECHA-DESDE          PIC X(10).
           05 HV-FECHA-HASTA          PIC X(10).
       01 HV-ESTADOS.
           05 HV-EST-PENDIENTE        PIC X(1).
           05 HV-EST-VENCIDO          PIC X(1).
       01 HV-TOP-LIBRO.
           05 HV-TOP-COD-LIBRO        PIC X(10).
           05 HV-TOP-TITULO           PIC X(60).
           05 HV-TOP-CANTIDAD         PIC S9(9) COMP.
       01 HV-VENCIDO.
           05 HV-VEN-NUM              PIC S9(9) COMP.
           05 HV-VEN-COD-USUARIO      PIC X(10).
           05 HV-VEN-NOMBRE           PIC X(30).
           05 HV-VEN-APELLIDO         PIC X(30).
           05 HV-VEN-TIPO             PIC X(1).
           05 HV-VEN-COD-LIBRO        PIC X(10).
           05 HV-VEN-FECHA-LIMITE     PIC X(10).
           05 HV-VEN-ESTADO           PIC X(1).
       01 HV-MENSUAL.
           05 HV-MES-ANIO             PIC S9(4) COMP.
           05 HV-MES-MES              PIC S9(4) COMP.
           05 HV-MES-PRESTAMOS        PIC S9(9) COMP.
           05 HV-MES-DEVOLUCIONES     PIC S9(9) COMP.
           05 HV-MES-MULTAS           PIC S9(9)V99 COMP-3.
       01 HV-INVENTARIO.
           05 HV-INV-CATEGORIA        PIC X(20).
           05 HV-INV-LIBROS           PIC S9(9) COMP.
           05 HV-INV-STOCK-TOTAL      PIC S9(9) COMP.
           05 HV-INV-STOCK-DISP       PIC S9(9) COMP.
      *
           EXEC SQL END DECLARE SECTION END-EXEC.
      *
           EXEC SQL
               DECLARE CUR-TOP-LIBROS CURSOR FOR
               SELECT L.COD_LIBRO,
                      L.TITULO,
                      COUNT(*)
                 FROM KC03G24.PRESTAMOS P,
                      KC03G24.LIBROS L
                WHERE P.COD_LIBRO = L.COD_LIBRO
                  AND P.FECHA_PRESTAMO BETWEEN
                      DATE(:HV-FECHA-DESDE)
                      AND DATE(:HV-FECHA-HASTA)
                GROUP BY L.COD_LIBRO,
                         L.TITULO
                ORDER BY COUNT(*) DESC,
                         L.COD_LIBRO
                FETCH FIRST 10 ROWS ONLY
           END-EXEC.
      *
           EXEC SQL
               DECLARE CUR-VENCIDOS CURSOR FOR
               SELECT P.NUM_PRESTAMO,
                      P.COD_USUARIO,
                      U.NOMBRE,
                      U.APELLIDO,
                      U.TIPO_USUARIO,
                      P.COD_LIBRO,
                      P.FECHA_LIMITE,
                      P.ESTADO
                 FROM KC03G24.PRESTAMOS P,
                      KC03G24.USUARIOS U
                WHERE P.COD_USUARIO = U.COD_USUARIO
                  AND (P.ESTADO = :HV-EST-VENCIDO
                   OR (P.ESTADO = :HV-EST-PENDIENTE
                  AND P.FECHA_LIMITE < DATE(:HV-FECHA-HASTA)))
                ORDER BY P.FECHA_LIMITE,
                         P.COD_USUARIO,
                         P.NUM_PRESTAMO
           END-EXEC.
      *
           EXEC SQL
               DECLARE CUR-MENSUAL CURSOR FOR
               SELECT YEAR(FECHA_PRESTAMO),
                      MONTH(FECHA_PRESTAMO),
                      COUNT(*),
                      SUM(CASE WHEN FECHA_DEVOL IS NOT NULL
                               THEN 1 ELSE 0 END),
                      COALESCE(SUM(MULTA), 0)
                 FROM KC03G24.PRESTAMOS
                WHERE FECHA_PRESTAMO BETWEEN
                      DATE(:HV-FECHA-DESDE)
                      AND DATE(:HV-FECHA-HASTA)
                GROUP BY YEAR(FECHA_PRESTAMO),
                         MONTH(FECHA_PRESTAMO)
                ORDER BY YEAR(FECHA_PRESTAMO),
                         MONTH(FECHA_PRESTAMO)
           END-EXEC.
      *
           EXEC SQL
               DECLARE CUR-INVENTARIO CURSOR FOR
               SELECT CATEGORIA,
                      COUNT(*),
                      COALESCE(SUM(STOCK_TOTAL), 0),
                      COALESCE(SUM(STOCK_DISPONIBLE), 0)
                 FROM KC03G24.LIBROS
                GROUP BY CATEGORIA
                ORDER BY CATEGORIA
           END-EXEC.
      *
       01 WS-REGISTRO-ENTRADA.
           05 WS-ENT-FECHA-DESDE      PIC X(10).
           05 FILLER                  PIC X(1).
           05 WS-ENT-FECHA-HASTA      PIC X(10).
           05 FILLER                  PIC X(59).
      *
       01 WS-FILE-STATUS.
           05 WS-STATUS-ENTRADA       PIC X(2) VALUE '00'.
              88 WS-ENTRADA-OK        VALUE '00'.
              88 WS-ENTRADA-EOF       VALUE '10'.
           05 WS-STATUS-REPORTE       PIC X(2) VALUE '00'.
              88 WS-REPORTE-OK        VALUE '00'.
      *
       01 WS-SQL-STATUS.
           05 WS-SQLCODE              PIC S9(9) COMP.
              88 SQL-OK               VALUE 0.
              88 SQL-NOT-FOUND        VALUE 100.
           05 WS-SQLCODE-DISPLAY      PIC -ZZZZZZZZ9.
           05 WS-SQLERRMC-DISPLAY     PIC X(40).
      *
       01 WS-CONTROL.
           05 WS-HAY-DATOS            PIC X(1) VALUE 'N'.
              88 HAY-DATOS            VALUE 'S'.
           05 WS-ABORTAR              PIC X(1) VALUE 'N'.
              88 WS-ABORTAR-SI        VALUE 'S'.
           05 WS-MOTIVO-ERROR         PIC X(90) VALUE SPACES.
      *
       01 WS-FECHA-ACTUAL.
           05 WS-FECHA-X              PIC X(8).
           05 WS-FECHA-NUM REDEFINES WS-FECHA-X PIC 9(8).
       01 WS-FECHA-FMT.
           05 WS-FMT-NUM              PIC 9(8).
           05 WS-FMT-X REDEFINES WS-FMT-NUM.
              10 WS-FMT-AAAA          PIC X(4).
              10 WS-FMT-MM            PIC X(2).
              10 WS-FMT-DD            PIC X(2).
       01 WS-FECHA-ISO.
           05 WS-ISO-AAAA             PIC X(4).
           05 FILLER                  PIC X(1) VALUE '-'.
           05 WS-ISO-MM               PIC X(2).
           05 FILLER                  PIC X(1) VALUE '-'.
           05 WS-ISO-DD               PIC X(2).
      *
       01 WS-LINEA-REPORTE            PIC X(133).
       01 WS-LINEA-TOP.
           05 WRK-TOP-COD             PIC X(10).
           05 FILLER                  PIC X(2) VALUE SPACES.
           05 WRK-TOP-TITULO          PIC X(45).
           05 FILLER                  PIC X(2) VALUE SPACES.
           05 WRK-TOP-CANT            PIC ZZZ,ZZ9.
           05 FILLER                  PIC X(68) VALUE SPACES.
       01 WS-LINEA-VENCIDO.
           05 WRK-VEN-NUM             PIC ZZZZZZZ9.
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-VEN-USUARIO         PIC X(10).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-VEN-NOMBRE          PIC X(22).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-VEN-TIPO            PIC X(1).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-VEN-LIBRO           PIC X(10).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-VEN-LIMITE          PIC X(10).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-VEN-ESTADO          PIC X(1).
           05 FILLER                  PIC X(65) VALUE SPACES.
       01 WS-LINEA-MENSUAL.
           05 WRK-MES-ANIO            PIC 9999.
           05 FILLER                  PIC X(1) VALUE '-'.
           05 WRK-MES-MES             PIC 99.
           05 FILLER                  PIC X(3) VALUE SPACES.
           05 WRK-MES-PRESTAMOS       PIC ZZZ,ZZ9.
           05 FILLER                  PIC X(5) VALUE SPACES.
           05 WRK-MES-DEVOLUCIONES    PIC ZZZ,ZZ9.
           05 FILLER                  PIC X(5) VALUE SPACES.
           05 WRK-MES-MULTAS          PIC ZZZ,ZZZ,ZZ9.99.
           05 FILLER                  PIC X(82) VALUE SPACES.
       01 WS-LINEA-INVENTARIO.
           05 WRK-INV-CATEGORIA       PIC X(20).
           05 FILLER                  PIC X(3) VALUE SPACES.
           05 WRK-INV-LIBROS          PIC ZZZ,ZZ9.
           05 FILLER                  PIC X(5) VALUE SPACES.
           05 WRK-INV-STOCK-TOTAL     PIC ZZZ,ZZ9.
           05 FILLER                  PIC X(5) VALUE SPACES.
           05 WRK-INV-STOCK-DISP      PIC ZZZ,ZZ9.
           05 FILLER                  PIC X(80) VALUE SPACES.
      *
       PROCEDURE DIVISION.
      *
       MAIN-PROGRAM.
           PERFORM INICIALIZAR
           IF NOT WS-ABORTAR-SI
               PERFORM GENERAR-REPORTES
           END-IF
           PERFORM FINALIZAR
           STOP RUN.
      *
       INICIALIZAR.
           DISPLAY 'INICIANDO PROGRAMA REPORTES'
           PERFORM INICIALIZAR-HOST-VARS
           PERFORM ABRIR-ARCHIVOS
           PERFORM LEER-PARAMETROS
           PERFORM ESCRIBIR-CABECERA-GENERAL.
      *
       INICIALIZAR-HOST-VARS.
           MOVE 'P' TO HV-EST-PENDIENTE
           MOVE 'V' TO HV-EST-VENCIDO.
      *
       GENERAR-REPORTES.
           PERFORM REPORTE-LIBROS-MAS-PRESTADOS
           PERFORM REPORTE-USUARIOS-VENCIDOS
           PERFORM REPORTE-ESTADISTICAS-MENSUALES
           PERFORM REPORTE-INVENTARIO-CATEGORIA.
      *
       FINALIZAR.
           PERFORM CERRAR-ARCHIVOS
           DISPLAY 'PROGRAMA REPORTES TERMINADO'.
      *
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
      *
       CERRAR-ARCHIVOS.
           CLOSE ARCHIVO-ENTRADA
           CLOSE ARCHIVO-REPORTE.
      *
       LEER-PARAMETROS.
           READ ARCHIVO-ENTRADA INTO WS-REGISTRO-ENTRADA
               AT END
                   MOVE SPACES TO WS-ENT-FECHA-DESDE
                   MOVE SPACES TO WS-ENT-FECHA-HASTA
           END-READ
           PERFORM RESOLVER-FECHAS.
      *
       RESOLVER-FECHAS.
           ACCEPT WS-FECHA-NUM FROM DATE YYYYMMDD
           MOVE WS-FECHA-NUM TO WS-FMT-NUM
           MOVE WS-FMT-AAAA  TO WS-ISO-AAAA
           MOVE WS-FMT-MM    TO WS-ISO-MM
           MOVE WS-FMT-DD    TO WS-ISO-DD
           IF WS-ENT-FECHA-HASTA = SPACES
               MOVE WS-FECHA-ISO TO HV-FECHA-HASTA
           ELSE
               MOVE WS-ENT-FECHA-HASTA TO HV-FECHA-HASTA
           END-IF
           IF WS-ENT-FECHA-DESDE = SPACES
               MOVE '01' TO WS-ISO-DD
               MOVE WS-FECHA-ISO TO HV-FECHA-DESDE
           ELSE
               MOVE WS-ENT-FECHA-DESDE TO HV-FECHA-DESDE
           END-IF
           PERFORM VALIDAR-FECHAS.
      *
       VALIDAR-FECHAS.
           MOVE SPACES TO WS-MOTIVO-ERROR
           IF HV-FECHA-DESDE(5:1) NOT = '-'
              OR HV-FECHA-DESDE(8:1) NOT = '-'
               MOVE 'FECHA DESDE INVALIDA, USAR YYYY-MM-DD'
                   TO WS-MOTIVO-ERROR
           END-IF
           IF WS-MOTIVO-ERROR = SPACES
              AND (HV-FECHA-HASTA(5:1) NOT = '-'
              OR HV-FECHA-HASTA(8:1) NOT = '-')
               MOVE 'FECHA HASTA INVALIDA, USAR YYYY-MM-DD'
                   TO WS-MOTIVO-ERROR
           END-IF
           IF WS-MOTIVO-ERROR = SPACES
               PERFORM VALIDAR-FECHA-DESDE-NUM
           END-IF
           IF WS-MOTIVO-ERROR = SPACES
               PERFORM VALIDAR-FECHA-HASTA-NUM
           END-IF
           IF WS-MOTIVO-ERROR NOT = SPACES
               MOVE 'S' TO WS-ABORTAR
           END-IF.
      *
       VALIDAR-FECHA-DESDE-NUM.
           STRING HV-FECHA-DESDE(1:4)
                  HV-FECHA-DESDE(6:2)
                  HV-FECHA-DESDE(9:2)
               DELIMITED BY SIZE
               INTO WS-FECHA-X
           END-STRING
           IF WS-FECHA-X NOT NUMERIC
               MOVE 'FECHA DESDE INVALIDA, USAR YYYY-MM-DD'
                   TO WS-MOTIVO-ERROR
           END-IF.
      *
       VALIDAR-FECHA-HASTA-NUM.
           STRING HV-FECHA-HASTA(1:4)
                  HV-FECHA-HASTA(6:2)
                  HV-FECHA-HASTA(9:2)
               DELIMITED BY SIZE
               INTO WS-FECHA-X
           END-STRING
           IF WS-FECHA-X NOT NUMERIC
               MOVE 'FECHA HASTA INVALIDA, USAR YYYY-MM-DD'
                   TO WS-MOTIVO-ERROR
           END-IF.
      *
       ESCRIBIR-CABECERA-GENERAL.
           MOVE ALL '=' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'SISTEMA DE BIBLIOTECA UNIVERSITARIA - REPORTES'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           INITIALIZE WS-LINEA-REPORTE
           STRING 'PERIODO: ' HV-FECHA-DESDE ' A ' HV-FECHA-HASTA
               DELIMITED BY SIZE
               INTO WS-LINEA-REPORTE
           END-STRING
           PERFORM EMITIR-LINEA
           IF WS-ABORTAR-SI
               MOVE WS-MOTIVO-ERROR TO WS-LINEA-REPORTE
               PERFORM EMITIR-LINEA
           END-IF
           MOVE ALL '=' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTE-LIBROS-MAS-PRESTADOS.
           PERFORM ESCRIBIR-SECCION-TOP
           MOVE 'N' TO WS-HAY-DATOS
           EXEC SQL OPEN CUR-TOP-LIBROS END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           IF NOT SQL-OK
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM FETCH-TOP-LIBRO
           PERFORM UNTIL SQL-NOT-FOUND
               IF SQL-OK
                   SET HAY-DATOS TO TRUE
                   PERFORM ESCRIBIR-TOP-LIBRO
                   PERFORM FETCH-TOP-LIBRO
               ELSE
                   PERFORM REPORTAR-ERROR-SQL
                   EXIT PERFORM
               END-IF
           END-PERFORM
           EXEC SQL CLOSE CUR-TOP-LIBROS END-EXEC
           IF NOT HAY-DATOS
               PERFORM ESCRIBIR-SIN-DATOS
           END-IF.
      *
       FETCH-TOP-LIBRO.
           EXEC SQL
               FETCH CUR-TOP-LIBROS
                INTO :HV-TOP-COD-LIBRO,
                     :HV-TOP-TITULO,
                     :HV-TOP-CANTIDAD
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       ESCRIBIR-SECCION-TOP.
           PERFORM ESCRIBIR-LINEA-BLANCO
           MOVE 'LIBROS MAS PRESTADOS'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'CODIGO      TITULO                             CANT'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       ESCRIBIR-TOP-LIBRO.
           INITIALIZE WS-LINEA-TOP
           MOVE HV-TOP-COD-LIBRO TO WRK-TOP-COD
           MOVE HV-TOP-TITULO    TO WRK-TOP-TITULO
           MOVE HV-TOP-CANTIDAD  TO WRK-TOP-CANT
           MOVE WS-LINEA-TOP     TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTE-USUARIOS-VENCIDOS.
           PERFORM ESCRIBIR-SECCION-VENCIDOS
           MOVE 'N' TO WS-HAY-DATOS
           EXEC SQL OPEN CUR-VENCIDOS END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           IF NOT SQL-OK
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM FETCH-VENCIDO
           PERFORM UNTIL SQL-NOT-FOUND
               IF SQL-OK
                   SET HAY-DATOS TO TRUE
                   PERFORM ESCRIBIR-VENCIDO
                   PERFORM FETCH-VENCIDO
               ELSE
                   PERFORM REPORTAR-ERROR-SQL
                   EXIT PERFORM
               END-IF
           END-PERFORM
           EXEC SQL CLOSE CUR-VENCIDOS END-EXEC
           IF NOT HAY-DATOS
               PERFORM ESCRIBIR-SIN-DATOS
           END-IF.
      *
       FETCH-VENCIDO.
           EXEC SQL
               FETCH CUR-VENCIDOS
                INTO :HV-VEN-NUM,
                     :HV-VEN-COD-USUARIO,
                     :HV-VEN-NOMBRE,
                     :HV-VEN-APELLIDO,
                     :HV-VEN-TIPO,
                     :HV-VEN-COD-LIBRO,
                     :HV-VEN-FECHA-LIMITE,
                     :HV-VEN-ESTADO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       ESCRIBIR-SECCION-VENCIDOS.
           PERFORM ESCRIBIR-LINEA-BLANCO
           MOVE 'USUARIOS CON PRESTAMOS VENCIDOS'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'NRO      USUARIO    NOMBRE        T LIBRO      LIMITE'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       ESCRIBIR-VENCIDO.
           INITIALIZE WS-LINEA-VENCIDO
           MOVE HV-VEN-NUM         TO WRK-VEN-NUM
           MOVE HV-VEN-COD-USUARIO TO WRK-VEN-USUARIO
           STRING HV-VEN-NOMBRE DELIMITED BY SPACE
                  ' ' DELIMITED BY SIZE
                  HV-VEN-APELLIDO DELIMITED BY SPACE
               INTO WRK-VEN-NOMBRE
           END-STRING
           MOVE HV-VEN-TIPO        TO WRK-VEN-TIPO
           MOVE HV-VEN-COD-LIBRO   TO WRK-VEN-LIBRO
           MOVE HV-VEN-FECHA-LIMITE TO WRK-VEN-LIMITE
           MOVE HV-VEN-ESTADO      TO WRK-VEN-ESTADO
           MOVE WS-LINEA-VENCIDO   TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTE-ESTADISTICAS-MENSUALES.
           PERFORM ESCRIBIR-SECCION-MENSUAL
           MOVE 'N' TO WS-HAY-DATOS
           EXEC SQL OPEN CUR-MENSUAL END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           IF NOT SQL-OK
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM FETCH-MENSUAL
           PERFORM UNTIL SQL-NOT-FOUND
               IF SQL-OK
                   SET HAY-DATOS TO TRUE
                   PERFORM ESCRIBIR-MENSUAL
                   PERFORM FETCH-MENSUAL
               ELSE
                   PERFORM REPORTAR-ERROR-SQL
                   EXIT PERFORM
               END-IF
           END-PERFORM
           EXEC SQL CLOSE CUR-MENSUAL END-EXEC
           IF NOT HAY-DATOS
               PERFORM ESCRIBIR-SIN-DATOS
           END-IF.
      *
       FETCH-MENSUAL.
           EXEC SQL
               FETCH CUR-MENSUAL
                INTO :HV-MES-ANIO,
                     :HV-MES-MES,
                     :HV-MES-PRESTAMOS,
                     :HV-MES-DEVOLUCIONES,
                     :HV-MES-MULTAS
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       ESCRIBIR-SECCION-MENSUAL.
           PERFORM ESCRIBIR-LINEA-BLANCO
           MOVE 'ESTADISTICAS MENSUALES'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'MES       PRESTAMOS    DEVOLUCIONES    MULTAS'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       ESCRIBIR-MENSUAL.
           INITIALIZE WS-LINEA-MENSUAL
           MOVE HV-MES-ANIO         TO WRK-MES-ANIO
           MOVE HV-MES-MES          TO WRK-MES-MES
           MOVE HV-MES-PRESTAMOS    TO WRK-MES-PRESTAMOS
           MOVE HV-MES-DEVOLUCIONES TO WRK-MES-DEVOLUCIONES
           MOVE HV-MES-MULTAS       TO WRK-MES-MULTAS
           MOVE WS-LINEA-MENSUAL    TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTE-INVENTARIO-CATEGORIA.
           PERFORM ESCRIBIR-SECCION-INVENTARIO
           MOVE 'N' TO WS-HAY-DATOS
           EXEC SQL OPEN CUR-INVENTARIO END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           IF NOT SQL-OK
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM FETCH-INVENTARIO
           PERFORM UNTIL SQL-NOT-FOUND
               IF SQL-OK
                   SET HAY-DATOS TO TRUE
                   PERFORM ESCRIBIR-INVENTARIO
                   PERFORM FETCH-INVENTARIO
               ELSE
                   PERFORM REPORTAR-ERROR-SQL
                   EXIT PERFORM
               END-IF
           END-PERFORM
           EXEC SQL CLOSE CUR-INVENTARIO END-EXEC
           IF NOT HAY-DATOS
               PERFORM ESCRIBIR-SIN-DATOS
           END-IF.
      *
       FETCH-INVENTARIO.
           EXEC SQL
               FETCH CUR-INVENTARIO
                INTO :HV-INV-CATEGORIA,
                     :HV-INV-LIBROS,
                     :HV-INV-STOCK-TOTAL,
                     :HV-INV-STOCK-DISP
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       ESCRIBIR-SECCION-INVENTARIO.
           PERFORM ESCRIBIR-LINEA-BLANCO
           MOVE 'INVENTARIO POR CATEGORIA'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'CATEGORIA              LIBROS     STOCK     DISPONIBLE'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       ESCRIBIR-INVENTARIO.
           INITIALIZE WS-LINEA-INVENTARIO
           MOVE HV-INV-CATEGORIA   TO WRK-INV-CATEGORIA
           MOVE HV-INV-LIBROS      TO WRK-INV-LIBROS
           MOVE HV-INV-STOCK-TOTAL TO WRK-INV-STOCK-TOTAL
           MOVE HV-INV-STOCK-DISP  TO WRK-INV-STOCK-DISP
           MOVE WS-LINEA-INVENTARIO TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       ESCRIBIR-SIN-DATOS.
           MOVE 'SIN DATOS PARA LA SECCION'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTAR-ERROR-SQL.
           MOVE WS-SQLCODE TO WS-SQLCODE-DISPLAY
           MOVE SQLERRMC   TO WS-SQLERRMC-DISPLAY
           INITIALIZE WS-LINEA-REPORTE
           STRING 'ERROR SQL - SQLCODE ' WS-SQLCODE-DISPLAY
                  ' ID ' WS-SQLERRMC-DISPLAY
               DELIMITED BY SIZE
               INTO WS-LINEA-REPORTE
           END-STRING
           PERFORM EMITIR-LINEA.
      *
       ESCRIBIR-LINEA-BLANCO.
           MOVE SPACES TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       EMITIR-LINEA.
           DISPLAY WS-LINEA-REPORTE
           WRITE REG-REPORTE FROM WS-LINEA-REPORTE.
