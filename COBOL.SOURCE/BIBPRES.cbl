      ***************************************************************
      * PROGRAMA: BIBPRES - PRESTAMOS Y DEVOLUCIONES CICS/DB2     *
      * TRANSID : PRES                                            *
      * FUNCION : ALTA DE PRESTAMOS Y REGISTRO DE DEVOLUCIONES   *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BIBPRES.
       AUTHOR. ESTUDIANTE KC03G24.
       DATE-WRITTEN. 30/06/2026.
       DATE-COMPILED.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.
      *
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
      *
       01 HV-PRESTAMO.
           05 HV-NUM-PRESTAMO         PIC S9(9) COMP.
           05 HV-COD-USUARIO          PIC X(10).
           05 HV-COD-LIBRO            PIC X(10).
           05 HV-FECHA-HOY            PIC X(10).
           05 HV-FECHA-LIMITE         PIC X(10).
           05 HV-ESTADO-PRE           PIC X(1).
           05 HV-MULTA                PIC S9(5)V99 COMP-3.
           05 HV-OBSERVACIONES        PIC X(100).
       01 HV-USUARIO.
           05 HV-USU-NOMBRE           PIC X(30).
           05 HV-USU-APELLIDO         PIC X(30).
           05 HV-USU-TIPO             PIC X(1).
       01 HV-LIBRO.
           05 HV-LIB-TITULO           PIC X(60).
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
       01 WS-COMMAREA.
           05 CA-PROGRAMA             PIC X(8) VALUE SPACES.
           05 FILLER                  PIC X(192) VALUE SPACES.
      *
       01 WS-CONSTANTES.
           05 WS-MAPSET               PIC X(8) VALUE 'BIBPRES'.
           05 WS-MAPA                 PIC X(8) VALUE 'BIBPRES'.
      *
       01 WS-CONTROL.
           05 WS-SQLCODE              PIC S9(9) COMP VALUE ZERO.
              88 SQL-OK               VALUE 0.
              88 SQL-NOT-FOUND        VALUE 100.
           05 WS-SQLCODE-DISPLAY      PIC -ZZZZZZZZ9.
           05 WS-RESULTADO            PIC X(1) VALUE 'N'.
              88 WS-RESULTADO-OK      VALUE 'S'.
           05 WS-MENSAJE              PIC X(79) VALUE SPACES.
           05 WS-MAX-LIBROS           PIC 9(2) VALUE ZERO.
           05 WS-DIAS-PRESTAMO        PIC 9(2) VALUE ZERO.
           05 WS-DIAS-ATRASO          PIC S9(9) COMP VALUE ZERO.
      *
       01 WS-FECHA.
           05 WS-ABSTIME              PIC S9(15) COMP-3.
           05 WS-FECHA-X              PIC X(8).
           05 WS-FECHA-NUM REDEFINES WS-FECHA-X PIC 9(8).
           05 WS-FECHA-INT            PIC S9(9) COMP VALUE ZERO.
           05 WS-LIMITE-NUM           PIC 9(8).
           05 WS-LIMITE-INT           PIC S9(9) COMP VALUE ZERO.
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
       01 WS-DISPLAY.
           05 WS-NUM-DISP             PIC 9(8).
           05 WS-STOCK-DISP           PIC ZZZZ9.
           05 WS-MULTA-DISP           PIC ZZZZZ9.99.
      *
           COPY DFHAID.
           COPY BIBPRES.
      *
       LINKAGE SECTION.
       01 DFHCOMMAREA                 PIC X(200).
      *
       PROCEDURE DIVISION.
      *
       MAIN-PROGRAM.
           EXEC CICS HANDLE CONDITION
                MAPFAIL(PRIMERA-VEZ)
           END-EXEC
           IF EIBCALEN > ZERO
               MOVE DFHCOMMAREA TO WS-COMMAREA
           END-IF
           IF CA-PROGRAMA NOT = 'BIBPRES'
               PERFORM PRIMERA-VEZ
           END-IF
           EVALUATE EIBAID
               WHEN DFHPF3
                   PERFORM VOLVER-MENU
               WHEN DFHPF12
                   PERFORM SALIR
               WHEN DFHCLEAR
                   PERFORM PRIMERA-VEZ
               WHEN DFHENTER
                   PERFORM PROCESAR-PANTALLA
               WHEN OTHER
                   PERFORM ENVIAR-ACTUAL
           END-EVALUATE.
      *
       PRIMERA-VEZ.
           INITIALIZE WS-COMMAREA
           MOVE 'BIBPRES' TO CA-PROGRAMA
           MOVE LOW-VALUES TO BIBPRESO
           MOVE 'INGRESE P PARA PRESTAMO O D PARA DEVOLUCION'
               TO MENSAJEO
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.
      *
       ENVIAR-ACTUAL.
           MOVE LOW-VALUES TO BIBPRESO
           MOVE 'USE ENTER PARA CONFIRMAR, PF3 PARA MENU'
               TO MENSAJEO
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.
      *
       PROCESAR-PANTALLA.
           EXEC CICS RECEIVE MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                INTO(BIBPRESI)
           END-EXEC
           MOVE LOW-VALUES TO BIBPRESO
           PERFORM INICIALIZAR-HOST-VARS
           PERFORM NORMALIZAR-ENTRADA
           PERFORM MOVER-ENTRADA-HOST
           PERFORM OBTENER-FECHA-HOY
           EVALUATE OPERAI
               WHEN 'P'
               WHEN 'p'
                   PERFORM PROCESAR-PRESTAMO
               WHEN 'D'
               WHEN 'd'
                   PERFORM PROCESAR-DEVOLUCION
               WHEN OTHER
                   MOVE 'OPERACION INVALIDA. USE P O D'
                       TO WS-MENSAJE
           END-EVALUATE
           PERFORM MOVER-ENTRADA-PANTALLA
           MOVE WS-MENSAJE TO MENSAJEO
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.
      *
       INICIALIZAR-HOST-VARS.
           MOVE 'A' TO HV-EST-ACTIVO
           MOVE 'P' TO HV-EST-PENDIENTE
           MOVE 'D' TO HV-EST-DEVUELTO
           MOVE 'V' TO HV-EST-VENCIDO
           MOVE ZERO TO HV-NUM-PRESTAMO
           MOVE ZERO TO HV-MULTA
           MOVE SPACES TO HV-COD-USUARIO HV-COD-LIBRO
           MOVE SPACES TO HV-OBSERVACIONES WS-MENSAJE.
      *
       NORMALIZAR-ENTRADA.
           IF OPERAI = LOW-VALUES
               MOVE SPACE TO OPERAI
           END-IF
           IF NUMPREI = LOW-VALUES
               MOVE SPACES TO NUMPREI
           END-IF
           IF CODUSUI = LOW-VALUES
               MOVE SPACES TO CODUSUI
           END-IF
           IF CODLIBI = LOW-VALUES
               MOVE SPACES TO CODLIBI
           END-IF
           IF OBSERVI = LOW-VALUES
               MOVE SPACES TO OBSERVI
           END-IF.
      *
       MOVER-ENTRADA-HOST.
           MOVE CODUSUI TO HV-COD-USUARIO
           MOVE CODLIBI TO HV-COD-LIBRO
           MOVE OBSERVI TO HV-OBSERVACIONES
           IF NUMPREI NUMERIC
               MOVE NUMPREI TO HV-NUM-PRESTAMO
           END-IF.
      *
       PROCESAR-PRESTAMO.
           IF HV-COD-USUARIO = SPACES
               MOVE 'CODIGO DE USUARIO OBLIGATORIO'
                   TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           IF HV-COD-LIBRO = SPACES
               MOVE 'CODIGO DE LIBRO OBLIGATORIO'
                   TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           PERFORM BUSCAR-USUARIO
           EVALUATE TRUE
               WHEN SQL-OK
                   PERFORM MOVER-USUARIO-PANTALLA
               WHEN SQL-NOT-FOUND
                   MOVE 'USUARIO NO ENCONTRADO O INACTIVO'
                       TO WS-MENSAJE
                   EXIT PARAGRAPH
               WHEN OTHER
                   PERFORM MENSAJE-ERROR-SQL
                   EXIT PARAGRAPH
           END-EVALUATE
           PERFORM CONFIGURAR-LIMITES
           PERFORM BUSCAR-LIBRO
           EVALUATE TRUE
               WHEN SQL-OK
                   PERFORM MOVER-LIBRO-PANTALLA
               WHEN SQL-NOT-FOUND
                   MOVE 'LIBRO NO ENCONTRADO O INACTIVO'
                       TO WS-MENSAJE
                   EXIT PARAGRAPH
               WHEN OTHER
                   PERFORM MENSAJE-ERROR-SQL
                   EXIT PARAGRAPH
           END-EVALUATE
           IF HV-STOCK-DISP <= ZERO
               MOVE 'LIBRO SIN STOCK DISPONIBLE' TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           PERFORM CONTAR-VENCIDOS
           IF NOT SQL-OK
               PERFORM MENSAJE-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           IF HV-CANT-VENCIDOS > ZERO
               MOVE 'USUARIO CON PRESTAMOS VENCIDOS'
                   TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           PERFORM CONTAR-ACTIVOS
           IF NOT SQL-OK
               PERFORM MENSAJE-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           IF HV-CANT-ACTIVOS >= WS-MAX-LIBROS
               MOVE 'USUARIO SUPERA LIMITE DE PRESTAMOS'
                   TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           PERFORM CALCULAR-FECHA-LIMITE
           PERFORM OBTENER-NUMERO-PRESTAMO
           IF NOT SQL-OK
               PERFORM MENSAJE-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM INSERTAR-PRESTAMO
           IF NOT SQL-OK
               PERFORM ROLLBACK-TRANSACCION
               PERFORM MENSAJE-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM DESCONTAR-STOCK
           IF SQL-OK
               PERFORM COMMIT-TRANSACCION
               SUBTRACT 1 FROM HV-STOCK-DISP
               PERFORM MOVER-LIBRO-PANTALLA
               PERFORM MOVER-PRESTAMO-PANTALLA
               MOVE 'PRESTAMO REGISTRADO CORRECTAMENTE'
                   TO WS-MENSAJE
           ELSE
               PERFORM ROLLBACK-TRANSACCION
               PERFORM MENSAJE-ERROR-SQL
           END-IF.
      *
       PROCESAR-DEVOLUCION.
           IF NUMPREI NOT NUMERIC
               MOVE 'NUMERO DE PRESTAMO OBLIGATORIO'
                   TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           PERFORM BUSCAR-PRESTAMO
           EVALUATE TRUE
               WHEN SQL-OK
                   CONTINUE
               WHEN SQL-NOT-FOUND
                   MOVE 'PRESTAMO NO ENCONTRADO'
                       TO WS-MENSAJE
                   EXIT PARAGRAPH
               WHEN OTHER
                   PERFORM MENSAJE-ERROR-SQL
                   EXIT PARAGRAPH
           END-EVALUATE
           IF HV-ESTADO-PRE = HV-EST-DEVUELTO
               MOVE 'PRESTAMO YA DEVUELTO' TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           IF HV-ESTADO-PRE NOT = HV-EST-PENDIENTE
              AND HV-ESTADO-PRE NOT = HV-EST-VENCIDO
               MOVE 'PRESTAMO NO ESTA ACTIVO'
                   TO WS-MENSAJE
               EXIT PARAGRAPH
           END-IF
           PERFORM BUSCAR-USUARIO
           IF SQL-OK
               PERFORM MOVER-USUARIO-PANTALLA
           END-IF
           PERFORM BUSCAR-LIBRO
           IF SQL-OK
               PERFORM MOVER-LIBRO-PANTALLA
           END-IF
           PERFORM CALCULAR-MULTA
           PERFORM ACTUALIZAR-DEVOLUCION
           IF NOT SQL-OK
               PERFORM ROLLBACK-TRANSACCION
               PERFORM MENSAJE-ERROR-SQL
               EXIT PARAGRAPH
           END-IF
           PERFORM SUMAR-STOCK
           IF SQL-OK
               PERFORM COMMIT-TRANSACCION
               ADD 1 TO HV-STOCK-DISP
               PERFORM MOVER-LIBRO-PANTALLA
               PERFORM MOVER-PRESTAMO-PANTALLA
               MOVE 'DEVOLUCION REGISTRADA CORRECTAMENTE'
                   TO WS-MENSAJE
           ELSE
               PERFORM ROLLBACK-TRANSACCION
               PERFORM MENSAJE-ERROR-SQL
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
       OBTENER-FECHA-HOY.
           EXEC CICS ASKTIME
                ABSTIME(WS-ABSTIME)
           END-EXEC
           EXEC CICS FORMATTIME
                ABSTIME(WS-ABSTIME)
                YYYYMMDD(WS-FECHA-X)
           END-EXEC
           COMPUTE WS-FECHA-INT =
               FUNCTION INTEGER-OF-DATE(WS-FECHA-NUM)
           MOVE WS-FECHA-NUM TO WS-FMT-NUM
           PERFORM FORMATEAR-FECHA-ISO
           MOVE WS-FECHA-ISO TO HV-FECHA-HOY.
      *
       CALCULAR-FECHA-LIMITE.
           COMPUTE WS-LIMITE-INT =
               WS-FECHA-INT + WS-DIAS-PRESTAMO
           COMPUTE WS-LIMITE-NUM =
               FUNCTION DATE-OF-INTEGER(WS-LIMITE-INT)
           MOVE WS-LIMITE-NUM TO WS-FMT-NUM
           PERFORM FORMATEAR-FECHA-ISO
           MOVE WS-FECHA-ISO TO HV-FECHA-LIMITE.
      *
       FORMATEAR-FECHA-ISO.
           MOVE WS-FMT-AAAA TO WS-ISO-AAAA
           MOVE WS-FMT-MM TO WS-ISO-MM
           MOVE WS-FMT-DD TO WS-ISO-DD.
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
               SELECT NOMBRE, APELLIDO, TIPO_USUARIO
                 INTO :HV-USU-NOMBRE, :HV-USU-APELLIDO,
                      :HV-USU-TIPO
                 FROM KC03G24.USUARIOS
                WHERE COD_USUARIO = :HV-COD-USUARIO
                  AND ESTADO = :HV-EST-ACTIVO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       BUSCAR-LIBRO.
           EXEC SQL
               SELECT TITULO, STOCK_DISPONIBLE
                 INTO :HV-LIB-TITULO, :HV-STOCK-DISP
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
                  AND FECHA_LIMITE < DATE(:HV-FECHA-HOY)))
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
                 INTO :HV-NUM-PRESTAMO
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
                   (:HV-NUM-PRESTAMO, :HV-COD-LIBRO,
                    :HV-COD-USUARIO, DATE(:HV-FECHA-HOY),
                    DATE(:HV-FECHA-LIMITE), :HV-EST-PENDIENTE,
                    :HV-MULTA, :HV-OBSERVACIONES)
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       DESCONTAR-STOCK.
           EXEC SQL
               UPDATE KC03G24.LIBROS
                  SET STOCK_DISPONIBLE = STOCK_DISPONIBLE - 1
                WHERE COD_LIBRO = :HV-COD-LIBRO
                  AND STOCK_DISPONIBLE > 0
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       BUSCAR-PRESTAMO.
           EXEC SQL
               SELECT COD_USUARIO, COD_LIBRO, FECHA_LIMITE,
                      ESTADO
                 INTO :HV-COD-USUARIO, :HV-COD-LIBRO,
                      :HV-FECHA-LIMITE, :HV-ESTADO-PRE
                 FROM KC03G24.PRESTAMOS
                WHERE NUM_PRESTAMO = :HV-NUM-PRESTAMO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       ACTUALIZAR-DEVOLUCION.
           EXEC SQL
               UPDATE KC03G24.PRESTAMOS
                  SET FECHA_DEVOL = DATE(:HV-FECHA-HOY),
                      ESTADO = :HV-EST-DEVUELTO,
                      MULTA = :HV-MULTA,
                      OBSERVACIONES = :HV-OBSERVACIONES
                WHERE NUM_PRESTAMO = :HV-NUM-PRESTAMO
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
           EXEC CICS SYNCPOINT END-EXEC.
      *
       ROLLBACK-TRANSACCION.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC.
      *
       MOVER-USUARIO-PANTALLA.
           STRING FUNCTION TRIM(HV-USU-NOMBRE)
                  ' '
                  FUNCTION TRIM(HV-USU-APELLIDO)
               DELIMITED BY SIZE
               INTO NOMUSUO
           END-STRING
           EVALUATE HV-USU-TIPO
               WHEN 'E'
                   MOVE 'ESTUDIANTE' TO TIPUSUO
               WHEN 'D'
                   MOVE 'DOCENTE' TO TIPUSUO
               WHEN OTHER
                   MOVE 'ADMINISTRATIVO' TO TIPUSUO
           END-EVALUATE.
      *
       MOVER-LIBRO-PANTALLA.
           MOVE HV-LIB-TITULO(1:50) TO TITLIBO
           MOVE HV-STOCK-DISP TO WS-STOCK-DISP
           STRING 'STOCK: ' WS-STOCK-DISP
               DELIMITED BY SIZE
               INTO STOLIBO
           END-STRING.
      *
       MOVER-PRESTAMO-PANTALLA.
           MOVE HV-NUM-PRESTAMO TO WS-NUM-DISP
           MOVE WS-NUM-DISP TO NUMPREO
           MOVE HV-FECHA-HOY TO FECPREO
           MOVE HV-FECHA-LIMITE TO FECLIMO
           MOVE HV-MULTA TO WS-MULTA-DISP
           MOVE WS-MULTA-DISP TO MULTAO.
      *
       MOVER-ENTRADA-PANTALLA.
           MOVE OPERAI TO OPERAO
           IF NUMPREO = LOW-VALUES
               MOVE NUMPREI TO NUMPREO
           END-IF
           MOVE HV-COD-USUARIO TO CODUSUO
           MOVE HV-COD-LIBRO TO CODLIBO
           MOVE OBSERVI TO OBSERVO.
      *
       MENSAJE-ERROR-SQL.
           MOVE WS-SQLCODE TO WS-SQLCODE-DISPLAY
           STRING 'ERROR DB2 SQLCODE ' WS-SQLCODE-DISPLAY
               DELIMITED BY SIZE
               INTO WS-MENSAJE
           END-STRING.
      *
       ENVIAR-MAPA.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                FROM(BIBPRESO)
                ERASE
                CURSOR
           END-EXEC.
      *
       RETORNAR.
           EXEC CICS RETURN
                TRANSID('PRES')
                COMMAREA(WS-COMMAREA)
                LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.
      *
       VOLVER-MENU.
           MOVE SPACES TO WS-COMMAREA
           EXEC CICS XCTL PROGRAM('BIBMENU')
                COMMAREA(WS-COMMAREA)
                LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.
      *
       SALIR.
           EXEC CICS RETURN END-EXEC.
