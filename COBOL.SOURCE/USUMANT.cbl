      ***************************************************************
      * PROGRAMA: USUMANT - MANTENIMIENTO DE USUARIOS EN DB2       *
      * FUNCION : INSERTA O ACTUALIZA USUARIOS DESDE ARCHIVO FIJO  *
      * ENTRADA : KC03G24.GRUPO6.DATA.INPUT2                      *
      * SALIDA  : CONSOLA Y KC03G24.GRUPO6.REPORTES.OUTPUT2       *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. USUMANT.
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
           RECORD CONTAINS 229 CHARACTERS
           BLOCK CONTAINS 0 RECORDS
           DATA RECORD IS REG-ENTRADA.
       01 REG-ENTRADA                 PIC X(229).
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
       01 HV-USUARIO.
           05 HV-USU-CODIGO           PIC X(10).
           05 HV-USU-NOMBRE           PIC X(30).
           05 HV-USU-APELLIDO         PIC X(30).
           05 HV-USU-TIPO-USUARIO     PIC X(1).
           05 HV-USU-EMAIL            PIC X(50).
           05 HV-USU-TELEFONO         PIC X(20).
           05 HV-USU-DIRECCION        PIC X(60).
           05 HV-USU-FECHA-ALTA       PIC X(10).
           05 HV-USU-FECHA-BAJA       PIC X(10).
           05 HV-USU-ESTADO           PIC X(1).
       01 HV-CONTROL-DB2.
           05 HV-CANT-USUARIO         PIC S9(9) COMP.
           05 HV-IND-FECHA-ALTA       PIC S9(4) COMP VALUE ZERO.
           05 HV-IND-FECHA-BAJA       PIC S9(4) COMP VALUE ZERO.
      *
           EXEC SQL END DECLARE SECTION END-EXEC.
      *
      * CONTADORES
      *
       01 WS-CONTADORES.
           05 WS-CONT-LEIDOS          PIC 9(7) VALUE ZERO.
           05 WS-CONT-INSERTADOS      PIC 9(7) VALUE ZERO.
           05 WS-CONT-ACTUALIZADOS    PIC 9(7) VALUE ZERO.
           05 WS-CONT-ERRORES         PIC 9(7) VALUE ZERO.
      *
      * VARIABLES DE CONTROL
      *
       01 WS-CONTROL.
           05 WS-FIN-ARCHIVO          PIC X(1) VALUE 'N'.
               88 WS-FIN-ARCHIVO-SI   VALUE 'S'.
           05 WS-RESULTADO            PIC X(1) VALUE 'N'.
               88 WS-RESULTADO-OK     VALUE 'S'.
           05 WS-ACCION               PIC X(1) VALUE SPACE.
               88 WS-ACCION-INSERT    VALUE 'I'.
               88 WS-ACCION-UPDATE    VALUE 'U'.
           05 WS-MOTIVO-ERROR         PIC X(60) VALUE SPACES.
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
               88 SQL-DUPLICATE       VALUE -803.
           05 WS-SQLCODE-DISPLAY      PIC -ZZZZZZZZ9.
      *
      * REGISTRO DE ENTRADA - LRECL 229
      * FECHAS EN FORMATO ISO YYYY-MM-DD PARA COLUMNAS DB2 DATE
      *
       01 WS-REGISTRO-ENTRADA.
           05 WS-ENT-CODIGO           PIC X(10).
           05 WS-ENT-NOMBRE           PIC X(30).
           05 WS-ENT-APELLIDO         PIC X(30).
           05 WS-ENT-TIPO-USUARIO     PIC X(1).
           05 WS-ENT-EMAIL            PIC X(50).
           05 WS-ENT-TELEFONO         PIC X(20).
           05 WS-ENT-DIRECCION        PIC X(60).
           05 WS-ENT-FECHA-ALTA       PIC X(10).
           05 WS-ENT-FECHA-BAJA       PIC X(10).
           05 WS-ENT-ESTADO           PIC X(1).
           05 FILLER                  PIC X(7).
      *
      * LINEAS DE REPORTE
      *
       01 WS-LINEA-REPORTE            PIC X(133).
       01 WS-LINEA-DETALLE.
           05 FILLER                  PIC X(8) VALUE 'USUARIO '.
           05 WRK-DET-CODIGO          PIC X(10).
           05 FILLER                  PIC X(3) VALUE ' - '.
           05 WRK-DET-ACCION          PIC X(12).
           05 FILLER                  PIC X(3) VALUE ' - '.
           05 WRK-DET-MENSAJE         PIC X(97).
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
           DISPLAY 'INICIANDO PROGRAMA USUMANT'
           PERFORM ABRIR-ARCHIVOS
           PERFORM ESCRIBIR-CABECERA.
      *
       PROCESAR-ARCHIVO.
           PERFORM LEER-ENTRADA
           PERFORM UNTIL WS-FIN-ARCHIVO-SI
               PERFORM VALIDAR-REGISTRO
               IF WS-RESULTADO-OK
                   PERFORM MOVER-DATOS-HOST-VARIABLES
                   PERFORM PROCESAR-USUARIO-DB2
               ELSE
                   PERFORM REPORTAR-REGISTRO-INVALIDO
               END-IF
               PERFORM LEER-ENTRADA
           END-PERFORM.
      *
       FINALIZAR.
           PERFORM ESCRIBIR-TOTALES
           PERFORM CERRAR-ARCHIVOS
           DISPLAY 'PROGRAMA USUMANT TERMINADO'.
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
      * VALIDACIONES Y MOVIMIENTO DE DATOS
      *
       VALIDAR-REGISTRO.
           MOVE 'S' TO WS-RESULTADO
           MOVE SPACES TO WS-MOTIVO-ERROR
           IF WS-ENT-CODIGO = SPACES
               MOVE 'N' TO WS-RESULTADO
               MOVE 'CODIGO OBLIGATORIO' TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK AND WS-ENT-NOMBRE = SPACES
               MOVE 'N' TO WS-RESULTADO
               MOVE 'NOMBRE OBLIGATORIO' TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK AND WS-ENT-APELLIDO = SPACES
               MOVE 'N' TO WS-RESULTADO
               MOVE 'APELLIDO OBLIGATORIO' TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK AND WS-ENT-EMAIL = SPACES
               MOVE 'N' TO WS-RESULTADO
               MOVE 'EMAIL OBLIGATORIO' TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK
              AND WS-ENT-TIPO-USUARIO NOT = 'E'
              AND WS-ENT-TIPO-USUARIO NOT = 'D'
              AND WS-ENT-TIPO-USUARIO NOT = 'A'
               MOVE 'N' TO WS-RESULTADO
               MOVE 'TIPO USUARIO INVALIDO' TO WS-MOTIVO-ERROR
           END-IF
           IF WS-RESULTADO-OK
              AND WS-ENT-ESTADO NOT = 'A'
              AND WS-ENT-ESTADO NOT = 'I'
               MOVE 'N' TO WS-RESULTADO
               MOVE 'ESTADO INVALIDO' TO WS-MOTIVO-ERROR
           END-IF.
      *
       MOVER-DATOS-HOST-VARIABLES.
           MOVE WS-ENT-CODIGO         TO HV-USU-CODIGO
           MOVE WS-ENT-NOMBRE         TO HV-USU-NOMBRE
           MOVE WS-ENT-APELLIDO       TO HV-USU-APELLIDO
           MOVE WS-ENT-TIPO-USUARIO   TO HV-USU-TIPO-USUARIO
           MOVE WS-ENT-EMAIL          TO HV-USU-EMAIL
           MOVE WS-ENT-TELEFONO       TO HV-USU-TELEFONO
           MOVE WS-ENT-DIRECCION      TO HV-USU-DIRECCION
           MOVE WS-ENT-FECHA-ALTA     TO HV-USU-FECHA-ALTA
           MOVE WS-ENT-FECHA-BAJA     TO HV-USU-FECHA-BAJA
           MOVE WS-ENT-ESTADO         TO HV-USU-ESTADO
           IF WS-ENT-FECHA-ALTA = SPACES
               MOVE -1 TO HV-IND-FECHA-ALTA
           ELSE
               MOVE ZERO TO HV-IND-FECHA-ALTA
           END-IF
           IF WS-ENT-FECHA-BAJA = SPACES
               MOVE -1 TO HV-IND-FECHA-BAJA
           ELSE
               MOVE ZERO TO HV-IND-FECHA-BAJA
           END-IF.
      *
      * RUTINAS DB2
      *
       PROCESAR-USUARIO-DB2.
           PERFORM CONSULTAR-USUARIO
           IF SQL-OK
               IF HV-CANT-USUARIO > 0
                   PERFORM ACTUALIZAR-USUARIO
               ELSE
                   PERFORM INSERTAR-USUARIO
               END-IF
           ELSE
               PERFORM REPORTAR-ERROR-SQL
           END-IF.
      *
       CONSULTAR-USUARIO.
           MOVE ZERO TO HV-CANT-USUARIO
           EXEC SQL
               SELECT COUNT(*)
                 INTO :HV-CANT-USUARIO
                 FROM KC03G24.USUARIOS
                WHERE COD_USUARIO = :HV-USU-CODIGO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       INSERTAR-USUARIO.
           EXEC SQL
               INSERT INTO KC03G24.USUARIOS
                   (COD_USUARIO, NOMBRE, APELLIDO,
                    TIPO_USUARIO, EMAIL, TELEFONO,
                    DIRECCION, FECHA_ALTA, FECHA_BAJA,
                    ESTADO)
               VALUES
                   (:HV-USU-CODIGO, :HV-USU-NOMBRE, :HV-USU-APELLIDO,
                    :HV-USU-TIPO-USUARIO, :HV-USU-EMAIL,
                    :HV-USU-TELEFONO, :HV-USU-DIRECCION,
                    :HV-USU-FECHA-ALTA :HV-IND-FECHA-ALTA,
                    :HV-USU-FECHA-BAJA :HV-IND-FECHA-BAJA,
                    :HV-USU-ESTADO)
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           IF SQL-OK
               PERFORM COMMIT-TRANSACCION
               ADD 1 TO WS-CONT-INSERTADOS
               SET WS-ACCION-INSERT TO TRUE
               MOVE 'INSERTADO OK' TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-REGISTRO-OK
           ELSE
               PERFORM ROLLBACK-TRANSACCION
               PERFORM REPORTAR-ERROR-SQL
           END-IF.
      *
       ACTUALIZAR-USUARIO.
           EXEC SQL
               UPDATE KC03G24.USUARIOS
                  SET NOMBRE       = :HV-USU-NOMBRE,
                      APELLIDO     = :HV-USU-APELLIDO,
                      TIPO_USUARIO = :HV-USU-TIPO-USUARIO,
                      EMAIL        = :HV-USU-EMAIL,
                      TELEFONO     = :HV-USU-TELEFONO,
                      DIRECCION    = :HV-USU-DIRECCION,
                      FECHA_ALTA   = :HV-USU-FECHA-ALTA
                                      :HV-IND-FECHA-ALTA,
                      FECHA_BAJA   = :HV-USU-FECHA-BAJA
                                      :HV-IND-FECHA-BAJA,
                      ESTADO       = :HV-USU-ESTADO
                WHERE COD_USUARIO  = :HV-USU-CODIGO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           IF SQL-OK
               PERFORM COMMIT-TRANSACCION
               ADD 1 TO WS-CONT-ACTUALIZADOS
               SET WS-ACCION-UPDATE TO TRUE
               MOVE 'ACTUALIZADO OK' TO WS-MOTIVO-ERROR
               PERFORM REPORTAR-REGISTRO-OK
           ELSE
               PERFORM ROLLBACK-TRANSACCION
               PERFORM REPORTAR-ERROR-SQL
           END-IF.
      *
       COMMIT-TRANSACCION.
           EXEC SQL COMMIT END-EXEC.
      *
       ROLLBACK-TRANSACCION.
           EXEC SQL ROLLBACK END-EXEC.
      *
      * RUTINAS DE REPORTE
      *
       ESCRIBIR-CABECERA.
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE 'REPORTE DE MANTENIMIENTO DE USUARIOS'
               TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           MOVE ALL '-' TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTAR-REGISTRO-OK.
           INITIALIZE WS-LINEA-DETALLE
           MOVE HV-USU-CODIGO TO WRK-DET-CODIGO
           IF WS-ACCION-INSERT
               MOVE 'INSERT' TO WRK-DET-ACCION
           ELSE
               MOVE 'UPDATE' TO WRK-DET-ACCION
           END-IF
           MOVE WS-MOTIVO-ERROR TO WRK-DET-MENSAJE
           MOVE WS-LINEA-DETALLE TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTAR-REGISTRO-INVALIDO.
           ADD 1 TO WS-CONT-ERRORES
           INITIALIZE WS-LINEA-DETALLE
           MOVE WS-ENT-CODIGO TO WRK-DET-CODIGO
           MOVE 'INVALIDO' TO WRK-DET-ACCION
           MOVE WS-MOTIVO-ERROR TO WRK-DET-MENSAJE
           MOVE WS-LINEA-DETALLE TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA.
      *
       REPORTAR-ERROR-SQL.
           ADD 1 TO WS-CONT-ERRORES
           INITIALIZE WS-LINEA-DETALLE
           MOVE HV-USU-CODIGO TO WRK-DET-CODIGO
           IF SQL-DUPLICATE
               MOVE 'EMAIL DUP' TO WRK-DET-ACCION
               MOVE 'EMAIL YA EXISTE PARA OTRO USUARIO'
                   TO WRK-DET-MENSAJE
           ELSE
               MOVE 'ERROR SQL' TO WRK-DET-ACCION
               MOVE WS-SQLCODE TO WS-SQLCODE-DISPLAY
               STRING 'SQLCODE ' WS-SQLCODE-DISPLAY
                   DELIMITED BY SIZE
                   INTO WRK-DET-MENSAJE
               END-STRING
           END-IF
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
           MOVE 'INSERTADOS:' TO WRK-TOTAL-TEXTO
           MOVE WS-CONT-INSERTADOS TO WRK-TOTAL-VALOR
           MOVE WS-LINEA-TOTAL TO WS-LINEA-REPORTE
           PERFORM EMITIR-LINEA
           INITIALIZE WS-LINEA-TOTAL
           MOVE 'ACTUALIZADOS:' TO WRK-TOTAL-TEXTO
           MOVE WS-CONT-ACTUALIZADOS TO WRK-TOTAL-VALOR
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
