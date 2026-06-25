# CICS: introducción y desarrollo de pantallas

Universidad Nacional de La Matanza - DIIT  
Electiva I - Lenguaje Orientado a Negocios (COBOL)  
Trabajo Práctico Integrador Final 2026  
Material docente para clase teórico-práctica

Programas CICS a desarrollar:

```text
BIBMENU  Transacción MENU  Menú principal
BIBCONS  Transacción CONS  Consulta de libros
BIBPRES  Transacción PRES  Préstamos y devoluciones
```

---

## 1. Qué es CICS

**CICS** significa **Customer Information Control System**. Es el monitor de transacciones de IBM que corre sobre z/OS y permite construir aplicaciones interactivas en tiempo real.

Diferencia principal:

| Mundo batch | Mundo CICS |
|---|---|
| Un job procesa archivos sin esperar intervención humana. | El usuario interactúa con una terminal 3270. |
| Entrada típica: datasets. | Entrada típica: pantalla/mapa. |
| Salida típica: reporte o tabla actualizada. | Salida típica: pantalla actualizada. |
| El programa corre de inicio a fin. | El programa se activa por transacciones y puede ser pseudoconversacional. |

En el TP:

- Los programas batch (`CARGINI`, `USUMANT`, `PRESTAM`, `REPORTES`) cargan/procesan datos.
- Los programas CICS (`BIBMENU`, `BIBCONS`, `BIBPRES`) exponen operaciones interactivas al operador.

---

## 2. Conceptos clave

## 2.1 Transacción

Una transacción CICS es una unidad de trabajo iniciada escribiendo un código de 4 caracteres en la terminal.

Transacciones del TP:

| Transacción | Programa | Función |
|---|---|---|
| `MENU` | `BIBMENU` | Menú principal. |
| `CONS` | `BIBCONS` | Consulta de libros. |
| `PRES` | `BIBPRES` | Préstamos y devoluciones. |

La relación transacción-programa se define en CICS, normalmente en el CSD. En el entorno de práctica suele estar configurada por el administrador.

---

## 2.2 Mapas BMS

**BMS** significa **Basic Mapping Support**. Un mapa BMS define una pantalla 3270:

- Textos fijos.
- Campos de entrada.
- Campos de salida.
- Posiciones de fila/columna.
- Atributos: protegido, desprotegido, numérico, intensificado, etc.

Un mapa BMS se escribe con macros assembler y se compila separado del programa COBOL.

La compilación del mapa genera:

1. Un load module que CICS usa para pintar la pantalla.
2. Un copybook COBOL con los campos del mapa.

Regla fundamental:

Si en el mapa existe un campo llamado `OPCION`, el copybook genera campos como:

```text
OPCIONI  Input recibido desde pantalla
OPCIONO  Output enviado a pantalla
OPCIONA  Atributo del campo
```

El programa COBOL usa el copybook generado. No manipula el fuente BMS directamente.

---

## 2.3 Modelo pseudoconversacional

El modelo pseudoconversacional evita dejar un programa COBOL en memoria mientras el usuario piensa o escribe.

Ciclo:

```text
1. Usuario escribe MENU y presiona ENTER.
2. CICS ejecuta BIBMENU.
3. El programa muestra pantalla.
4. El programa termina con RETURN TRANSID('MENU') COMMAREA(...).
5. El programa sale de memoria.
6. El usuario completa la pantalla y presiona ENTER.
7. CICS ejecuta BIBMENU nuevamente.
8. El programa recupera estado desde COMMAREA.
9. Procesa y vuelve a hacer RETURN.
```

Punto crítico:

```text
WORKING-STORAGE se reinicia en cada ejecución.
COMMAREA es el único estado persistente entre ejecuciones.
```

Por eso:

- Siempre verificar `EIBCALEN` antes de leer `DFHCOMMAREA`.
- Si `EIBCALEN = 0`, es la primera ejecución.
- Si cambia la estructura de la COMMAREA, conviene limpiar/reiniciar la sesión CICS.

---

## 2.4 EIB - Execute Interface Block

El **EIB** es un área de datos que CICS mantiene para cada tarea. El programa COBOL puede leer sus campos.

Campos frecuentes:

| Campo | Uso |
|---|---|
| `EIBCALEN` | Longitud de COMMAREA recibida. Si es 0, no hay COMMAREA. |
| `EIBTRNID` | Código de transacción actual. |
| `EIBAID` | Tecla presionada: ENTER, PF1-PF24, CLEAR, PA1-PA3. |
| `EIBRESP` | Código de respuesta del último comando CICS. |
| `EIBTIME` | Hora actual en formato CICS. |
| `EIBDATE` | Fecha actual en formato CICS. |

---

## 2.5 Teclas de función y DFHAID

Las teclas se comparan contra constantes de `DFHAID`.

Ejemplo:

```cobol
           IF EIBAID = DFHPF3
               PERFORM VOLVER-AL-MENU
           END-IF.

           IF EIBAID = DFHCLEAR
               PERFORM LIMPIAR-PANTALLA
           END-IF.

           IF EIBAID = DFHENTER
               PERFORM PROCESAR-ENTRADA
           END-IF.
```

Convención sugerida:

| Tecla | Acción |
|---|---|
| `ENTER` | Procesar / confirmar. |
| `PF3` | Volver al menú anterior. |
| `PF12` | Salir del sistema. |
| `CLEAR` | Limpiar campos o terminar pantalla actual. |
| `PF7` | Página anterior. |
| `PF8` | Página siguiente. |

---

## 3. Mapas BMS

## 3.1 Estructura general

Un fuente BMS tiene tres niveles principales:

```asm
MAPSET  DFHMSD TYPE=&SYSPARM,MODE=INOUT,LANG=COBOL,...
MAPA    DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
CAMPO   DFHMDF POS=(fila,col),LENGTH=n,ATTRB=(...),INITIAL='texto'
        DFHMSD TYPE=FINAL
```

Macros:

| Macro | Uso |
|---|---|
| `DFHMSD` | Define mapset y cierre. |
| `DFHMDI` | Define un mapa/pantalla. |
| `DFHMDF` | Define texto fijo o campo. |

---

## 3.2 Atributos DFHMDF frecuentes

| Atributo | Significado |
|---|---|
| `PROT` | Campo protegido. El usuario no puede escribir. |
| `UNPROT` | Campo desprotegido. El usuario puede escribir. |
| `NUM` | Campo numérico. |
| `BRT` | Intensificado / bright. |
| `DRK` | Oscuro/no visible. Útil para passwords. |
| `IC` | Initial Cursor. Cursor inicial. |
| `FSET` | Fuerza modified data tag. |
| `(NORM,PROT)` | Texto normal protegido. |
| `(UNPROT,IC)` | Campo de entrada con foco. |

Regla práctica:

Todo campo `UNPROT` debería tener inmediatamente después un campo `PROT` de longitud 1, llamado comúnmente **stopper field**.

Si falta el stopper, el usuario puede escribir de más y avanzar sobre campos contiguos.

---

## 4. Mapa BIBMENU

Objetivo: menú principal del sistema.

Opciones:

```text
1 - Consulta de libros
2 - Préstamos y devoluciones
3 - Salir
```

Estructura recomendada:

```asm
BIBMENU DFHMSD TYPE=&SYSPARM,MODE=INOUT,LANG=COBOL,             X
               CTRL=FREEKB,STORAGE=AUTO,TIOAPFX=YES
BIBMENU DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
*
* CABECERA
        DFHMDF POS=(1,2),LENGTH=38,ATTRB=(NORM,PROT),           X
               INITIAL='SISTEMA DE BIBLIOTECA - U.N. LA MATANZA'
        DFHMDF POS=(1,60),LENGTH=8,ATTRB=(NORM,PROT),           X
               INITIAL='GRUPO: '
GRPNUM  DFHMDF POS=(1,68),LENGTH=2,ATTRB=(NORM,PROT)
*
* OPCIONES
        DFHMDF POS=(5,10),LENGTH=25,ATTRB=(BRT,PROT),           X
               INITIAL='MENU PRINCIPAL'
        DFHMDF POS=(8,15),LENGTH=30,ATTRB=(NORM,PROT),          X
               INITIAL='1 - CONSULTA DE LIBROS'
        DFHMDF POS=(9,15),LENGTH=30,ATTRB=(NORM,PROT),          X
               INITIAL='2 - PRESTAMOS Y DEVOLUCIONES'
        DFHMDF POS=(10,15),LENGTH=30,ATTRB=(NORM,PROT),         X
               INITIAL='3 - SALIR'
*
* ENTRADA
        DFHMDF POS=(22,1),LENGTH=15,ATTRB=(NORM,PROT),          X
               INITIAL='INGRESE OPCION:'
OPCION  DFHMDF POS=(22,17),LENGTH=1,ATTRB=(NORM,UNPROT,IC)
        DFHMDF POS=(22,19),LENGTH=1,ATTRB=(PROT)
*
MENSAJE DFHMDF POS=(24,1),LENGTH=79,ATTRB=(NORM,PROT)
        DFHMSD TYPE=FINAL
```

---

## 5. Mapa BIBCONS

Objetivo: consulta de libros por código o título, con resultados paginados.

Campos sugeridos:

- Código de libro.
- Título.
- Resultado: código, título, autor, stock.
- Mensaje.
- Controles: `PF3`, `ENTER`, `PF7`, `PF8`.

Estructura resumida:

```asm
BIBCONS DFHMSD TYPE=&SYSPARM,MODE=INOUT,LANG=COBOL,             X
               CTRL=FREEKB,STORAGE=AUTO,TIOAPFX=YES
BIBCONS DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
*
        DFHMDF POS=(1,2),LENGTH=38,ATTRB=(NORM,PROT),           X
               INITIAL='SISTEMA DE BIBLIOTECA - CONSULTA LIBROS'
*
        DFHMDF POS=(4,2),LENGTH=15,ATTRB=(NORM,PROT),           X
               INITIAL='CODIGO LIBRO:'
CODLIB  DFHMDF POS=(4,18),LENGTH=10,ATTRB=(NORM,UNPROT,IC)
        DFHMDF POS=(4,29),LENGTH=1,ATTRB=(PROT)
*
        DFHMDF POS=(5,2),LENGTH=15,ATTRB=(NORM,PROT),           X
               INITIAL='TITULO:'
TITULO  DFHMDF POS=(5,18),LENGTH=40,ATTRB=(NORM,UNPROT)
        DFHMDF POS=(5,59),LENGTH=1,ATTRB=(PROT)
*
        DFHMDF POS=(8,2),LENGTH=10,ATTRB=(BRT,PROT),            X
               INITIAL='CODIGO'
        DFHMDF POS=(8,14),LENGTH=40,ATTRB=(BRT,PROT),           X
               INITIAL='TITULO'
        DFHMDF POS=(8,56),LENGTH=10,ATTRB=(BRT,PROT),           X
               INITIAL='AUTOR'
        DFHMDF POS=(8,68),LENGTH=5,ATTRB=(BRT,PROT),            X
               INITIAL='STOCK'
*
RES1COD DFHMDF POS=(10,2),LENGTH=10,ATTRB=(NORM,PROT)
RES1TIT DFHMDF POS=(10,14),LENGTH=40,ATTRB=(NORM,PROT)
RES1AUT DFHMDF POS=(10,56),LENGTH=10,ATTRB=(NORM,PROT)
RES1STK DFHMDF POS=(10,68),LENGTH=3,ATTRB=(NORM,PROT)
*
* Repetir RES2..RES10 en filas 11..19
*
        DFHMDF POS=(21,2),LENGTH=50,ATTRB=(NORM,PROT),          X
               INITIAL='PF3=VOLVER ENTER=BUSCAR PF7=ANT PF8=SIG'
MENSAJE DFHMDF POS=(24,1),LENGTH=79,ATTRB=(NORM,PROT)
        DFHMSD TYPE=FINAL
```

---

## 6. Mapa BIBPRES

Objetivo: registrar préstamos y devoluciones mostrando datos del usuario y del libro.

Campos sugeridos:

- Operación: `P` préstamo, `D` devolución.
- Código de usuario.
- Nombre/tipo de usuario.
- Código de libro.
- Título/stock del libro.
- Número de préstamo.
- Fecha préstamo.
- Fecha límite.
- Mensaje.

Estructura resumida:

```asm
BIBPRES DFHMSD TYPE=&SYSPARM,MODE=INOUT,LANG=COBOL,             X
               CTRL=FREEKB,STORAGE=AUTO,TIOAPFX=YES
BIBPRES DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
*
        DFHMDF POS=(1,2),LENGTH=38,ATTRB=(NORM,PROT),           X
               INITIAL='SISTEMA BIBLIOTECA - PRESTAMOS'
*
        DFHMDF POS=(4,2),LENGTH=15,ATTRB=(NORM,PROT),           X
               INITIAL='OPERACION (P/D):'
TIPOP   DFHMDF POS=(4,18),LENGTH=1,ATTRB=(NORM,UNPROT,IC)
        DFHMDF POS=(4,20),LENGTH=1,ATTRB=(PROT)
*
        DFHMDF POS=(6,2),LENGTH=15,ATTRB=(NORM,PROT),           X
               INITIAL='COD. USUARIO:'
CODUSU  DFHMDF POS=(6,18),LENGTH=10,ATTRB=(NORM,UNPROT)
        DFHMDF POS=(6,29),LENGTH=1,ATTRB=(PROT)
NOMBUSU DFHMDF POS=(7,18),LENGTH=30,ATTRB=(NORM,PROT)
TIPOUSU DFHMDF POS=(7,50),LENGTH=20,ATTRB=(NORM,PROT)
*
        DFHMDF POS=(10,2),LENGTH=15,ATTRB=(NORM,PROT),          X
               INITIAL='COD. LIBRO:'
CODLIB  DFHMDF POS=(10,18),LENGTH=10,ATTRB=(NORM,UNPROT)
        DFHMDF POS=(10,29),LENGTH=1,ATTRB=(PROT)
TITULIB DFHMDF POS=(11,18),LENGTH=50,ATTRB=(NORM,PROT)
STOKLIB DFHMDF POS=(12,18),LENGTH=20,ATTRB=(NORM,PROT)
*
NUMPRES DFHMDF POS=(15,2),LENGTH=10,ATTRB=(NORM,PROT)
FECPRES DFHMDF POS=(15,15),LENGTH=10,ATTRB=(NORM,PROT)
FECLIM  DFHMDF POS=(15,28),LENGTH=10,ATTRB=(NORM,PROT)
*
        DFHMDF POS=(21,2),LENGTH=40,ATTRB=(NORM,PROT),          X
               INITIAL='PF3=VOLVER ENTER=CONFIRMAR PF12=SALIR'
MENSAJE DFHMDF POS=(24,1),LENGTH=79,ATTRB=(NORM,PROT)
        DFHMSD TYPE=FINAL
```

---

## 7. Estructura de un programa CICS

Un programa CICS pseudoconversacional no es totalmente lineal. Debe distinguir:

- Primera ejecución.
- Retorno desde pantalla.
- Tecla presionada.
- Estado guardado en COMMAREA.

Esquema:

```cobol
       PROCEDURE DIVISION.

       MAIN-PROGRAM.
           IF EIBCALEN > ZERO
               MOVE DFHCOMMAREA TO WS-COMMAREA
           END-IF

           EVALUATE TRUE
               WHEN EIBCALEN = ZERO
                   PERFORM PRIMERA-VEZ
               WHEN EIBAID = DFHPF3
                   PERFORM VOLVER
               WHEN EIBAID = DFHPF12
                   PERFORM SALIR
               WHEN OTHER
                   PERFORM PROCESAR-PANTALLA
           END-EVALUATE.
```

---

## 8. COMMAREA

La COMMAREA guarda el estado entre ejecuciones.

Definición en Working-Storage:

```cobol
       01 WS-COMMAREA.
          05 CA-PRIMERA-VEZ          PIC X VALUE 'S'.
             88 ES-PRIMERA-VEZ       VALUE 'S'.
             88 NO-ES-PRIMERA-VEZ    VALUE 'N'.
          05 CA-ESTADO               PIC X VALUE SPACE.
          05 CA-COD-USUARIO          PIC X(10) VALUE SPACES.
          05 FILLER                  PIC X(68) VALUE SPACES.
```

Definición en Linkage:

```cobol
       LINKAGE SECTION.
       01 DFHCOMMAREA                PIC X(80).
```

Uso en `RETURN`:

```cobol
           EXEC CICS RETURN
                TRANSID('MENU')
                COMMAREA(WS-COMMAREA)
                LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.
```

Reglas:

- `LENGTH` debe coincidir con la estructura real.
- Nunca leer `DFHCOMMAREA` si `EIBCALEN = 0`.
- Si cambia el layout de COMMAREA, limpiar sesión CICS antes de probar.

---

## 9. Comandos CICS esenciales

| Comando | Uso |
|---|---|
| `EXEC CICS SEND MAP` | Envía/muestra una pantalla. |
| `EXEC CICS RECEIVE MAP` | Recibe datos ingresados por el usuario. |
| `EXEC CICS RETURN TRANSID` | Termina ejecución y deja transacción para el próximo ENTER. |
| `EXEC CICS RETURN` | Termina la tarea sin volver a la transacción. |
| `EXEC CICS XCTL PROGRAM` | Transfiere control a otro programa sin retorno. |
| `EXEC CICS LINK PROGRAM` | Llama a otro programa y espera retorno. |
| `EXEC CICS HANDLE CONDITION` | Define manejo de condiciones CICS. |
| `EXEC CICS ASKTIME` | Obtiene hora/fecha CICS. |
| `EXEC CICS FORMATTIME` | Convierte hora/fecha a formato legible. |

Enviar mapa:

```cobol
       ENVIAR-MAPA.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                FROM(BIBMENUO)
                ERASE
                CURSOR
           END-EXEC.
```

Recibir mapa:

```cobol
       RECIBIR-MAPA.
           EXEC CICS RECEIVE MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                INTO(BIBMENUI)
           END-EXEC.
```

Navegar a otro programa:

```cobol
           EXEC CICS XCTL PROGRAM('BIBCONS')
                COMMAREA(WS-COMMAREA)
                LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.
```

---

## 10. Esqueleto de BIBMENU

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BIBMENU.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 WS-COMMAREA.
          05 CA-PRIMERA-VEZ          PIC X VALUE 'S'.
          05 CA-ESTADO               PIC X VALUE SPACE.
          05 FILLER                  PIC X(78).

       01 WS-CONSTANTES.
          05 WS-MAPSET               PIC X(8) VALUE 'BIBMENU'.
          05 WS-MAPA                 PIC X(8) VALUE 'BIBMENU'.

           COPY DFHAID.
           COPY BIBMENU.

       LINKAGE SECTION.
       01 DFHCOMMAREA                PIC X(80).

       PROCEDURE DIVISION.

       MAIN-PROGRAM.
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
               WHEN OTHER
                   PERFORM PROCESAR-MENU
           END-EVALUATE.

       PRIMERA-VEZ.
           MOVE 'N' TO CA-PRIMERA-VEZ
           MOVE LOW-VALUES TO BIBMENUO
           MOVE 'BIENVENIDO AL SISTEMA DE BIBLIOTECA'
               TO MENSAJEO
           PERFORM ENVIAR-MAPA
           PERFORM RETORNAR.

       PROCESAR-MENU.
           EXEC CICS RECEIVE MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                INTO(BIBMENUI)
           END-EXEC

           EVALUATE OPCIONI
               WHEN '1'
                   EXEC CICS XCTL PROGRAM('BIBCONS')
                        COMMAREA(WS-COMMAREA)
                        LENGTH(LENGTH OF WS-COMMAREA)
                   END-EXEC
               WHEN '2'
                   EXEC CICS XCTL PROGRAM('BIBPRES')
                        COMMAREA(WS-COMMAREA)
                        LENGTH(LENGTH OF WS-COMMAREA)
                   END-EXEC
               WHEN '3'
               WHEN 'X'
               WHEN 'x'
                   PERFORM SALIR
               WHEN OTHER
                   MOVE 'OPCION NO VALIDA' TO MENSAJEO
                   PERFORM ENVIAR-MAPA
                   PERFORM RETORNAR
           END-EVALUATE.

       ENVIAR-MAPA.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                FROM(BIBMENUO)
                ERASE
                CURSOR
           END-EXEC.

       RETORNAR.
           EXEC CICS RETURN
                TRANSID('MENU')
                COMMAREA(WS-COMMAREA)
                LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.

       SALIR.
           EXEC CICS RETURN END-EXEC.
```

---

## 11. Integración CICS con DB2

Un programa CICS puede ejecutar SQL embebido igual que un batch COBOL DB2:

```cobol
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.
```

En el entorno de práctica, los planes CICS suelen estar configurados por el administrador. Validar si el alumno debe o no bindear manualmente.

Ejemplo de consulta en `BIBCONS`:

```cobol
       BUSCAR-LIBRO.
           MOVE CODLIBI TO HV-COD-LIBRO
           EXEC SQL
               SELECT TITULO, AUTOR, STOCK_DISPONIBLE
                 INTO :HV-TITULO, :HV-AUTOR, :HV-STOCK
                 FROM KC03G24.LIBROS
                WHERE COD_LIBRO = :HV-COD-LIBRO
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   MOVE HV-TITULO TO TITULOO
                   MOVE HV-AUTOR  TO AUTORO
                   MOVE HV-STOCK  TO STOCKO
               WHEN +100
                   MOVE 'LIBRO NO ENCONTRADO' TO MENSAJEO
               WHEN OTHER
                   MOVE 'ERROR DE BASE DE DATOS' TO MENSAJEO
           END-EVALUATE.
```

Regla práctica:

- `SQLCODE 0`: éxito.
- `SQLCODE +100`: no encontrado; no es error fatal.
- `SQLCODE < 0`: error DB2.

---

## 12. Reglas de negocio para BIBPRES

El programa de préstamos/devoluciones debe respetar:

| Tipo usuario | Código | Máximo libros | Días préstamo |
|---|---|---:|---:|
| Estudiante | `E` | 3 | 15 |
| Docente | `D` | 10 | 30 |
| Administrativo | `A` | 5 | 20 |

Validaciones:

- No prestar si el usuario tiene préstamos vencidos.
- No prestar si `STOCK_DISPONIBLE = 0`.
- Calcular fecha límite automáticamente según tipo de usuario.
- En devolución, verificar que el préstamo exista.
- En devolución, verificar que el préstamo esté activo/pendiente.
- Actualizar stock disponible.
- Registrar multa si corresponde.

---

## 13. JCL de compilación CICS

Los nombres de datasets CICS dependen del entorno. Validar HLQ reales antes de usar.

## 13.1 Compilar mapa BMS

Ejemplo orientativo:

```jcl
//COMPBMS JOB (UNLAM),'COMPILAR MAPA BMS',CLASS=A,MSGCLASS=H,
//        NOTIFY=&SYSUID
//*
//SET1    SET MAPA=BIBMENU
//*
//JCLLIB  ORDER=(DFH610.CICS.ADFHPROC)
//STEP1   EXEC DFHMAPS,
//        INDEX='DFH610.CICS',
//        MAPLIB='KC02814.GRUPO6.LOAD.LIBRARY',
//        DSCTLIB='KC02814.GRUPO6.COBOL.COPYLIB',
//        MAPNAME=&MAPA
//COPY.SYSUT1 DD DSN=KC02814.GRUPO6.BMS.SOURCE(&MAPA),DISP=SHR
//LINKMAP.SYSLMOD DD DSN=KC02814.GRUPO6.LOAD.LIBRARY(&MAPA),
//        DISP=SHR
```

Resultado esperado:

- Load module del mapa en `LOAD.LIBRARY`.
- Copybook del mapa en `COBOL.COPYLIB`.

## 13.2 Compilar COBOL + CICS + DB2

Ejemplo orientativo:

```jcl
//COMPCICS JOB (UNLAM),'COBOL+CICS+DB2',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID
//*
//SET1     SET PROG=BIBMENU
//*
//COMPILE  EXEC IGYWCL,
//         PARM.COBOL='CICS,SQL,RENT,OBJECT'
//COBOL.STEPLIB DD DSN=IGY640.SIGYCOMP,DISP=SHR
//              DD DSN=DFH610.CICS.SDFHLOAD,DISP=SHR
//              DD DSN=DSND10.SDSNLOAD,DISP=SHR
//              DD DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//COBOL.SYSLIB  DD DSN=KC02814.GRUPO6.COBOL.COPYLIB,DISP=SHR
//              DD DSN=DFH610.CICS.SDFHCOB,DISP=SHR
//COBOL.SYSIN   DD DSN=KC02814.GRUPO6.COBOL.SOURCE(&PROG),
//              DISP=SHR
//COBOL.DBRMLIB DD DSN=KC02814.GRUPO6.DBRM(&PROG),DISP=SHR
//LKED.SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//              DD DSN=DFH610.CICS.SDFHLOAD,DISP=SHR
//              DD DSN=DSND10.SDSNLOAD,DISP=SHR
//LKED.SYSLMOD  DD DSN=KC02814.GRUPO6.LOAD.LIBRARY(&PROG),
//              DISP=SHR
//LKED.SYSPRINT DD SYSOUT=*
```

Notas:

- `CICS` activa el coprocesador CICS.
- `SQL` activa soporte de SQL embebido.
- `RENT` es importante para programas reentrantes.
- Puede haber RC=4 no fatal dependiendo del entorno.
- Confirmar con el administrador si se necesita bind separado para CICS.

---

## 14. Errores comunes

| Error / síntoma | Causa probable | Acción |
|---|---|---|
| `ASRA` | Storage violation, acceso inválido, COMMAREA mal usada | Revisar `EIBCALEN`, tamaños y moves |
| `AEI9` | Programa no encontrado | Verificar `PROGRAM-ID`, `XCTL/LINK`, load library |
| `MAPFAIL` | `RECEIVE MAP` sin datos, CLEAR o PA | Manejar condición antes de procesar |
| `NOTFND` | Registro no encontrado en comando CICS | Manejar condición o revisar `EIBRESP` |
| Pantalla en blanco tras `RETURN` | Falta `TRANSID` | Usar `RETURN TRANSID(...)` si debe continuar |
| `LOW-VALUES` en campo de entrada | Campo no modificado por usuario | Validar antes de usar |
| Campo de entrada se extiende de más | Falta stopper field | Agregar campo `PROT` de longitud 1 |
| COMMAREA corrupta | Tamaño/layout no coincide o sesión vieja | Limpiar sesión y revisar `LENGTH` |
| SQL `-818` | Timestamp mismatch DBRM/plan | Recompilar y rebindear |
| SQL `-811` | `SELECT INTO` devuelve varias filas | Ajustar `WHERE` o usar cursor |

---

## 15. Diagnóstico con CEDF

`CEDF` es el debugger nativo de CICS.

Uso:

1. Escribir `CEDF` en la terminal y presionar ENTER.
2. Ejecutar la transacción a depurar, por ejemplo `MENU`.
3. CEDF intercepta cada `EXEC CICS`.
4. Revisar campos, COMMAREA, condiciones y respuestas.

CEDF sirve para verificar:

- Si `RECEIVE MAP` trae datos.
- Valores de campos con sufijo `I`.
- Contenido de COMMAREA.
- Código de respuesta de comandos CICS.
- Flujo entre `SEND`, `RECEIVE`, `XCTL` y `RETURN`.

Confirmar con el administrador si CEDF está habilitado para el usuario.

---

## 16. Orden de desarrollo sugerido

Para cada programa CICS:

1. Diseñar la pantalla en papel.
2. Definir campos, posiciones y teclas.
3. Escribir fuente BMS en `BMS.SOURCE`.
4. Compilar mapa con JCL de BMS.
5. Verificar que se genere copybook del mapa.
6. Revisar nombres generados con sufijos `I`, `O`, `A`.
7. Escribir programa COBOL CICS.
8. Compilar COBOL CICS.
9. Instalar/refresh del programa en CICS si corresponde.
10. Ejecutar transacción.
11. Depurar con CEDF.
12. Documentar pruebas.

---

## 17. Checklist por programa CICS

## 17.1 Mapa BMS

- [ ] Pantalla 24x80 definida.
- [ ] Campo `MENSAJE` definido.
- [ ] Cada campo `UNPROT` tiene stopper `PROT`.
- [ ] Campos de entrada tienen longitud correcta.
- [ ] Atributos `PROT`, `UNPROT`, `IC`, `BRT` usados correctamente.
- [ ] Mapa compila y genera copybook.

## 17.2 COBOL CICS

- [ ] Incluye `COPY DFHAID`.
- [ ] Incluye copybook del mapa.
- [ ] Define `WS-COMMAREA`.
- [ ] Define `DFHCOMMAREA` en `LINKAGE SECTION`.
- [ ] Verifica `EIBCALEN` antes de leer `DFHCOMMAREA`.
- [ ] Maneja `ENTER`, `PF3`, `PF12`, `CLEAR`.
- [ ] Maneja `MAPFAIL`.
- [ ] Valida `LOW-VALUES` en campos de entrada.
- [ ] Usa `SEND MAP` y `RECEIVE MAP` correctamente.
- [ ] Usa `RETURN TRANSID` con `COMMAREA` y `LENGTH`.

## 17.3 DB2

- [ ] Incluye `SQLCA`.
- [ ] Declara host variables.
- [ ] Maneja `SQLCODE 0`.
- [ ] Maneja `SQLCODE +100`.
- [ ] Maneja `SQLCODE < 0`.
- [ ] SQL embebido usa columnas reales del DDL.
- [ ] Plan/paquete CICS validado con el administrador.

---

## 18. Diez reglas para no olvidar

1. `WORKING-STORAGE` se reinicia en cada ejecución.
2. La COMMAREA es el estado persistente.
3. Verificar `EIBCALEN` antes de leer `DFHCOMMAREA`.
4. Todo campo `UNPROT` necesita stopper `PROT`.
5. `RETURN` debe llevar `TRANSID` si se espera continuar la conversación.
6. Manejar `MAPFAIL`.
7. Validar `LOW-VALUES` antes de usar campos de entrada.
8. Leer campos con sufijo `I` y escribir campos con sufijo `O`.
9. Para navegar usar `XCTL` sin retorno o `LINK` con retorno.
10. Usar CEDF durante el desarrollo.

---

## 19. Relación con el sistema de biblioteca

| Programa | Rol en el TP |
|---|---|
| `BIBMENU` | Entrada principal al sistema. |
| `BIBCONS` | Consulta interactiva de libros. |
| `BIBPRES` | Préstamos y devoluciones. |

Relación con DB2:

- `BIBCONS` consulta `KC03G24.LIBROS`.
- `BIBPRES` consulta `KC03G24.USUARIOS`, `KC03G24.LIBROS`, `KC03G24.PRESTAMOS`.
- `BIBPRES` actualiza stock y estado de préstamos.

Relación con batch:

- `CARGINI` carga libros.
- `USUMANT` carga/actualiza usuarios.
- `PRESTAM` puede procesar préstamos batch.
- CICS opera sobre las mismas tablas actualizadas por batch.
