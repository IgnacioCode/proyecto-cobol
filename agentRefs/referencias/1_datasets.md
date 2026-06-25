# Guía de datasets en z/OS para COBOL

Universidad Nacional de La Matanza - DIIT  
Electiva I - Lenguaje Orientado a Negocios (COBOL)  
Documentación técnica para el TP Integrador Final - Año 2026

---

## 1. Introducción

Un **dataset** en z/OS es una colección nombrada de datos almacenada en DASD. Es el equivalente aproximado a un archivo en otros sistemas operativos, pero con reglas propias de mainframe: nombre jerárquico, organización, formato de registro, longitud lógica, tamaño de bloque y espacio asignado.

Entender datasets es clave para trabajar con COBOL, JCL, DB2, CICS y Zowe.

---

## 2. Convenciones de nombres

Los datasets usan nombres jerárquicos separados por puntos:

```text
HIGH_LEVEL_QUALIFIER.MIDDLE_QUALIFIERS.LOW_LEVEL_QUALIFIER
```

Ejemplos del proyecto:

```text
KC03G24.GRUPO6.COBOL.SOURCE
KC03G24.GRUPO6.COBOL.COPYLIB
KC03G24.GRUPO6.JCL.SOURCE
KC03G24.GRUPO6.DATA.INPUT
KC03G24.GRUPO6.DATA.INPUT2
KC03G24.GRUPO6.LOAD.LIBRARY
KC03G24.GRUPO6.REPORTES.OUTPUT
KC03G24.GRUPO6.REPORTES.OUTPUT2
```

Reglas generales:

- Máximo 44 caracteres en total.
- Cada calificador tiene máximo 8 caracteres.
- Se permiten letras, números y caracteres especiales como `$`, `@`, `#`.
- Debe comenzar con letra o carácter especial.
- No puede terminar en punto.

---

## 3. Tipos de datasets por organización

## 3.1 PS - Physical Sequential

Un dataset **PS** guarda registros uno después del otro en orden físico secuencial.

Características:

- Acceso secuencial.
- Ideal para procesamiento batch.
- Lectura desde el principio hasta el fin.
- Útil para entrada, salida, reportes y logs.

Uso típico en COBOL:

```cobol
SELECT ARCHIVO-ENTRADA ASSIGN TO ENTRADA
    ORGANIZATION IS SEQUENTIAL
    ACCESS MODE IS SEQUENTIAL
    FILE STATUS IS WS-STATUS-ENTRADA.
```

Cuándo usarlo:

- Archivos de entrada para carga masiva.
- Reportes de salida.
- Archivos de log.
- Respaldos.

Ejemplo con Zowe:

```bash
zowe files create data-set-sequential "KC03G24.GRUPO6.DATA.INPUT" \
  --record-format FB \
  --record-length 200 \
  --block-size 32000 \
  --primary-space 10 \
  --secondary-space 5
```

## 3.2 PO - Partitioned Organization

Un dataset **PO** o **PDS** contiene múltiples miembros independientes. Cada miembro se parece a un archivo separado dentro de una biblioteca.

Ejemplo:

```text
KC03G24.GRUPO6.COBOL.SOURCE
├── CARGINI
├── USUMANT
├── PRESTAM
└── REPORTES
```

Características:

- Tiene directorio interno de miembros.
- Permite acceso por nombre de miembro.
- Ideal para código fuente, copybooks, JCL y load libraries.

Cuándo usarlo:

- `COBOL.SOURCE`: programas COBOL.
- `COBOL.COPYLIB`: copybooks.
- `JCL.SOURCE`: JCL.
- `BMS.SOURCE`: mapas BMS.
- `LOAD.LIBRARY`: módulos compilados.

Ejemplo con Zowe:

```bash
zowe files create data-set-partitioned "KC03G24.GRUPO6.COBOL.SOURCE" \
  --record-format FB \
  --record-length 80 \
  --block-size 32000 \
  --primary-space 20 \
  --secondary-space 10 \
  --directory-blocks 10
```

## 3.3 VSAM

VSAM se usa para archivos con acceso más avanzado que un PS.

### KSDS - Key Sequenced Data Set

Registros organizados por clave única. Permite acceso directo por clave y recorrido secuencial.

Características:

- Acceso por clave primaria.
- Mantiene orden por clave.
- Permite inserción, actualización y eliminación.
- Útil para archivos maestros.

Ejemplo COBOL:

```cobol
SELECT ARCHIVO-USUARIOS ASSIGN TO USUARIOS
    ORGANIZATION IS INDEXED
    ACCESS MODE IS DYNAMIC
    RECORD KEY IS USU-CODIGO
    FILE STATUS IS WS-STATUS-USUARIOS.
```

Ejemplo IDCAMS:

```jcl
//DEFINE   JOB (ACCT),'DEFINIR VSAM',CLASS=A,MSGCLASS=H
//STEP1    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DEFINE CLUSTER (NAME(KC03G24.GRUPO6.VSAM.USUARIOS) -
                  RECSZ(200 200) -
                  KEYS(10 0) -
                  CYLINDERS(5 2) -
                  INDEXED) -
         DATA  (NAME(KC03G24.GRUPO6.VSAM.USUARIOS.DATA)) -
         INDEX (NAME(KC03G24.GRUPO6.VSAM.USUARIOS.INDEX))
/*
```

### ESDS - Entry Sequenced Data Set

Registros guardados en orden de llegada.

Uso típico:

- Logs.
- Auditoría.
- Transacciones históricas.
- Colas de procesamiento.

### RRDS - Relative Record Data Set

Registros accedidos por número relativo.

Uso típico:

- Tablas de acceso directo por posición.
- Estructuras tipo slot.

---

## 4. Atributos principales

## 4.1 RECFM - Record Format

Define el formato físico de los registros.

### FB - Fixed Blocked

Registros de longitud fija, agrupados en bloques.

Características:

- Eficiente en espacio y performance.
- Recomendado para la mayoría de archivos del TP.
- Cada registro mide exactamente `LRECL`.

Ejemplo:

```text
RECFM=FB
LRECL=80
BLKSIZE=32000
```

### F - Fixed Unblocked

Registros de longitud fija, un registro por bloque. Es menos eficiente. Usar solo si se pide explícitamente.

### VB - Variable Blocked

Registros de longitud variable, agrupados en bloques. Útil cuando los registros tienen tamaños muy distintos.

### V - Variable Unblocked

Registros de longitud variable, un registro por bloque.

---

## 4.2 LRECL - Logical Record Length

Define la longitud lógica de cada registro.

Valores típicos:

```text
80   Fuentes COBOL, JCL, miembros PDS
133  Reportes impresos simples
200  Archivos de entrada de aplicación
229  INPUT2 de usuarios en este proyecto
```

Regla práctica: el `LRECL` del dataset debe coincidir con el `RECORD CONTAINS` del `FD` COBOL.

Ejemplo:

```cobol
FD ARCHIVO-ENTRADA
    RECORD CONTAINS 229 CHARACTERS.
```

Requiere:

```text
RECFM=FB
LRECL=229
```

Si el dataset tiene `LRECL=80`, COBOL no puede leer correctamente un registro de 229 caracteres.

---

## 4.3 BLKSIZE - Block Size

Define cuántos bytes se agrupan en cada bloque físico.

Reglas:

- Para `FB`, debe ser múltiplo de `LRECL`.
- Máximo usual recomendado: alrededor de 32760.
- Bloques grandes suelen mejorar performance.
- `BLKSIZE=0` permite que z/OS calcule un tamaño óptimo.

Ejemplos:

```text
LRECL=80   BLKSIZE=32000
LRECL=200  BLKSIZE=32000
LRECL=229  BLKSIZE=0 o múltiplo de 229
```

---

## 4.4 Espacio

Unidades:

- `TRK`: tracks. Recomendado para datasets chicos.
- `CYL`: cylinders. Para datasets más grandes.

Ejemplo:

```text
SPACE=(TRK,(5,5))
```

Significa:

- 5 tracks iniciales.
- 5 tracks adicionales por extensión si hace falta.

---

## 5. Creación de datasets con Zowe

## 5.1 Datasets secuenciales

Archivo de entrada:

```bash
zowe files create data-set-sequential "KC03G24.GRUPO6.DATA.INPUT" \
  --record-format FB \
  --record-length 200 \
  --block-size 32000 \
  --primary-space 10 \
  --secondary-space 5
```

Archivo de usuarios `INPUT2` para `USUMANT`:

```bash
zowe files create data-set-sequential "KC03G24.GRUPO6.DATA.INPUT2" \
  --record-format FB \
  --record-length 229 \
  --block-size 0 \
  --primary-space 5 \
  --secondary-space 5
```

Reporte:

```bash
zowe files create data-set-sequential "KC03G24.GRUPO6.REPORTES.OUTPUT2" \
  --record-format FB \
  --record-length 133 \
  --block-size 0 \
  --primary-space 5 \
  --secondary-space 2
```

## 5.2 Datasets particionados

Fuente COBOL:

```bash
zowe files create data-set-partitioned "KC03G24.GRUPO6.COBOL.SOURCE" \
  --record-format FB \
  --record-length 80 \
  --block-size 32000 \
  --primary-space 25 \
  --secondary-space 10 \
  --directory-blocks 15
```

Copybooks:

```bash
zowe files create data-set-partitioned "KC03G24.GRUPO6.COBOL.COPYLIB" \
  --record-format FB \
  --record-length 80 \
  --block-size 32000 \
  --primary-space 10 \
  --secondary-space 5 \
  --directory-blocks 10
```

JCL:

```bash
zowe files create data-set-partitioned "KC03G24.GRUPO6.JCL.SOURCE" \
  --record-format FB \
  --record-length 80 \
  --block-size 32000 \
  --primary-space 20 \
  --secondary-space 10 \
  --directory-blocks 20
```

Load library:

```bash
zowe files create data-set-partitioned "KC03G24.GRUPO6.LOAD.LIBRARY" \
  --record-format U \
  --block-size 32760 \
  --primary-space 30 \
  --secondary-space 15 \
  --directory-blocks 25
```

---

## 6. Operaciones básicas con Zowe

Listar datasets:

```bash
zowe files list data-set "KC03G24.GRUPO6.*"
```

Listar miembros de un PDS:

```bash
zowe files list all-members "KC03G24.GRUPO6.COBOL.SOURCE"
```

Subir un programa fuente:

```bash
zowe files upload file-to-data-set "USUMANT.cbl" \
  "KC03G24.GRUPO6.COBOL.SOURCE(USUMANT)"
```

Subir un copybook:

```bash
zowe files upload file-to-data-set "USUARIO.cbl" \
  "KC03G24.GRUPO6.COBOL.COPYLIB(USUARIO)"
```

Subir JCL:

```bash
zowe files upload file-to-data-set "USUMANT.jcl" \
  "KC03G24.GRUPO6.JCL.SOURCE(USUMANT)"
```

Descargar un miembro:

```bash
zowe files download data-set \
  "KC03G24.GRUPO6.COBOL.SOURCE(USUMANT)" \
  --file "USUMANT.cbl"
```

Descargar dataset secuencial:

```bash
zowe files download data-set \
  "KC03G24.GRUPO6.REPORTES.OUTPUT2" \
  --file "output2.txt"
```

Eliminar dataset:

```bash
zowe files delete data-set "KC03G24.GRUPO6.DATA.TEMPORAL"
```

Eliminar miembro:

```bash
zowe files delete data-set \
  "KC03G24.GRUPO6.COBOL.SOURCE(TEMPORAL)"
```

---

## 7. Datasets específicos del proyecto

## 7.1 Bibliotecas de desarrollo

```text
KC03G24.GRUPO6.COBOL.SOURCE
KC03G24.GRUPO6.COBOL.COPYLIB
KC03G24.GRUPO6.JCL.SOURCE
KC03G24.GRUPO6.BMS.SOURCE
KC03G24.GRUPO6.SQL.SOURCE
KC03G24.GRUPO6.LOAD.LIBRARY
KC03G24.GRUPO6.DBRM
```

## 7.2 Datasets de entrada

```text
KC03G24.GRUPO6.DATA.INPUT    Entrada de libros para CARGINI
KC03G24.GRUPO6.DATA.INPUT2   Entrada de usuarios para USUMANT
```

### INPUT2 - Usuarios

Para el programa `USUMANT`, el archivo debe ser:

```text
DSORG=PS
RECFM=FB
LRECL=229
```

Layout:

```text
COD_USUARIO    X(10)
NOMBRE         X(30)
APELLIDO       X(30)
TIPO_USUARIO   X(01)
EMAIL          X(50)
TELEFONO       X(20)
DIRECCION      X(60)
FECHA_ALTA     X(10)  Formato YYYY-MM-DD o espacios
FECHA_BAJA     X(10)  Formato YYYY-MM-DD o espacios
ESTADO         X(01)  A=Activo, I=Inactivo
FILLER         X(07)
Total          229
```

Si `INPUT2` se crea con `LRECL=80`, los registros quedan truncados y el programa no puede procesarlos correctamente.

## 7.3 Reportes

```text
KC03G24.GRUPO6.REPORTES.OUTPUT
KC03G24.GRUPO6.REPORTES.OUTPUT2
```

Para reportes simples:

```text
RECFM=FB
LRECL=133
```

---

## 8. Creación con JCL / IDCAMS / IEFBR14

Ejemplo para borrar y recrear `INPUT2`:

```jcl
//DEL     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE KC03G24.GRUPO6.DATA.INPUT2
  SET MAXCC = 0
/*
//ALLOC   EXEC PGM=IEFBR14
//INPUT2  DD DSN=KC03G24.GRUPO6.DATA.INPUT2,
//            DISP=(NEW,CATLG,DELETE),
//            DSORG=PS,
//            RECFM=FB,
//            LRECL=229,
//            BLKSIZE=0,
//            SPACE=(TRK,(5,5)),
//            UNIT=SYSALLDA
```

Ejemplo para borrar y recrear `OUTPUT2`:

```jcl
//DEL     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE KC03G24.GRUPO6.REPORTES.OUTPUT2
  SET MAXCC = 0
/*
//ALLOC   EXEC PGM=IEFBR14
//REPORTE DD DSN=KC03G24.GRUPO6.REPORTES.OUTPUT2,
//            DISP=(NEW,CATLG,DELETE),
//            DSORG=PS,
//            RECFM=FB,
//            LRECL=133,
//            BLKSIZE=0,
//            SPACE=(TRK,(5,5)),
//            UNIT=SYSALLDA
```

---

## 9. Buenas prácticas

- Mantener nombres consistentes entre JCL, COBOL y datasets reales.
- Verificar `LRECL` antes de cargar datos.
- En archivos `FB`, cada registro debe tener exactamente la longitud definida.
- Para fuentes COBOL/JCL usar `LRECL=80`.
- Para reportes usar `LRECL=133` salvo que el programa indique otra cosa.
- Para datasets de datos, alinear `LRECL` con el `FD` COBOL.
- Usar `FILE STATUS` en COBOL para diagnosticar apertura, lectura y escritura.
- Usar `SET MAXCC = 0` en IDCAMS cuando se borra un dataset que puede no existir.
- Documentar layouts de entrada y salida junto al programa que los usa.

---

## 10. Diagnóstico rápido

| Síntoma | Causa probable | Acción |
|---|---|---|
| El programa lee campos corridos | `LRECL` no coincide con layout | Revisar `FD` y atributos del dataset |
| `OPEN INPUT` falla | DD faltante o dataset inexistente | Revisar JCL y nombre del dataset |
| `OPEN OUTPUT` falla | Dataset ya existe con `DISP=NEW` | Borrar antes o usar `DISP=MOD/OLD` según corresponda |
| Registros truncados | Dataset `LRECL` menor al registro | Recrear dataset con `LRECL` correcto |
| Reporte ilegible | `LRECL`/`RECFM` incorrecto | Usar `RECFM=FB,LRECL=133` |
| Error de miembro no encontrado | Nombre de miembro incorrecto | Revisar PDS y `SYSIN`/`SYSLIB` |
