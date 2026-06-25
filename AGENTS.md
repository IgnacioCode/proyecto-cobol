# AGENTS.md

## Proyecto

Sistema de Gestion de Biblioteca Universitaria para z/OS Mainframe.

Materia: Electiva I - Lenguaje Orientado a Negocios (COBOL), UNLaM.
Grupo: 6.
Owner DB2 principal: KC03G24.
Datasets de desarrollo observados: KC02814.GRUPO6.*.
Subsistema DB2: DBDG.

## Referencias obligatorias

Antes de modificar COBOL, JCL, DB2, datasets o CICS, consultar:

- `agentRefs/consigna.md`
- `agentRefs/referencias/1_datasets.md`
- `agentRefs/referencias/2_jcl.md`
- `agentRefs/referencias/3_cobol.md`
- `agentRefs/referencias/4_db2.md`
- `agentRefs/referencias/5_cics.md`

## Estructura del repo

- `COBOL.SOURCE/`: programas COBOL.
- `COBOL.COPYLIB/`: copybooks.
- `JCL.SOURCE/`: JCL de compilacion, ejecucion y SQL.
- `SQL.SOURCE/`: scripts SQL si aplica.
- `BMS.SOURCE/`: mapas BMS CICS.
- `agentRefs/`: documentacion de contexto para agentes.

## Convenciones

- COBOL en formato fijo.
- Divisiones, secciones, parrafos, `FD` y niveles `01` en Area A.
- Sentencias ejecutables y clausulas en Area B.
- No pasar columna 72 en COBOL.
- No pasar columna 80 en JCL.
- Usar `FILE STATUS` para archivos.
- Alinear `FD RECORD CONTAINS` con `LRECL` del dataset.
- Recompilar y bindear despues de cambiar SQL embebido.

## DB2

- Schema/owner actual: `KC03G24`.
- Tablas principales:
  - `KC03G24.USUARIOS`
  - `KC03G24.LIBROS`
  - `KC03G24.PRESTAMOS`
- DDL operativo actual esta en `JCL.SOURCE/RUNSQL.jcl`.
- No asumir columnas con prefijo COBOL (`USU_*`, `LIB_*`, `PRES_*`) en DB2.
- Al usar SQL embebido, comparar siempre contra las columnas reales.

## Esquema DB2 operativo

Fuente de verdad local: `JCL.SOURCE/RUNSQL.jcl`.

### KC03G24.USUARIOS

Tabla en `UNLAM.G6USU`.

| Columna | Tipo DB2 | Null | Notas |
|---|---|---|---|
| `COD_USUARIO` | `CHAR(10)` | No | PK |
| `NOMBRE` | `VARCHAR(30)` | No |  |
| `APELLIDO` | `VARCHAR(30)` | No |  |
| `TIPO_USUARIO` | `CHAR(1)` | No | `E`, `D`, `A` |
| `EMAIL` | `VARCHAR(50)` | No | Indice unico |
| `TELEFONO` | `VARCHAR(20)` | Si |  |
| `DIRECCION` | `VARCHAR(60)` | Si |  |
| `FECHA_ALTA` | `DATE` | Si | Host `YYYY-MM-DD` |
| `FECHA_BAJA` | `DATE` | Si | Host `YYYY-MM-DD` o NULL |
| `ESTADO` | `CHAR(1)` | Si | Default `A`; `A`, `I` |

### KC03G24.LIBROS

Tabla en `UNLAM.G6LIB`.

| Columna | Tipo DB2 | Null | Notas |
|---|---|---|---|
| `COD_LIBRO` | `CHAR(10)` | No | PK |
| `TITULO` | `VARCHAR(60)` | No |  |
| `AUTOR` | `VARCHAR(40)` | No |  |
| `EDITORIAL` | `VARCHAR(30)` | Si |  |
| `ANIO_PUBLICACION` | `INTEGER` | Si |  |
| `CATEGORIA` | `VARCHAR(20)` | No | Indice `IDP_LIB_CAT` |
| `STOCK_TOTAL` | `INTEGER` | Si | Default `0`, check `>= 0` |
| `STOCK_DISPONIBLE` | `INTEGER` | Si | Default `0` |
| `UBICACION` | `CHAR(10)` | Si |  |
| `FECHA_ALTA` | `DATE` | Si | Host `YYYY-MM-DD` |
| `ESTADO` | `CHAR(1)` | Si | Default `A`; `A`, `I`, `B` |

### KC03G24.PRESTAMOS

Tabla en `UNLAM.G6PRE`.

| Columna | Tipo DB2 | Null | Notas |
|---|---|---|---|
| `NUM_PRESTAMO` | `INTEGER` | No | PK; usar `SEQ_PRESTAMOS` |
| `COD_LIBRO` | `CHAR(10)` | No | FK a `LIBROS.COD_LIBRO` |
| `COD_USUARIO` | `CHAR(10)` | No | FK a `USUARIOS.COD_USUARIO` |
| `FECHA_PRESTAMO` | `DATE` | No | Host `YYYY-MM-DD` |
| `FECHA_LIMITE` | `DATE` | No | Host `YYYY-MM-DD` |
| `FECHA_DEVOL` | `DATE` | Si | No se llama `FECHA_DEVOLUCION` en DB2 |
| `ESTADO` | `CHAR(1)` | Si | Default `P`; `P`, `D`, `V` |
| `MULTA` | `DECIMAL(7,2)` | Si | Default `0.00` |
| `OBSERVACIONES` | `CHAR(100)` | Si |  |

### Secuencia e indices

- `KC03G24.SEQ_PRESTAMOS`: `START WITH 1`, `INCREMENT BY 1`, `CACHE 20`.
- `IDZ_PK_USU`: unico sobre `USUARIOS(COD_USUARIO)`.
- `IDU_USU_EMAIL`: unico sobre `USUARIOS(EMAIL)`.
- `IDP_USU_TIPO`: sobre `USUARIOS(TIPO_USUARIO)`.
- `IDZ_PK_LIB`: unico sobre `LIBROS(COD_LIBRO)`.
- `IDP_LIB_CAT`: sobre `LIBROS(CATEGORIA)`.
- `IDZ_PK_PRE`: unico sobre `PRESTAMOS(NUM_PRESTAMO)`.

## Copybooks y equivalencias

- `COBOL.COPYLIB/USUARIO.cbl`: `REG-USUARIO` mide 229 bytes.
  - Campos: `USU-CODIGO`, `USU-NOMBRE`, `USU-APELLIDO`,
    `USU-TIPO-USUARIO`, `USU-EMAIL`, `USU-TELEFONO`,
    `USU-DIRECCION`, `USU-FECHA-ALTA`, `USU-FECHA-BAJA`,
    `USU-ESTADO`.
  - Equivalen a columnas DB2 sin prefijo: `COD_USUARIO`, `NOMBRE`, `APELLIDO`, etc.
- `COBOL.COPYLIB/LIBRO.cbl`: `REG-LIBRO` mide 200 bytes.
  - Campos: `LIB-CODIGO`, `LIB-TITULO`, `LIB-AUTOR`,
    `LIB-EDITORIAL`, `LIB-ANIO-PUBLICACION`, `LIB-CATEGORIA`,
    `LIB-STOCK-TOTAL`, `LIB-STOCK-DISPONIBLE`, `LIB-UBICACION`,
    `LIB-FECHA-ALTA`, `LIB-USUARIO-ALTA`, `LIB-ESTADO`.
  - `LIB-USUARIO-ALTA` existe en copybook, pero no existe en la tabla DB2 actual.
- `COBOL.COPYLIB/PRESTAMO.cbl`: `REG-PRESTAMO` mide 171 bytes.
  - Campos: `PRES-NUMERO`, `PRES-CODIGO-LIBRO`,
    `PRES-CODIGO-USUARIO`, `PRES-FECHA-PRESTAMO`,
    `PRES-FECHA-DEVOLUCION`, `PRES-FECHA-LIMITE`,
    `PRES-ESTADO`, `PRES-MULTA`, `PRES-OBSERVACIONES`.
  - En DB2 la columna de devolucion es `FECHA_DEVOL`, no `FECHA_DEVOLUCION`.
- `COBOL.COPYLIB/CONSTANT.cbl`:
  - Dias prestamo: estudiante `15`, docente `30`, administrativo `20`.
  - Maximos activos: estudiante `3`, docente `10`, administrativo `5`.
  - Multa por dia: `50.00`.

## JCL / ejecucion

- Subsistema DB2: `DBDG`.
- DSNTEP2 usa plan `DSNTEP13`.
- Algunos programas usan plan `GRUPO6` o `CURSOG06`; verificar el JCL real antes de cambiar.
- Para datasets de salida con `DISP=NEW`, borrar previamente con `IDCAMS DELETE` y `SET MAXCC = 0`.

## USUMANT

- Programa: `COBOL.SOURCE/USUMANT.cbl`.
- JCL: `JCL.SOURCE/USUMANT.jcl`.
- Entrada: `KC03G24.GRUPO6.DATA.INPUT2`.
- Salida: `KC03G24.GRUPO6.REPORTES.OUTPUT2`.
- `INPUT2` debe ser `RECFM=FB,LRECL=229`.
- Logica: si existe usuario, `UPDATE`; si no existe, `INSERT`.
- Email unico por indice unico sobre `EMAIL`.
- `FECHA_ALTA` y `FECHA_BAJA` son `DATE`; usar formato `YYYY-MM-DD` o NULL con indicador.

## PRESTAM

- Programa: `COBOL.SOURCE/PRESTAM.cbl`.
- JCL: `JCL.SOURCE/PRESTAM.jcl`.
- Entrada: `KC03G24.GRUPO6.DATA.INPUT3`.
- Salida: `KC03G24.GRUPO6.REPORTES.OUTPUT3`.
- `INPUT3` debe ser `RECFM=FB,LRECL=140`.
- Layout `INPUT3`: operacion `X(1)`, numero prestamo `X(8)`,
  usuario `X(10)`, libro `X(10)`, fecha `X(10)`,
  observaciones `X(100)`, filler `X(1)`.
- Para evitar `SQLCODE -206 ID A/P/D/V`, usar host variables para estados en SQL embebido, no literales directos.

## Pitfalls frecuentes

- `SQLCODE -206`: columna/identificador no existe; revisar `SQLERRMC` y comparar contra DDL real.
- `SQLCODE -204`: tabla/schema no existe o mal qualifier.
- `SQLCODE -803`: duplicado por PK/indice unico.
- `FILE STATUS 39`: atributos fisicos del dataset no coinciden con `FD`.
- Error Area B: sentencia COBOL mal indentada.
