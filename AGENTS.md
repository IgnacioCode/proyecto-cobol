# AGENTS.md

## Proyecto

Sistema de Gestión de Biblioteca Universitaria para z/OS Mainframe.

Materia: Electiva I - Lenguaje Orientado a Negocios (COBOL), UNLaM.  
Grupo: 6.  
Owner DB2 principal: KC03G24.  
Datasets de desarrollo observados: KC02814.GRUPO6.*  
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
- `JCL.SOURCE/`: JCL de compilación, ejecución y SQL.
- `SQL.SOURCE/`: scripts SQL si aplica.
- `BMS.SOURCE/`: mapas BMS CICS.
- `agentRefs/`: documentación de contexto para agentes.

## Convenciones

- COBOL en formato fijo.
- Divisiones, secciones, párrafos, `FD` y niveles `01` en Area A.
- Sentencias ejecutables y cláusulas en Area B.
- No pasar columna 72 en COBOL.
- No pasar columna 80 en JCL.
- Usar `FILE STATUS` para archivos.
- Alinear `FD RECORD CONTAINS` con `LRECL` del dataset.
- Recompilar y bindear después de cambiar SQL embebido.

## DB2

- Schema/owner actual: `KC03G24`.
- Tablas principales:
  - `KC03G24.USUARIOS`
  - `KC03G24.LIBROS`
  - `KC03G24.PRESTAMOS`
- DDL operativo actual está en `JCL.SOURCE/RUNSQL.jcl`.
- La tabla `USUARIOS` usa columnas:
  - `COD_USUARIO`
  - `NOMBRE`
  - `APELLIDO`
  - `TIPO_USUARIO`
  - `EMAIL`
  - `TELEFONO`
  - `DIRECCION`
  - `FECHA_ALTA`
  - `FECHA_BAJA`
  - `ESTADO`
- No asumir columnas `USU_*` en DB2 aunque existan en copybooks COBOL.

## JCL / ejecución

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
- Lógica: si existe usuario, `UPDATE`; si no existe, `INSERT`.
- Email único por índice único sobre `EMAIL`.
- `FECHA_ALTA` y `FECHA_BAJA` son `DATE`; usar formato `YYYY-MM-DD` o NULL con indicador.

## Pitfalls frecuentes

- `SQLCODE -206`: columna no existe; comparar contra DDL real.
- `SQLCODE -204`: tabla/schema no existe o mal qualifier.
- `SQLCODE -803`: duplicado por PK/índice único.
- `FILE STATUS 39`: atributos físicos del dataset no coinciden con `FD`.
- Error Area B: sentencia COBOL mal indentada.