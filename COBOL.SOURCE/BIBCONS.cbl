      ***************************************************************
      * PROGRAMA: BIBCONS - CONSULTA DE LIBROS CICS/DB2           *
      * TRANSID : CONS                                            *
      * FUNCION : BUSQUEDA POR CODIGO, TITULO, AUTOR O CATEGORIA *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BIBCONS.
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
       01 HV-BUSQUEDA.
           05 HV-MODO                 PIC X(1).
           05 HV-EST-ACTIVO           PIC X(1).
           05 HV-COD-LIBRO            PIC X(10).
           05 HV-TIT-LIKE.
              10 HV-TIT-LEN           PIC S9(4) COMP.
              10 HV-TIT-TEXT          PIC X(41).
           05 HV-AUT-LIKE.
              10 HV-AUT-LEN           PIC S9(4) COMP.
              10 HV-AUT-TEXT          PIC X(31).
           05 HV-CAT-LIKE.
              10 HV-CAT-LEN           PIC S9(4) COMP.
              10 HV-CAT-TEXT          PIC X(18).
       01 HV-RESULTADO.
           05 HV-RES-COD              PIC X(10).
           05 HV-RES-TIT              PIC X(60).
           05 HV-RES-AUT              PIC X(40).
           05 HV-RES-STK              PIC S9(9) COMP.
      *
           EXEC SQL END DECLARE SECTION END-EXEC.
      *
       01 WS-COMMAREA.
           05 CA-PROGRAMA             PIC X(8) VALUE SPACES.
           05 CA-OFFSET               PIC S9(4) COMP VALUE ZERO.
           05 CA-HAY-SIG              PIC X(1) VALUE 'N'.
           05 CA-COD-LIBRO            PIC X(10) VALUE SPACES.
           05 CA-TITULO               PIC X(40) VALUE SPACES.
           05 CA-AUTOR                PIC X(30) VALUE SPACES.
           05 CA-CATEGORIA            PIC X(17) VALUE SPACES.
           05 FILLER                  PIC X(92) VALUE SPACES.
      *
       01 WS-CONSTANTES.
           05 WS-MAPSET               PIC X(8) VALUE 'BIBCONS'.
           05 WS-MAPA                 PIC X(8) VALUE 'BIBCONS'.
           05 WS-FILAS-PAGINA         PIC S9(4) COMP VALUE 8.
      *
       01 WS-CONTROL.
           05 WS-SQLCODE              PIC S9(9) COMP VALUE ZERO.
              88 SQL-OK               VALUE 0.
              88 SQL-NOT-FOUND        VALUE 100.
           05 WS-SQLCODE-DISPLAY      PIC -ZZZZZZZZ9.
           05 WS-I                    PIC S9(4) COMP VALUE ZERO.
           05 WS-FILA                 PIC S9(4) COMP VALUE ZERO.
           05 WS-LEN                  PIC S9(4) COMP VALUE ZERO.
           05 WS-CANT-MOSTRADA        PIC S9(4) COMP VALUE ZERO.
           05 WS-STOCK-DISPLAY        PIC ZZZZ9.
      *
           COPY DFHAID.
           COPY BIBCONS.
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
           IF CA-PROGRAMA NOT = 'BIBCONS'
               PERFORM PRIMERA-VEZ
           END-IF
           EVALUATE EIBAID
               WHEN DFHPF3
                   PERFORM VOLVER-MENU
               WHEN DFHPF12
                   PERFORM SALIR
               WHEN DFHCLEAR
                   PERFORM PRIMERA-VEZ
               WHEN DFHPF7
                   PERFORM PAGINA-ANTERIOR
               WHEN DFHPF8
                   PERFORM PAGINA-SIGUIENTE
               WHEN DFHENTER
                   PERFORM NUEVA-BUSQUEDA
               WHEN OTHER
                   PERFORM ENVIAR-ACTUAL
           END-EVALUATE.
      *
       PRIMERA-VEZ.
           INITIALIZE WS-COMMAREA
           MOVE 'BIBCONS' TO CA-PROGRAMA
           MOVE LOW-VALUES TO BIBCONSO
           MOVE 'INGRESE CRITERIO DE BUSQUEDA'
               TO MENSAJEO
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.
      *
       NUEVA-BUSQUEDA.
           EXEC CICS RECEIVE MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                INTO(BIBCONSI)
           END-EXEC
           PERFORM NORMALIZAR-ENTRADA
           MOVE ZERO TO CA-OFFSET
           MOVE CODLIBI TO CA-COD-LIBRO
           MOVE TITULOI TO CA-TITULO
           MOVE AUTORI  TO CA-AUTOR
           MOVE CATEGOI TO CA-CATEGORIA
           PERFORM BUSCAR-Y-ENVIAR.
      *
       PAGINA-ANTERIOR.
           IF CA-OFFSET > ZERO
               SUBTRACT WS-FILAS-PAGINA FROM CA-OFFSET
               IF CA-OFFSET < ZERO
                   MOVE ZERO TO CA-OFFSET
               END-IF
               PERFORM BUSCAR-Y-ENVIAR
           ELSE
               MOVE LOW-VALUES TO BIBCONSO
               PERFORM MOVER-CRITERIOS-PANTALLA
               MOVE 'YA ESTA EN LA PRIMERA PAGINA' TO MENSAJEO
               PERFORM ENVIAR-MAPA
               PERFORM RETORNAR
           END-IF.
      *
       PAGINA-SIGUIENTE.
           IF CA-HAY-SIG = 'S'
               ADD WS-FILAS-PAGINA TO CA-OFFSET
               PERFORM BUSCAR-Y-ENVIAR
           ELSE
               MOVE LOW-VALUES TO BIBCONSO
               PERFORM MOVER-CRITERIOS-PANTALLA
               MOVE 'NO HAY MAS RESULTADOS' TO MENSAJEO
               PERFORM ENVIAR-MAPA
               PERFORM RETORNAR
           END-IF.
      *
       ENVIAR-ACTUAL.
           MOVE LOW-VALUES TO BIBCONSO
           PERFORM MOVER-CRITERIOS-PANTALLA
           MOVE 'USE ENTER PARA BUSCAR, PF3 PARA MENU'
               TO MENSAJEO
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.
      *
       NORMALIZAR-ENTRADA.
           IF CODLIBI = LOW-VALUES
               MOVE SPACES TO CODLIBI
           END-IF
           IF TITULOI = LOW-VALUES
               MOVE SPACES TO TITULOI
           END-IF
           IF AUTORI = LOW-VALUES
               MOVE SPACES TO AUTORI
           END-IF
           IF CATEGOI = LOW-VALUES
               MOVE SPACES TO CATEGOI
           END-IF.
      *
       BUSCAR-Y-ENVIAR.
           MOVE LOW-VALUES TO BIBCONSO
           PERFORM MOVER-CRITERIOS-PANTALLA
           PERFORM PREPARAR-HOST-VARS
           PERFORM LIMPIAR-RESULTADOS
           PERFORM ABRIR-CURSOR
           IF NOT SQL-OK
               PERFORM MENSAJE-ERROR-SQL
               PERFORM ENVIAR-MAPA
               PERFORM RETORNAR
           END-IF
           PERFORM SALTEAR-FILAS
           IF SQL-OK
               PERFORM CARGAR-FILAS
           END-IF
           PERFORM CERRAR-CURSOR
           IF WS-CANT-MOSTRADA = ZERO
               MOVE 'NO SE ENCONTRARON LIBROS' TO MENSAJEO
           ELSE
               MOVE 'RESULTADOS DE CONSULTA' TO MENSAJEO
           END-IF
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.
      *
       PREPARAR-HOST-VARS.
           MOVE 'A' TO HV-EST-ACTIVO
           MOVE CA-COD-LIBRO TO HV-COD-LIBRO
           IF CA-COD-LIBRO NOT = SPACES
               MOVE 'C' TO HV-MODO
           ELSE
               IF CA-TITULO NOT = SPACES
                   MOVE 'T' TO HV-MODO
               ELSE
                   IF CA-AUTOR NOT = SPACES
                       MOVE 'A' TO HV-MODO
                   ELSE
                       IF CA-CATEGORIA NOT = SPACES
                           MOVE 'G' TO HV-MODO
                       ELSE
                           MOVE 'L' TO HV-MODO
                       END-IF
                   END-IF
               END-IF
           END-IF
           PERFORM ARMAR-LIKE-TITULO
           PERFORM ARMAR-LIKE-AUTOR
           PERFORM ARMAR-LIKE-CATEGORIA.
      *
       ARMAR-LIKE-TITULO.
           MOVE SPACES TO HV-TIT-TEXT
           MOVE FUNCTION TRIM(CA-TITULO) TO HV-TIT-TEXT
           COMPUTE WS-LEN =
               FUNCTION LENGTH(FUNCTION TRIM(CA-TITULO))
           COMPUTE HV-TIT-LEN = WS-LEN + 1
           IF HV-TIT-LEN > 1
               MOVE '%' TO HV-TIT-TEXT(HV-TIT-LEN:1)
           END-IF.
      *
       ARMAR-LIKE-AUTOR.
           MOVE SPACES TO HV-AUT-TEXT
           MOVE FUNCTION TRIM(CA-AUTOR) TO HV-AUT-TEXT
           COMPUTE WS-LEN =
               FUNCTION LENGTH(FUNCTION TRIM(CA-AUTOR))
           COMPUTE HV-AUT-LEN = WS-LEN + 1
           IF HV-AUT-LEN > 1
               MOVE '%' TO HV-AUT-TEXT(HV-AUT-LEN:1)
           END-IF.
      *
       ARMAR-LIKE-CATEGORIA.
           MOVE SPACES TO HV-CAT-TEXT
           MOVE FUNCTION TRIM(CA-CATEGORIA) TO HV-CAT-TEXT
           COMPUTE WS-LEN =
               FUNCTION LENGTH(FUNCTION TRIM(CA-CATEGORIA))
           COMPUTE HV-CAT-LEN = WS-LEN + 1
           IF HV-CAT-LEN > 1
               MOVE '%' TO HV-CAT-TEXT(HV-CAT-LEN:1)
           END-IF.
      *
       ABRIR-CURSOR.
           EXEC SQL
               DECLARE CUR-LIBROS CURSOR FOR
                SELECT COD_LIBRO, TITULO, AUTOR, STOCK_DISPONIBLE
                  FROM KC03G24.LIBROS
                 WHERE ESTADO = :HV-EST-ACTIVO
                   AND (:HV-MODO = 'L'
                    OR (:HV-MODO = 'C'
                   AND COD_LIBRO = :HV-COD-LIBRO)
                    OR (:HV-MODO = 'T'
                   AND TITULO LIKE :HV-TIT-LIKE)
                    OR (:HV-MODO = 'A'
                   AND AUTOR LIKE :HV-AUT-LIKE)
                    OR (:HV-MODO = 'G'
                   AND CATEGORIA LIKE :HV-CAT-LIKE))
                 ORDER BY COD_LIBRO
           END-EXEC
           EXEC SQL
               OPEN CUR-LIBROS
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       SALTEAR-FILAS.
           MOVE ZERO TO WS-I
           PERFORM UNTIL WS-I >= CA-OFFSET
              OR NOT SQL-OK
               PERFORM FETCH-LIBRO
               IF SQL-OK
                   ADD 1 TO WS-I
               END-IF
           END-PERFORM.
      *
       CARGAR-FILAS.
           MOVE ZERO TO WS-FILA
           MOVE ZERO TO WS-CANT-MOSTRADA
           MOVE 'N' TO CA-HAY-SIG
           PERFORM UNTIL WS-FILA >= WS-FILAS-PAGINA
              OR NOT SQL-OK
               PERFORM FETCH-LIBRO
               IF SQL-OK
                   ADD 1 TO WS-FILA
                   ADD 1 TO WS-CANT-MOSTRADA
                   PERFORM MOVER-FILA
               END-IF
           END-PERFORM
           IF SQL-OK
               PERFORM FETCH-LIBRO
               IF SQL-OK
                   MOVE 'S' TO CA-HAY-SIG
               END-IF
           END-IF.
      *
       FETCH-LIBRO.
           EXEC SQL
               FETCH CUR-LIBROS
                INTO :HV-RES-COD, :HV-RES-TIT,
                     :HV-RES-AUT, :HV-RES-STK
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE.
      *
       CERRAR-CURSOR.
           EXEC SQL
               CLOSE CUR-LIBROS
           END-EXEC.
      *
       MOVER-FILA.
           MOVE HV-RES-STK TO WS-STOCK-DISPLAY
           EVALUATE WS-FILA
               WHEN 1
                   MOVE HV-RES-COD TO RES1CODO
                   MOVE HV-RES-TIT(1:32) TO RES1TITO
                   MOVE HV-RES-AUT(1:20) TO RES1AUTO
                   MOVE WS-STOCK-DISPLAY TO RES1STKO
               WHEN 2
                   MOVE HV-RES-COD TO RES2CODO
                   MOVE HV-RES-TIT(1:32) TO RES2TITO
                   MOVE HV-RES-AUT(1:20) TO RES2AUTO
                   MOVE WS-STOCK-DISPLAY TO RES2STKO
               WHEN 3
                   MOVE HV-RES-COD TO RES3CODO
                   MOVE HV-RES-TIT(1:32) TO RES3TITO
                   MOVE HV-RES-AUT(1:20) TO RES3AUTO
                   MOVE WS-STOCK-DISPLAY TO RES3STKO
               WHEN 4
                   MOVE HV-RES-COD TO RES4CODO
                   MOVE HV-RES-TIT(1:32) TO RES4TITO
                   MOVE HV-RES-AUT(1:20) TO RES4AUTO
                   MOVE WS-STOCK-DISPLAY TO RES4STKO
               WHEN 5
                   MOVE HV-RES-COD TO RES5CODO
                   MOVE HV-RES-TIT(1:32) TO RES5TITO
                   MOVE HV-RES-AUT(1:20) TO RES5AUTO
                   MOVE WS-STOCK-DISPLAY TO RES5STKO
               WHEN 6
                   MOVE HV-RES-COD TO RES6CODO
                   MOVE HV-RES-TIT(1:32) TO RES6TITO
                   MOVE HV-RES-AUT(1:20) TO RES6AUTO
                   MOVE WS-STOCK-DISPLAY TO RES6STKO
               WHEN 7
                   MOVE HV-RES-COD TO RES7CODO
                   MOVE HV-RES-TIT(1:32) TO RES7TITO
                   MOVE HV-RES-AUT(1:20) TO RES7AUTO
                   MOVE WS-STOCK-DISPLAY TO RES7STKO
               WHEN 8
                   MOVE HV-RES-COD TO RES8CODO
                   MOVE HV-RES-TIT(1:32) TO RES8TITO
                   MOVE HV-RES-AUT(1:20) TO RES8AUTO
                   MOVE WS-STOCK-DISPLAY TO RES8STKO
           END-EVALUATE.
      *
       LIMPIAR-RESULTADOS.
           MOVE SPACES TO RES1CODO RES1TITO RES1AUTO RES1STKO
           MOVE SPACES TO RES2CODO RES2TITO RES2AUTO RES2STKO
           MOVE SPACES TO RES3CODO RES3TITO RES3AUTO RES3STKO
           MOVE SPACES TO RES4CODO RES4TITO RES4AUTO RES4STKO
           MOVE SPACES TO RES5CODO RES5TITO RES5AUTO RES5STKO
           MOVE SPACES TO RES6CODO RES6TITO RES6AUTO RES6STKO
           MOVE SPACES TO RES7CODO RES7TITO RES7AUTO RES7STKO
           MOVE SPACES TO RES8CODO RES8TITO RES8AUTO RES8STKO.
      *
       MOVER-CRITERIOS-PANTALLA.
           MOVE CA-COD-LIBRO TO CODLIBO
           MOVE CA-TITULO TO TITULOO
           MOVE CA-AUTOR TO AUTORO
           MOVE CA-CATEGORIA TO CATEGOO.
      *
       MENSAJE-ERROR-SQL.
           MOVE WS-SQLCODE TO WS-SQLCODE-DISPLAY
           STRING 'ERROR DB2 SQLCODE ' WS-SQLCODE-DISPLAY
               DELIMITED BY SIZE
               INTO MENSAJEO
           END-STRING.
      *
       ENVIAR-MAPA.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                FROM(BIBCONSO)
                ERASE
                CURSOR
           END-EXEC.
      *
       RETORNAR.
           EXEC CICS RETURN
                TRANSID('CONS')
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
