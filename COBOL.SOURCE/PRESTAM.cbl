      ***************************************************************
      * PROGRAMA: PRESTAM - PRESTAMOS Y DEVOLUCIONES EN DB2       *
      * FUNCION : PROCESA TRANSACCIONES BATCH DE PRESTAMOS        *
      * ENTRADA : KC03G24.GRUPO6.DATA.INPUT3                     *
      * SALIDA  : CONSOLA Y KC03G24.GRUPO6.REPORTES.OUTPUT3      *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PRESTAM.
       AUTHOR. ESTUDIANTE KC03G24.
       DATE-WRITTEN. 24/06/2026.
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
           RECORD CONTAINS 140 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           DATA RECORD IS REG-ENTRADA.
       01 REG-ENTRADA                 PIC X(140).
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
       01 HV-PRESTAMO.
           05 HV-PRE-NUM              PIC S9(9) COMP.
           05 HV-COD-LIBRO            PIC X(10).
           05 HV-COD-USUARIO          PIC X(10).
           05 HV-FECHA-OPER           PIC X(10).
           05 HV-FECHA-LIMITE         PIC X(10).
           05 HV-ESTADO-PRE           PIC X(1).
           05 HV-MULTA                PIC S9(5)V99 COMP-3.
           05 HV-OBSERVACIONES        PIC X(100).
       01 HV-USUARIO.
           05 HV-USU-TIPO             PIC X(1).
       01 HV-LIBRO.
           05 HV-STOCK-DISP           PIC S9(9) COMP.
       01 HV-CONTROL.
           05 HV-CANT-ACTIVOS         PIC S9(9) COMP.
           05 HV-CANT-VENCIDOS        PIC S9(9) COMP.
       01 HV-ESTADOS.
           05 HV-EST-ACTIVO           PIC X(1).
           05 HV-EST-PENDIENTE        PIC X(1).
           05 HV-EST-DEVUELTO         PIC X(1).
           05 HV-EST-VENCIDO          PIC X(1).
      *
           EXEC SQL END DECLARE SECTION END-EXEC.
      *
           COPY CONSTANT.
      *
       01 WS-CONTADORES.
           05 WS-CONT-LEIDOS          PIC 9(7) VALUE ZERO.
           05 WS-CONT-PRESTAMOS       PIC 9(7) VALUE ZERO.
           05 WS-CONT-DEVOLUCIONES    PIC 9(7) VALUE ZERO.
           05 WS-CONT-ERRORES         PIC 9(7) VALUE ZERO.
      *
       01 WS-CONTROL.
           05 WS-FIN-ARCHIVO          PIC X(1) VALUE 'N'.
              88 WS-FIN-ARCHIVO-SI    VALUE 'S'.
           05 WS-RESULTADO            PIC X(1) VALUE 'N'.
              88 WS-RESULTADO-OK      VALUE 'S'.
           05 WS-MOTIVO-ERROR         PIC X(85) VALUE SPACES.
           05 WS-MAX-LIBROS           PIC 9(2) VALUE ZERO.
           05 WS-DIAS-PRESTAMO        PIC 9(2) VALUE ZERO.
           05 WS-DIAS-ATRASO          PIC S9(9) COMP VALUE ZERO.
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
              88 SQL-DUPLICATE        VALUE -803.
           05 WS-SQLCODE-DISPLAY      PIC -ZZZZZZZZ9.
           05 WS-SQLERRMC-DISPLAY     PIC X(40).
      *
      * LRECL 140: OP, NRO, USUARIO, LIBRO, FECHA, OBS, FILLER
      *
       01 WS-REGISTRO-ENTRADA.
           05 WS-ENT-OPERACION        PIC X(1).
           05 WS-ENT-NUM-PRESTAMO     PIC X(8).
           05 WS-ENT-COD-USUARIO      PIC X(10).
           05 WS-ENT-COD-LIBRO        PIC X(10).
           05 WS-ENT-FECHA-OPER       PIC X(10).
           05 WS-ENT-OBSERVACIONES    PIC X(100).
           05 FILLER                  PIC X(1).
      *
       01 WS-FECHA-TRABAJO.
           05 WS-FECHA-X              PIC X(8).
           05 WS-FECHA-NUM REDEFINES WS-FECHA-X PIC 9(8).
           05 WS-FECHA-INT            PIC S9(9) COMP.
           05 WS-LIMITE-NUM           PIC 9(8).
           05 WS-LIMITE-INT           PIC S9(9) COMP.
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
       01 WS-LINEA-DETALLE.
           05 WRK-DET-OPER            PIC X(1).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-DET-NUM             PIC ZZZZZZZ9.
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-DET-USUARIO         PIC X(10).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-DET-LIBRO           PIC X(10).
           05 FILLER                  PIC X(1) VALUE SPACE.
           05 WRK-DET-RESULTADO       PIC X(12).
           05 FILLER                  PIC X(3) VALUE ' - '.
           05 WRK-DET-MENSAJE         PIC X(85).
       01 WS-LINEA-TOTAL.
           05 WRK-TOTAL-TEXTO         PIC X(25).
           05 WRK-TOTAL-VALOR         PIC ZZZ,ZZ9.
           05 FILLER                  PIC X(101) VALUE SPACES.
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
           DISPLAY 'INICIANDO PROGRAMA PRESTAM'
           PERFORM INICIALIZAR-HOST-VARS
           PERFORM ABRIR-ARCHIVOS
           PERFORM ESCRIBIR-CABECERA.
      *
       INICIALIZAR-HOST-VARS.
           MOVE 'A' TO HV-EST-ACTIVO
           MOVE 'P' TO HV-EST-PENDIENTE
           MOVE 'D' TO HV-EST-DEVUELTO
           MOVE 'V' TO HV-EST-VENCIDO.
      *
       PROCESAR-ARCHIVO.
           PERFORM LEER-ENTRADA
           PERFORM UNTIL WS-FIN-ARCHIVO-SI
               PERFORM MOVER-DATOS-HOST
               PERFORM VALIDAR-REGISTRO
               IF WS-RESULTADO-OK
                   PERFORM RESOLVER-FECHA-OPERACION
               END-IF
               IF WS-RESULTADO-OK
                   EVALUATE WS-ENT-OPERACION
                       WHEN 'P'
                           PERFORM PROCESAR-PRESTAMO
                       WHEN 'D'
                           PERFORM PROCESAR-DEVOLUCION
                   END-EVALUATE
               ELSE
                   PERFORM REPORTAR-ERROR-FUNCIONAL
               END-IF
               PERFORM LEER-ENTRADA
           END-PERFORM.
      *
       FINALIZAR.
           PERFORM ESCRIBIR-TOTALES
           PERFORM CERRAR-ARCHIVOS
           DISPLAY 'PROGRAMA PRESTAM TERMINADO'.
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
       VALIDAR-REGISTRO.
           MOVE 'S' TO WS-RESULTADO
           MOVE SPACES TO WS-MOTIVO-ERROR
           IF WS-ENT-OPERACION NOT = 'P'
              AND WS-ENT-OPERACION NOT = 'D'
               MOVE 'N' TO WS-RESULTADO
               MOVE 'OPERACION INVALIDA' TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK
              AND WS-ENT-OPERACION = 'P'
              AND WS-ENT-COD-USUARIO = SPACES
               MOVE 'N' TO WS-RESULTADO
               MOVE 'USUARIO OBLIGATORIO PARA PRESTAMO'
                   TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK
              AND WS-ENT-OPERACION = 'P'
              AND WS-ENT-COD-LIBRO = SPACES
               MOVE 'N' TO WS-RESULTADO
               MOVE 'LIBRO OBLIGATORIO PARA PRESTAMO'
                   TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK
              AND WS-ENT-OPERACION = 'D'
              AND WS-ENT-NUM-PRESTAMO NOT NUMERIC
               MOVE 'N' TO WS-RESULTADO
               MOVE 'NUMERO DE PRESTAMO INVALIDO'
                   TO WS-MOTIVO-ERROR
           END-IF.
      *
       MOVER-DATOS-HOST.
           MOVE WS-ENT-COD-USUARIO   TO HV-COD-USUARIO
           MOVE WS-ENT-COD-LIBRO     TO HV-COD-LIBRO
           MOVE WS-ENT-OBSERVACIONES TO HV-OBSERVACIONES
           MOVE ZERO                 TO HV-PRE-NUM
           MOVE ZERO                 TO HV-MULTA
           IF WS-ENT-NUM-PRESTAMO NUMERIC
               MOVE WS-ENT-NUM-PRESTAMO TO HV-PRE-NUM
           END-IF.
      *
       RESOLVER-FECHA-OPERACION.
           IF WS-ENT-FECHA-OPER = SPACES
               ACCEPT WS-FECHA-NUM FROM DATE YYYYMMDD
           ELSE
               PERFORM CONVERTIR-FECHA-ENTRADA
           END-IF
           IF WS-RESULTADO-OK
               PERFORM FORMATEAR-FECHA-OPER
           END-IF.
      *
       CONVERTIR-FECHA-ENTRADA.
           IF WS-ENT-FECHA-OPER(5:1) NOT = '-'
               MOVE 'N' TO WS-RESULTADO
               MOVE 'FECHA INVALIDA, USAR YYYY-MM-DD'
                   TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK
              AND WS-ENT-FECHA-OPER(8:1) NOT = '-'
               MOVE 'N' TO WS-RESULTADO
               MOVE 'FECHA INVALIDA, USAR YYYY-MM-DD'
                   TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK
               STRING WS-ENT-FECHA-OPER(1:4)
                      WS-ENT-FECHA-OPER(6:2)
                      WS-ENT-FECHA-OPER(9:2)
                   DELIMITED BY SIZE
                   INTO WS-FECHA-X
               END-STRING
           END-IF
           IF WS-RESULTADO-OK AND WS-FECHA-X NOT NUMERIC
               MOVE 'N' TO WS-RESULTADO
               MOVE 'FECHA INVALIDA, USAR YYYY-MM-DD'
                   TO WS-MOTIVO-ERROR
           END-IF.
      *
       FORMATEAR-FECHA-OPER.
           COMPUTE WS-FECHA-INT =
               FUNCTION INTEGER-OF-DATE(WS-FECHA-NUM)
           MOVE WS-FECHA-NUM TO WS-FMT-NUM
           MOVE WS-FMT-AAAA  TO WS-ISO-AAAA
           MOVE WS-FMT-MM    TO WS-ISO-MM
           MOVE WS-FMT-DD    TO WS-ISO-DD
           MOVE WS-FECHA-ISO TO HV-FECHA-OPER.
      *
       FORMATEAR-FECHA-LIMITE.
           COMPUTE WS-LIMITE-INT =
               WS-FECHA-INT + WS-DIAS-PRESTAMO
           COMPUTE WS-LIMITE-NUM =
               FUNCTION DATE-OF-INTEGER(WS-LIMITE-INT)
           MOVE WS-LIMITE-NUM TO WS-FMT-NUM
           MOVE WS-FMT-AAAA   TO WS-ISO-AAAA
           MOVE WS-FMT-MM     TO WS-ISO-MM
           MOVE WS-FMT-DD     TO WS-ISO-DD
           MOVE WS-FECHA-ISO  TO HV-FECHA-LIMITE.
      *
       PROCESAR-PRESTAMO.
           PERFORM BUSCAR-USUARIO
           EVALUATE TRUE
               WHEN SQL-OK
                   CONTINUE
               WHEN SQL-NOT-FOUND
                   MOVE 'USUARIO NO ENCONTRADO O INACTIVO'
                       TO WS-MOTIVO-ERROR
                   PERFORM REPORTAR-ERROR-FUNCIONAL
                   EXIT PARAGRAPH
               WHEN OTHER
                   PERFORM REPORTAR-ERROR-SQL
                   EXIT PARAGRAPH
           END-EVALUATE
           PERFORM CONFIGURAR-LIMITES
           PERFORM BUSCAR-LIBRO
           EVALUATE TRUE
               WHEN SQL-OK
                   CONTINUE
               WHEN SQL-NOT-FOUND
                   MOVE 'LIBRO NO ENCONTRADO O INACTIVO'
                       TO WS-MOTIVO-ERROR
                   PERFORM REPORTAR-ERROR-FUNCIONAL
                   EXIT PARAGRAPH
               WHEN OTHER
                   PERFORM REPORTAR-ERROR-SQL
                   EXIT PARAGRAPH
           END-EVALUATE
           IF HV-STOCK-DISP <= ZERO
               MOVE 'LIBRO SIN STOCK DISPONIBLE' TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-ERROR-FUNCIONAL
               EXIT PARAGRAPH
           END-IF
           PERFORM CONTAR-VENCIDOS
           IF NOT SQL-OK
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           IF HV-CANT-VENCIDOS > ZERO
               MOVE 'USUARIO CON PRESTAMOS VENCIDOS'
                   TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-ERROR-FUNCIONAL
               EXIT PARAGRAPH
           END-IF
           PERFORM CONTAR-ACTIVOS
           IF NOT SQL-OK
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           IF HV-CANT-ACTIVOS >= WS-MAX-LIBROS
               MOVE 'USUARIO SUPERA LIMITE DE PRESTAMOS'
                   TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-ERROR-FUNCIONAL
               EXIT PARAGRAPH
           END-IF
           PERFORM FORMATEAR-FECHA-LIMITE
           PERFORM OBTENER-NUMERO-PRESTAMO
           IF NOT SQL-OK
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM INSERTAR-PRESTAMO
           IF NOT SQL-OK
               PERFORM ROLLBACK-TRANSACCION
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM DESCONTAR-STOCK
           IF SQL-OK
               PERFORM COMMIT-TRANSACCION
               ADD 1 TO WS-CONT-PRESTAMOS
               MOVE 'PRESTAMO OK' TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-REGISTRO-OK
           ELSE
               PERFORM ROLLBACK-TRANSACCION
               PERFORM REPORTAR-ERROR-SQL
           END-IF.
      *
       PROCESAR-DEVOLUCION.
           PERFORM BUSCAR-PRESTAMO
           EVALUATE TRUE
               WHEN SQL-OK
                   CONTINUE
               WHEN SQL-NOT-FOUND
                   MOVE 'PRESTAMO NO ENCONTRADO'
                       TO WS-MOTIVO-ERROR
                   PERFORM REPORTAR-ERROR-FUNCIONAL
                   EXIT PARAGRAPH
               WHEN OTHER
                   PERFORM REPORTAR-ERROR-SQL
                   EXIT PARAGRAPH
           END-EVALUATE
           IF HV-ESTADO-PRE = 'D'
               MOVE 'PRESTAMO YA DEVUELTO' TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-ERROR-FUNCIONAL
               EXIT PARAGRAPH
           END-IF
           IF HV-ESTADO-PRE NOT = 'P' AND HV-ESTADO-PRE NOT = 'V'
               MOVE 'PRESTAMO NO ESTA ACTIVO' TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-ERROR-FUNCIONAL
               EXIT PARAGRAPH
           END-IF
           IF WS-ENT-COD-USUARIO NOT = SPACES
              AND WS-ENT-COD-USUARIO NOT = HV-COD-USUARIO
               MOVE 'USUARIO NO COINCIDE CON PRESTAMO'
                   TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-ERROR-FUNCIONAL
               EXIT PARAGRAPH
           END-IF
           IF WS-ENT-COD-LIBRO NOT = SPACES
              AND WS-ENT-COD-LIBRO NOT = HV-COD-LIBRO
               MOVE 'LIBRO NO COINCIDE CON PRESTAMO'
                   TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-ERROR-FUNCIONAL
               EXIT PARAGRAPH
           END-IF
           PERFORM CALCULAR-MULTA
           PERFORM ACTUALIZAR-DEVOLUCION
           IF NOT SQL-OK
               PERFORM ROLLBACK-TRANSACCION
               PERFORM REPORTAR-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM SUMAR-STOCK
           IF SQL-OK
               PERFORM COMMIT-TRANSACCION
               ADD 1 TO WS-CONT-DEVOLUCIONES
               MOVE 'DEVOLUCION OK' TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-REGISTRO-OK
           ELSE
               PERFORM ROLLBACK-TRANSACCION
               PERFORM REPORTAR-ERROR-SQL
           END-IF.
      *
       CONFIGURAR-LIMITES.
           EVALUATE HV-USU-TIPO
               WHEN 'E'
                   MOVE CONST-MAX-LIBROS-EST TO WS-MAX-LIBROS
                   MOVE CONST-DIAS-PRESTAMO-EST TO WS-DIAS-PRESTAMO
               WHEN 'D'
                   MOVE CONST-MAX-LIBROS-DOC TO WS-MAX-LIBROS
                   MOVE CONST-DIAS-PRESTAMO-DOC TO WS-DIAS-PRESTAMO
               WHEN OTHER
                   MOVE CONST-MAX-LIBROS-ADM TO WS-MAX-LIBROS
                   MOVE CONST-DIAS-PRESTAMO-ADM TO WS-DIAS-PRESTAMO
           END-EVALUATE.
      *
       CALCULAR-MULTA.
           MOVE HV-FECHA-LIMITE(1:4) TO WS-FMT-AAAA
           MOVE HV-FECHA-LIMITE(6:2) TO WS-FMT-MM
           MOVE HV-FECHA-LIMITE(9:2) TO WS-FMT-DD
           MOVE WS-FMT-NUM TO WS-LIMITE-NUM
           COMPUTE WS-LIMITE-INT =
               FUNCTION INTEGER-OF-DATE(WS-LIMITE-NUM)
           COMPUTE WS-DIAS-ATRASO = WS-FECHA-INT - WS-LIMITE-INT
           IF WS-DIAS-ATRASO > ZERO
               COMPUTE HV-MULTA =
                   WS-DIAS-ATRASO * CONST-MULTA-DIA
           ELSE
               MOVE ZERO TO HV-MULTA
           END-IF.
      *
       BUSCAR-USUARIO.
           EXEC SQL
               SELECT TIPO_USUARIO
                 INTO :HV-USU-TIPO
                FROM KC03G24.USUARIOS
               WHERE COD_USUARIO = :HV-COD-USUARIO
                  AND ESTADO = :HV-EST-ACTIVO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       BUSCAR-LIBRO.
           EXEC SQL
               SELECT STOCK_DISPONIBLE
                 INTO :HV-STOCK-DISP
                FROM KC03G24.LIBROS
               WHERE COD_LIBRO = :HV-COD-LIBRO
                  AND ESTADO = :HV-EST-ACTIVO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       CONTAR-VENCIDOS.
           MOVE ZERO TO HV-CANT-VENCIDOS
           EXEC SQL
               SELECT COUNT(*)
                 INTO :HV-CANT-VENCIDOS
                FROM KC03G24.PRESTAMOS
               WHERE COD_USUARIO = :HV-COD-USUARIO
                  AND (ESTADO = :HV-EST-VENCIDO
                   OR (ESTADO = :HV-EST-PENDIENTE
                  AND FECHA_LIMITE < DATE(:HV-FECHA-OPER)))
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       CONTAR-ACTIVOS.
           MOVE ZERO TO HV-CANT-ACTIVOS
           EXEC SQL
               SELECT COUNT(*)
                 INTO :HV-CANT-ACTIVOS
                FROM KC03G24.PRESTAMOS
               WHERE COD_USUARIO = :HV-COD-USUARIO
                  AND (ESTADO = :HV-EST-PENDIENTE
                   OR ESTADO = :HV-EST-VENCIDO)
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       OBTENER-NUMERO-PRESTAMO.
           EXEC SQL
               SELECT NEXT VALUE FOR KC03G24.SEQ_PRESTAMOS
                 INTO :HV-PRE-NUM
                 FROM SYSIBM.SYSDUMMY1
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       INSERTAR-PRESTAMO.
           EXEC SQL
               INSERT INTO KC03G24.PRESTAMOS
                   (NUM_PRESTAMO, COD_LIBRO, COD_USUARIO,
                    FECHA_PRESTAMO, FECHA_LIMITE, ESTADO,
                    MULTA, OBSERVACIONES)
               VALUES
                    (:HV-PRE-NUM, :HV-COD-LIBRO, :HV-COD-USUARIO,
                    DATE(:HV-FECHA-OPER),
                    DATE(:HV-FECHA-LIMITE),
                    :HV-EST-PENDIENTE,
                    :HV-MULTA, :HV-OBSERVACIONES)
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       DESCONTAR-STOCK.
           EXEC SQL
               UPDATE KC03G24.LIBROS
                  SET STOCK_DISPONIBLE = STOCK_DISPONIBLE - 1
                WHERE COD_LIBRO = :HV-COD-LIBRO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       BUSCAR-PRESTAMO.
           EXEC SQL
               SELECT COD_USUARIO, COD_LIBRO, FECHA_LIMITE, ESTADO
                 INTO :HV-COD-USUARIO, :HV-COD-LIBRO,
                      :HV-FECHA-LIMITE, :HV-ESTADO-PRE
                 FROM KC03G24.PRESTAMOS
                WHERE NUM_PRESTAMO = :HV-PRE-NUM
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       ACTUALIZAR-DEVOLUCION.
           EXEC SQL
               UPDATE KC03G24.PRESTAMOS
                  SET FECHA_DEVOL = DATE(:HV-FECHA-OPER),
                      ESTADO = :HV-EST-DEVUELTO,
                      MULTA = :HV-MULTA,
                      OBSERVACIONES = :HV-OBSERVACIONES
                WHERE NUM_PRESTAMO = :HV-PRE-NUM
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       SUMAR-STOCK.
           EXEC SQL
               UPDATE KC03G24.LIBROS
                  SET STOCK_DISPONIBLE = STOCK_DISPONIBLE + 1
                WHERE COD_LIBRO = :HV-COD-LIBRO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       COMMIT-TRANSACCION.
           EXEC SQL COMMIT END-EXEC.
      *
       ROLLBACK-TRANSACCION.
           EXEC SQL ROLLBACK END-EXEC.
      *
       ESCRIBIR-CABECERA.
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'REPORTE DE PRESTAMOS Y DEVOLUCIONES'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'O NROPREST USUARIO    LIBRO      RESULTADO    MENSAJE'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTAR-REGISTRO-OK.
           INITIALIZE WS-LINEA-DETALLE
           MOVE WS-ENT-OPERACION TO WRK-DET-OPER
           MOVE HV-PRE-NUM       TO WRK-DET-NUM
           MOVE HV-COD-USUARIO   TO WRK-DET-USUARIO
           MOVE HV-COD-LIBRO     TO WRK-DET-LIBRO
           MOVE 'OK'             TO WRK-DET-RESULTADO
           MOVE WS-MOTIVO-ERROR  TO WRK-DET-MENSAJE
           MOVE WS-LINEA-DETALLE TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTAR-ERROR-FUNCIONAL.
           ADD 1 TO WS-CONT-ERRORES
           INITIALIZE WS-LINEA-DETALLE
           MOVE WS-ENT-OPERACION TO WRK-DET-OPER
           MOVE HV-PRE-NUM       TO WRK-DET-NUM
           MOVE HV-COD-USUARIO   TO WRK-DET-USUARIO
           MOVE HV-COD-LIBRO     TO WRK-DET-LIBRO
           MOVE 'RECHAZADO'      TO WRK-DET-RESULTADO
           MOVE WS-MOTIVO-ERROR  TO WRK-DET-MENSAJE
           MOVE WS-LINEA-DETALLE TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTAR-ERROR-SQL.
           ADD 1 TO WS-CONT-ERRORES
           INITIALIZE WS-LINEA-DETALLE
           MOVE WS-ENT-OPERACION TO WRK-DET-OPER
           MOVE HV-PRE-NUM       TO WRK-DET-NUM
           MOVE HV-COD-USUARIO   TO WRK-DET-USUARIO
           MOVE HV-COD-LIBRO     TO WRK-DET-LIBRO
           MOVE 'ERROR SQL'      TO WRK-DET-RESULTADO
           MOVE WS-SQLCODE       TO WS-SQLCODE-DISPLAY
           MOVE SQLERRMC         TO WS-SQLERRMC-DISPLAY
           STRING 'SQLCODE ' WS-SQLCODE-DISPLAY
                  ' ID ' WS-SQLERRMC-DISPLAY
               DELIMITED BY SIZE
               INTO WRK-DET-MENSAJE
           END-STRING
           MOVE WS-LINEA-DETALLE TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       ESCRIBIR-TOTALES.
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           INITIALIZE WS-LINEA-TOTAL
           MOVE 'REGISTROS LEIDOS:' TO WRK-TOTAL-TEXTO
           MOVE WS-CONT-LEIDOS TO WRK-TOTAL-VALOR
           MOVE WS-LINEA-TOTAL TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           INITIALIZE WS-LINEA-TOTAL
           MOVE 'PRESTAMOS OK:' TO WRK-TOTAL-TEXTO
           MOVE WS-CONT-PRESTAMOS TO WRK-TOTAL-VALOR
           MOVE WS-LINEA-TOTAL TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           INITIALIZE WS-LINEA-TOTAL
           MOVE 'DEVOLUCIONES OK:' TO WRK-TOTAL-TEXTO
           MOVE WS-CONT-DEVOLUCIONES TO WRK-TOTAL-VALOR
           MOVE WS-LINEA-TOTAL TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           INITIALIZE WS-LINEA-TOTAL
           MOVE 'ERRORES:' TO WRK-TOTAL-TEXTO
           MOVE WS-CONT-ERRORES TO WRK-TOTAL-VALOR
           MOVE WS-LINEA-TOTAL TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       EMITIR-LINEA.
           DISPLAY WS-LINEA-REPORTE
           WRITE REG-REPORTE FROM WS-LINEA-REPORTE.
