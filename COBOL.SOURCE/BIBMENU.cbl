      ***************************************************************
      * PROGRAMA: BIBMENU - MENU PRINCIPAL CICS                   *
      * TRANSID : MENU                                            *
      * FUNCION : NAVEGA A CONSULTAS Y PRESTAMOS DEL SISTEMA      *
      ***************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BIBMENU.
       AUTHOR. ESTUDIANTE KC03G24.
       DATE-WRITTEN. 30/06/2026.
       DATE-COMPILED.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
       01 WS-COMMAREA.
           05 CA-PROGRAMA             PIC X(8) VALUE SPACES.
           05 FILLER                  PIC X(192) VALUE SPACES.
      *
       01 WS-CONSTANTES.
           05 WS-MAPSET               PIC X(8) VALUE 'BIBMENU'.
           05 WS-MAPA                 PIC X(8) VALUE 'BIBMENU'.
           05 WS-MSG-USUARIOS         PIC X(79)
              VALUE 'USUARIOS SE MANTIENE POR BATCH USUMANT'.
           05 WS-MSG-REPORTES         PIC X(79)
              VALUE 'REPORTES SE GENERA POR BATCH REPORTES'.
      *
           COPY DFHAID.
           COPY BIBMENU.
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
           EVALUATE TRUE
               WHEN EIBCALEN = ZERO
                   PERFORM PRIMERA-VEZ
               WHEN EIBAID = DFHPF3
                   PERFORM SALIR
               WHEN EIBAID = DFHPF12
                   PERFORM SALIR
               WHEN EIBAID = DFHCLEAR
                   PERFORM PRIMERA-VEZ
               WHEN OTHER
                   PERFORM PROCESAR-MENU
           END-EVALUATE.
      *
       PRIMERA-VEZ.
           MOVE 'BIBMENU' TO CA-PROGRAMA
           MOVE LOW-VALUES TO BIBMENUO
           MOVE '06' TO GRPNUMO
           MOVE 'SELECCIONE UNA OPCION Y PRESIONE ENTER'
               TO MENSAJEO
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.
      *
       PROCESAR-MENU.
           EXEC CICS RECEIVE MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                INTO(BIBMENUI)
           END-EXEC
           IF OPCIONI = LOW-VALUES
               MOVE SPACE TO OPCIONI
           END-IF
           MOVE 'BIBMENU' TO CA-PROGRAMA
           EVALUATE OPCIONI
               WHEN '1'
                   MOVE SPACES TO WS-COMMAREA
                   EXEC CICS XCTL PROGRAM('BIBCONS')
                        COMMAREA(WS-COMMAREA)
                        LENGTH(LENGTH OF WS-COMMAREA)
                   END-EXEC
               WHEN '2'
                   MOVE LOW-VALUES TO BIBMENUO
                   MOVE '06' TO GRPNUMO
                   MOVE WS-MSG-USUARIOS TO MENSAJEO
                   PERFORM ENVIAR-MAPA
                   PERFORM RETORNAR
               WHEN '3'
                   MOVE SPACES TO WS-COMMAREA
                   EXEC CICS XCTL PROGRAM('BIBPRES')
                        COMMAREA(WS-COMMAREA)
                        LENGTH(LENGTH OF WS-COMMAREA)
                   END-EXEC
               WHEN '4'
                   MOVE LOW-VALUES TO BIBMENUO
                   MOVE '06' TO GRPNUMO
                   MOVE WS-MSG-REPORTES TO MENSAJEO
                   PERFORM ENVIAR-MAPA
                   PERFORM RETORNAR
               WHEN 'X'
               WHEN 'x'
                   PERFORM SALIR
               WHEN OTHER
                   MOVE LOW-VALUES TO BIBMENUO
                   MOVE '06' TO GRPNUMO
                   MOVE 'OPCION NO VALIDA' TO MENSAJEO
                   PERFORM ENVIAR-MAPA
                   PERFORM RETORNAR
           END-EVALUATE.
      *
       ENVIAR-MAPA.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                FROM(BIBMENUO)
                ERASE
                CURSOR
           END-EXEC.
      *
       RETORNAR.
           EXEC CICS RETURN
                TRANSID('MENU')
                COMMAREA(WS-COMMAREA)
                LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.
      *
       SALIR.
           EXEC CICS RETURN END-EXEC.
