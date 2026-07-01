# Prueba de programas CICS

Esta guia cubre la carga y prueba de los programas CICS del sistema de
biblioteca usando Zowe para transferir archivos al mainframe y un emulador
3270 para ejecutar las transacciones.

## Artefactos CICS

Programas COBOL:

- `COBOL.SOURCE/BIBMENU.cbl`: transaccion `MENU`.
- `COBOL.SOURCE/BIBCONS.cbl`: transaccion `CONS`.
- `COBOL.SOURCE/BIBPRES.cbl`: transaccion `PRES`.

Mapas BMS:

- `BMS.SOURCE/BIBMENU.bms`.
- `BMS.SOURCE/BIBCONS.bms`.
- `BMS.SOURCE/BIBPRES.bms`.

JCL:

- `JCL.SOURCE/CICSMAP.jcl`: compila un mapa BMS.
- `JCL.SOURCE/CICSPGM.jcl`: compila un programa COBOL CICS/DB2.
- `JCL.SOURCE/CICSBIND.jcl`: bind de `BIBCONS` y `BIBPRES`.

## Prerrequisitos

- Tablas DB2 creadas con `JCL.SOURCE/RUNSQL.jcl`.
- Datos cargados en `KC03G24.USUARIOS` y `KC03G24.LIBROS`.
- PDS existentes:
  - `KC02814.GRUPO6.COBOL.SOURCE`
  - `KC02814.GRUPO6.COBOL.COPYLIB`
  - `KC02814.GRUPO6.BMS.SOURCE`
  - `KC02814.GRUPO6.JCL.SOURCE`
  - `KC02814.GRUPO6.DBRM`
  - `KC02814.GRUPO6.LOAD.LIBRARY`
- Acceso a CICS con las transacciones definidas o permiso para pedir su
  definicion al administrador.

## 1. Subir fuentes con Zowe

Desde la raiz del repo:

```bash
zowe files upload file-to-data-set "BMS.SOURCE/BIBMENU.bms" \
  "KC02814.GRUPO6.BMS.SOURCE(BIBMENU)"
zowe files upload file-to-data-set "BMS.SOURCE/BIBCONS.bms" \
  "KC02814.GRUPO6.BMS.SOURCE(BIBCONS)"
zowe files upload file-to-data-set "BMS.SOURCE/BIBPRES.bms" \
  "KC02814.GRUPO6.BMS.SOURCE(BIBPRES)"

zowe files upload file-to-data-set "COBOL.SOURCE/BIBMENU.cbl" \
  "KC02814.GRUPO6.COBOL.SOURCE(BIBMENU)"
zowe files upload file-to-data-set "COBOL.SOURCE/BIBCONS.cbl" \
  "KC02814.GRUPO6.COBOL.SOURCE(BIBCONS)"
zowe files upload file-to-data-set "COBOL.SOURCE/BIBPRES.cbl" \
  "KC02814.GRUPO6.COBOL.SOURCE(BIBPRES)"

zowe files upload file-to-data-set "JCL.SOURCE/CICSMAP.jcl" \
  "KC02814.GRUPO6.JCL.SOURCE(CICSMAP)"
zowe files upload file-to-data-set "JCL.SOURCE/CICSPGM.jcl" \
  "KC02814.GRUPO6.JCL.SOURCE(CICSPGM)"
zowe files upload file-to-data-set "JCL.SOURCE/CICSBIND.jcl" \
  "KC02814.GRUPO6.JCL.SOURCE(CICSBIND)"
```

## 2. Compilar mapas BMS

Editar `KC02814.GRUPO6.JCL.SOURCE(CICSMAP)` y cambiar:

```jcl
//SETMAP   SET MAPA=BIBMENU
```

Ejecutar una vez por cada mapa: `BIBMENU`, `BIBCONS`, `BIBPRES`.

```bash
zowe jobs submit data-set "KC02814.GRUPO6.JCL.SOURCE(CICSMAP)" \
  --wait-for-output
```

El resultado esperado es:

- Load module del mapset en `KC02814.GRUPO6.LOAD.LIBRARY`.
- Copybook COBOL generado en `KC02814.GRUPO6.COBOL.COPYLIB`.

## 3. Compilar programas COBOL CICS

Editar `KC02814.GRUPO6.JCL.SOURCE(CICSPGM)` y cambiar:

```jcl
//SETPROG  SET PROG=BIBCONS
```

Ejecutar una vez por cada programa: `BIBMENU`, `BIBCONS`, `BIBPRES`.

```bash
zowe jobs submit data-set "KC02814.GRUPO6.JCL.SOURCE(CICSPGM)" \
  --wait-for-output
```

Notas:

- `BIBMENU` no usa DB2, pero se puede compilar con la misma plantilla si el
  entorno acepta `PARM.COBOL='CICS,SQL,RENT,OBJECT'`.
- Si el entorno genera error por no haber DBRM en `BIBMENU`, compilarlo con
  `PARM.COBOL='CICS,RENT,OBJECT'` y sin `COBOL.DBRMLIB`.
- `BIBCONS` y `BIBPRES` usan SQL embebido y generan DBRM.

## 4. Bind DB2

Ejecutar:

```bash
zowe jobs submit data-set "KC02814.GRUPO6.JCL.SOURCE(CICSBIND)" \
  --wait-for-output
```

El JCL usa `PLAN(CURSOG06)`. Si CICS esta configurado para otro plan, por
ejemplo `GRUPO6`, cambiar el nombre antes de ejecutar.

## 5. Definir o refrescar recursos CICS

Si las transacciones no existen, pedir al administrador o ejecutar desde CEDA
con el grupo que corresponda al entorno:

```text
CEDA DEFINE PROGRAM(BIBMENU) GROUP(GRUPO6) LANGUAGE(COBOL)
CEDA DEFINE PROGRAM(BIBCONS) GROUP(GRUPO6) LANGUAGE(COBOL)
CEDA DEFINE PROGRAM(BIBPRES) GROUP(GRUPO6) LANGUAGE(COBOL)

CEDA DEFINE MAPSET(BIBMENU) GROUP(GRUPO6)
CEDA DEFINE MAPSET(BIBCONS) GROUP(GRUPO6)
CEDA DEFINE MAPSET(BIBPRES) GROUP(GRUPO6)

CEDA DEFINE TRANSACTION(MENU) GROUP(GRUPO6) PROGRAM(BIBMENU)
CEDA DEFINE TRANSACTION(CONS) GROUP(GRUPO6) PROGRAM(BIBCONS)
CEDA DEFINE TRANSACTION(PRES) GROUP(GRUPO6) PROGRAM(BIBPRES)

CEDA INSTALL GROUP(GRUPO6)
```

Si ya existian y se recompilo:

```text
CEMT SET PROGRAM(BIBMENU) NEWCOPY
CEMT SET PROGRAM(BIBCONS) NEWCOPY
CEMT SET PROGRAM(BIBPRES) NEWCOPY
CEMT SET PROGRAM(BIBMENU) PHASEIN
CEMT SET PROGRAM(BIBCONS) PHASEIN
CEMT SET PROGRAM(BIBPRES) PHASEIN
```

## 6. Probar desde emulador 3270

Ingresar a la region CICS y escribir:

```text
MENU
```

Pruebas minimas:

1. Menu principal:
   - `1` navega a consulta de libros.
   - `3` navega a prestamos/devoluciones.
   - `2` informa que usuarios se mantiene por batch `USUMANT`.
   - `4` informa que reportes se genera por batch `REPORTES`.
   - `X` o `PF12` sale.

2. Consulta de libros:
   - Buscar por `COD. LIBRO`.
   - Buscar por `TITULO`.
   - Buscar por `AUTOR`.
   - Buscar por `CATEGORIA`.
   - Usar `PF8` para pagina siguiente y `PF7` para anterior.
   - `PF3` vuelve al menu.

3. Prestamo:
   - Operacion `P`.
   - Informar `COD. USUARIO` activo.
   - Informar `COD. LIBRO` activo con stock disponible.
   - Confirmar con `ENTER`.
   - Verificar mensaje `PRESTAMO REGISTRADO CORRECTAMENTE`.
   - Validar en DB2 que se inserto una fila en `KC03G24.PRESTAMOS` y bajo
     `STOCK_DISPONIBLE`.

4. Devolucion:
   - Operacion `D`.
   - Informar `NRO. PRESTAMO`.
   - Confirmar con `ENTER`.
   - Verificar mensaje `DEVOLUCION REGISTRADA CORRECTAMENTE`.
   - Validar que `FECHA_DEVOL`, `ESTADO='D'`, `MULTA` y stock quedaron
     actualizados.

## 7. Diagnostico rapido

- Si aparece `AEI9`, revisar que el programa este en `LOAD.LIBRARY` y definido
  en CICS.
- Si aparece `MAPFAIL`, revisar que la pantalla se haya enviado antes de
  recibir datos o usar `CLEAR` para reiniciar.
- Si aparece SQL `-206`, comparar el SQL embebido contra `RUNSQL.jcl`.
- Si aparece SQL `-818`, recompilar el COBOL y ejecutar `CICSBIND`.
- Para depurar comandos CICS, activar `CEDF`, ejecutar `MENU`, y revisar cada
  `SEND`, `RECEIVE`, `XCTL` y `SYNCPOINT`.
