# Guía de JCL para COBOL en z/OS

Universidad Nacional de La Matanza - DIIT  
Electiva I - Lenguaje Orientado a Negocios (COBOL)  
Documentación técnica para el TP Integrador Final

---

## 1. Introducción

**JCL** significa **Job Control Language**. Es el lenguaje de control de trabajos de z/OS y permite definir cómo se compilan, linkeditan, bindean y ejecutan programas en mainframe.

En el proyecto se usa JCL para:

- Compilar programas COBOL.
- Compilar programas COBOL con DB2.
- Ejecutar programas batch.
- Ejecutar utilitarios como `IDCAMS`, `IEFBR14`, `IEBGENER` y `DSNTEP2`.
- Crear, borrar y cargar datasets.
- Ejecutar sentencias SQL contra DB2.

---

## 2. Conceptos básicos

| Concepto | Descripción |
|---|---|
| Job | Unidad completa de trabajo enviada a JES. |
| Step | Paso dentro de un job. Cada step ejecuta un programa o procedimiento. |
| DD Statement | Define un dataset o recurso de entrada/salida. |
| Procedure / PROC | Conjunto reutilizable de pasos JCL. |
| Return Code / RC | Código de retorno de un step o job. |
| SYSOUT | Salida enviada al spool. |

---

## 3. Estructura básica de un JCL

```jcl
//JOBNAME  JOB (ACCOUNT),'DESCRIPCION',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID
//STEP1    EXEC PGM=PROGRAMA
//DDNAME   DD DSN=DATASET.NAME,DISP=SHR
```

Elementos principales:

- `//`: inicio de sentencia JCL.
- `JOBNAME`: nombre del job. Máximo 8 caracteres.
- `JOB`: identifica el inicio del trabajo.
- `EXEC`: ejecuta un programa o procedimiento.
- `DD`: define un dataset o flujo de datos.
- `DSN`: nombre del dataset.
- `DISP`: disposición del dataset.

Clases comunes:

| Parámetro | Uso típico |
|---|---|
| `CLASS=A` | Jobs normales o prioritarios, según instalación. |
| `CLASS=S` | Jobs de estudiantes, común en universidades. |
| `MSGCLASS=H` | Mantener salida en spool para revisar online. |
| `MSGCLASS=X` | Salida no impresa o descartada, según instalación. |

---

## 4. Datasets en JCL

La variable `&SYSUID` representa el usuario que ejecuta el job.

Ejemplo:

```jcl
//COBOL.SYSIN DD DSN=&SYSUID..COBOL.SOURCE(PROGRAMA),DISP=SHR
```

El doble punto después de `&SYSUID` es intencional: el primer punto termina la variable y el segundo separa el siguiente calificador.

En este repo/proyecto se observan nombres explícitos como:

```text
KC02814.GRUPO6.COBOL.SOURCE
KC02814.GRUPO6.COBOL.COPYLIB
KC02814.GRUPO6.LOAD.LIBRARY
KC03G24.GRUPO6.DATA.INPUT2
KC03G24.GRUPO6.REPORTES.OUTPUT2
```

Ejemplos de DD:

```jcl
//ENTRADA  DD DSN=KC03G24.GRUPO6.DATA.INPUT2,DISP=SHR
//REPORTE  DD DSN=KC03G24.GRUPO6.REPORTES.OUTPUT2,
//            DISP=(NEW,CATLG,DELETE),
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=1330),
//            SPACE=(TRK,(5,5)),UNIT=SYSALLDA
```

---

## 5. DISP

`DISP` indica qué hacer con un dataset.

| DISP | Significado |
|---|---|
| `SHR` | Compartido, normalmente para lectura. |
| `OLD` | Uso exclusivo de dataset existente. |
| `MOD` | Agregar al final o crear si no existe. |
| `NEW` | Crear nuevo dataset. |
| `CATLG` | Catalogar si el step termina bien. |
| `DELETE` | Borrar si el step falla o al cerrar. |
| `PASS` | Pasar dataset temporal a otro step. |

Ejemplo:

```jcl
DISP=(NEW,CATLG,DELETE)
```

Significa:

- Crear dataset nuevo.
- Catalogarlo si el step termina bien.
- Borrarlo si el step falla.

---

## 6. Compilación COBOL sin DB2

El proceso clásico tiene dos pasos:

1. Compilación: COBOL fuente a objeto.
2. Link-edit: objeto a módulo ejecutable.

Procedimientos comunes:

| PROC/Programa | Uso |
|---|---|
| `IGYWCLG` | Compile, link and go. |
| `IGYWCL` | Compile and link. |
| `IGYWC` | Solo compile. |
| `IEWL` | Solo link-edit. |

Ejemplo con `IGYWCL`:

```jcl
//COMPILE JOB (ACCT),'COMPILAR COBOL',CLASS=S,MSGCLASS=H
//STEP1   EXEC IGYWCL,PARM.COBOL='APOST,LIB'
//COBOL.SYSLIB DD DSN=&SYSUID..COBOL.COPYLIB,DISP=SHR
//COBOL.SYSIN  DD DSN=&SYSUID..COBOL.SOURCE(CARGINI),DISP=SHR
//LKED.SYSLMOD DD DSN=&SYSUID..LOAD.LIBRARY(CARGINI),DISP=SHR
//LKED.SYSIN   DD *
  NAME CARGINI(R)
/*
```

Parámetros COBOL frecuentes:

| Parámetro | Uso |
|---|---|
| `APOST` | Usa apóstrofes para literales. |
| `LIB` | Habilita búsqueda de copybooks. |
| `MAP` | Genera mapa de datos. |
| `LIST` | Genera listado fuente. |
| `XREF` | Genera referencias cruzadas. |
| `NOOPT` | Sin optimización, útil para debugging. |
| `TEST` | Incluye información de depuración. |
| `SQL` | Compilación con soporte SQL embebido, si el entorno lo soporta. |

---

## 7. Compilación COBOL con DB2

Un programa COBOL con SQL embebido requiere:

1. Precompilación DB2 o compilación con opción `SQL`.
2. Compilación COBOL.
3. Link-edit con librerías DB2/LE.
4. Bind del DBRM a un plan o package.
5. Ejecución bajo DB2 mediante `IKJEFT01`.

### Variante con precompilador DB2

```jcl
//PRECOMP EXEC PGM=DSNHPC,
//             PARM='HOST(IBMCOB),APOST'
//STEPLIB  DD DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//SYSLIB   DD DSN=KC02814.GRUPO6.COBOL.COPYLIB,DISP=SHR
//         DD DSN=DSND10.SDSNC.H,DISP=SHR
//SYSIN    DD DSN=KC02814.GRUPO6.COBOL.SOURCE(USUMANT),DISP=SHR
//SYSCIN   DD DSN=&&PRECOMP,DISP=(NEW,PASS),
//            SPACE=(TRK,(10,5)),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=32000)
//DBRMLIB  DD DSN=&&DBRM(USUMANT),DISP=(NEW,PASS),
//            SPACE=(TRK,(5,2,5)),UNIT=SYSDA,
//            DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=3200)
//SYSPRINT DD SYSOUT=*
```

### Variante usada en el JCL actual del repo

En `JCL.SOURCE/USUMANT.jcl` se usa `IGYWCL` con parámetro `SQL`:

```jcl
//COMPILE  EXEC IGYWCL,
//         PARM.COBOL='SQL,RENT,OBJECT'
```

Esta variante depende de que el entorno COBOL/DB2 soporte compilación SQL integrada.

---

## 8. Link-edit con DB2

Para programas COBOL DB2 se debe incluir soporte DB2, típicamente `DSNELI`.

Ejemplo:

```jcl
//LKED     EXEC PGM=IEWL,PARM='XREF,LIST,LET'
//SYSLIB   DD DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD DSN=CEE.SCEELKED,DISP=SHR
//SYSLIN   DD DSN=&&OBJECT,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DSN=KC02814.GRUPO6.LOAD.LIBRARY(USUMANT),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  INCLUDE SYSLIB(DSNELI)
  NAME USUMANT(R)
/*
```

---

## 9. Bind y ejecución con DB2

Para ejecutar un COBOL con DB2 se usa normalmente `IKJEFT01`.

Ejemplo:

```jcl
//STEP1    EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT)
//STEPLIB  DD DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD DSN=DSND10.DBDG.RUNLIB.LOAD,DISP=SHR
//         DD DSN=KC02814.GRUPO6.LOAD.LIBRARY,DISP=SHR
//DBRMLIB  DD DSN=KC02814.GRUPO6.DBRM,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBDG)
  BIND PLAN(GRUPO6) MEMBER(USUMANT) -
       ACTION(REPLACE) ISOLATION(CS) ENCODING(EBCDIC)
  RUN PROGRAM(USUMANT) PLAN(GRUPO6) -
      LIB('KC02814.GRUPO6.LOAD.LIBRARY')
  END
/*
```

Puntos críticos:

- `DSN SYSTEM(DBDG)` debe coincidir con el subsistema DB2.
- `BIND PLAN(...)` debe usar el DBRM correcto.
- `RUN PROGRAM(...) PLAN(...)` debe usar el plan bindeado.
- Si se modifica SQL embebido, hay que recompilar y hacer bind de nuevo.

---

## 10. Ejecución de SQL con DSNTEP2

`DSNTEP2` permite ejecutar sentencias SQL desde JCL.

Ejemplo:

```jcl
//STEP01   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD DSN=DSND10.DBDG.RUNLIB.LOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBDG)
  RUN PROGRAM(DSNTEP2) PLAN(DSNTEP13) -
      LIB('DSND10.DBDG.RUNLIB.LOAD')
  END
/*
//SYSIN    DD *
  SELECT CURRENT DATE
    FROM SYSIBM.SYSDUMMY1;
/*
```

Uso en el proyecto:

- Crear tablespaces.
- Crear tablas.
- Crear índices.
- Otorgar permisos `GRANT`.
- Consultar catálogos DB2 para diagnosticar columnas/tablas.

---

## 11. Utilitarios frecuentes

## 11.1 IDCAMS

`IDCAMS` gestiona datasets, catálogos y VSAM.

Usos:

- Borrar datasets.
- Crear VSAM.
- Copiar datos con `REPRO`.
- Operaciones de catálogo.

Ejemplo para borrar sin fallar si no existe:

```jcl
//LIMPIEZA EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE KC03G24.GRUPO6.REPORTES.OUTPUT2
  SET MAXCC = 0
/*
```

## 11.2 IEFBR14

`IEFBR14` se usa comúnmente para crear o borrar datasets mediante DD statements. El programa no hace lógica de negocio; el efecto viene de las sentencias DD.

Ejemplo para crear un PS:

```jcl
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

## 11.3 IEBGENER

`IEBGENER` copia datasets secuenciales.

Ejemplo de backup:

```jcl
//BACKUP  JOB (ACCT),'BACKUP DATOS',NOTIFY=&SYSUID
//BKPLIBR EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=KC03G24.GRUPO6.DATA.INPUT2,DISP=SHR
//SYSUT2   DD DSN=KC03G24.GRUPO6.BACKUP.INPUT2,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(5,2)),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=229,BLKSIZE=0)
```

---

## 12. Plantilla de ejecución batch simple

```jcl
//RUNBAT   JOB (ACCT),'EJECUTAR BATCH',NOTIFY=&SYSUID
//STEP1    EXEC PGM=PROGRAMA
//STEPLIB  DD DSN=KC02814.GRUPO6.LOAD.LIBRARY,DISP=SHR
//         DD DSN=CEE.SCEERUN,DISP=SHR
//ENTRADA  DD DSN=KC03G24.GRUPO6.DATA.INPUT,DISP=SHR
//REPORTE  DD DSN=KC03G24.GRUPO6.REPORTES.OUTPUT,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(5,5)),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
```

---

## 13. Plantilla de documentación en JCL

```jcl
//*==============================================================*
//* PROCESO: Mantenimiento de usuarios                          *
//* PROGRAMA: USUMANT                                           *
//* AUTOR   : Grupo 6                                           *
//* FECHA   : 2026                                              *
//*                                                              *
//* DESCRIPCION:                                                *
//* Lee usuarios desde archivo fijo, inserta o actualiza DB2 y   *
//* genera reporte de proceso.                                  *
//*                                                              *
//* ENTRADAS:                                                   *
//* - KC03G24.GRUPO6.DATA.INPUT2                                *
//*                                                              *
//* SALIDAS:                                                    *
//* - KC03G24.GRUPO6.REPORTES.OUTPUT2                           *
//*                                                              *
//* PREREQUISITOS:                                              *
//* - Tabla KC03G24.USUARIOS creada.                            *
//* - DBRM disponible para bind.                                *
//* - INPUT2 con RECFM=FB,LRECL=229.                            *
//*==============================================================*
```

---

## 14. Gestión de jobs con Zowe

Enviar job:

```bash
zowe jobs submit data-set "KC02814.GRUPO6.JCL.SOURCE(USUMANT)" \
  --wait-for-output
```

Listar jobs:

```bash
zowe jobs list jobs --owner KC02814
```

Ver estado:

```bash
zowe jobs view job-status-by-jobid "JOB12345"
```

Descargar output:

```bash
zowe jobs download output "JOB12345" --directory "./job-output"
```

Ver spool específico:

```bash
zowe jobs view spool-file-by-id "JOB12345" 2
```

---

## 15. Errores comunes

| Error / síntoma | Causa probable | Acción |
|---|---|---|
| RC=12 en compilación COBOL | Error de sintaxis | Revisar `COBOL.SYSPRINT` |
| COPYBOOK NOT FOUND | `SYSLIB` no incluye copylib correcta | Verificar `COBOL.SYSLIB` |
| UNRESOLVED EXTERNAL | Falta librería en link-edit | Agregar `CEE.SCEELKED`, `DSND10.SDSNLOAD` o módulo requerido |
| SQLCODE -204 | Tabla/objeto no existe o schema incorrecto | Verificar owner y nombre de tabla |
| SQLCODE -206 | Columna inexistente | Comparar SQL embebido contra DDL real |
| SQLCODE -803 | Duplicado por índice único | Manejar como error funcional |
| ABEND S0C7 | Dato numérico inválido | Validar entrada con `NUMERIC` antes de mover/procesar |
| FILE NOT FOUND | Dataset inexistente o DD mal nombrado | Revisar `DSN`, `DISP` y DD del COBOL |
| OPEN OUTPUT falla | Dataset ya existe con `DISP=NEW` | Borrar antes con `IDCAMS` o ajustar `DISP` |
| Registros truncados | `LRECL` incorrecto | Recrear dataset con el LRECL esperado por el COBOL |

---

## 16. Checklist antes de enviar un job

- [ ] El miembro JCL está en el PDS correcto.
- [ ] El nombre del programa coincide con `PROGRAM-ID`, miembro COBOL y `RUN PROGRAM`.
- [ ] Los datasets de entrada existen.
- [ ] Los datasets de salida no existen si se usan con `DISP=NEW`.
- [ ] El `LRECL` coincide con el `FD` COBOL.
- [ ] `STEPLIB` incluye load library del proyecto.
- [ ] Para DB2, `STEPLIB` incluye librerías DB2.
- [ ] Para DB2, el plan y member usados en `BIND` son correctos.
- [ ] Las tablas DB2 existen y el SQL embebido usa columnas reales.
- [ ] El usuario tiene permisos sobre tablas, índices, secuencias y plan.

## 17. Checklist después de ejecutar

- [ ] Revisar `JESMSGLG`, `JESJCL` y `JESYSMSG`.
- [ ] Verificar RC de cada step.
- [ ] Revisar `SYSPRINT`, `SYSTSPRT` y salidas COBOL.
- [ ] Confirmar creación de reportes.
- [ ] Validar contenido de reportes.
- [ ] Guardar evidencia si corresponde para la entrega.
- [ ] Limpiar temporales o outputs de prueba si corresponde.
