//PRESTAM  JOB (UNLAM),'PRESTAM DB2',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID
//*
//*==============================================================*
//* COMPILA, BINDEA Y EJECUTA PRESTAM                           *
//* SUBSISTEMA: DBDG                                            *
//* ENTRADA : KC03G24.GRUPO6.DATA.INPUT3                        *
//* REPORTE : KC03G24.GRUPO6.REPORTES.OUTPUT3                   *
//* INPUT3  : RECFM=FB,LRECL=140                                *
//* OUTPUT3 : RECFM=FB,LRECL=133                                *
//*==============================================================*
//SETPROG  SET PROG=PRESTAM
//*
//*--------------------------------------------------------------*
//* COMPILACION COBOL CON DB2                                   *
//*--------------------------------------------------------------*
//COMPILE  EXEC IGYWCL,
//         PARM.COBOL='SQL,RENT,OBJECT'
//COBOL.STEPLIB DD DSN=IGY640.SIGYCOMP,DISP=SHR
//              DD DSN=DSND10.SDSNLOAD,DISP=SHR
//              DD DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//COBOL.SYSLIB  DD DSN=KC02814.GRUPO6.COBOL.COPYLIB,DISP=SHR
//COBOL.SYSIN   DD DSN=KC02814.GRUPO6.COBOL.SOURCE(&PROG),DISP=SHR
//COBOL.DBRMLIB DD DSN=KC02814.GRUPO6.DBRM(&PROG),DISP=SHR
//LKED.SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//              DD DSN=DSND10.SDSNLOAD,DISP=SHR
//LKED.SYSLMOD  DD DSN=KC02814.GRUPO6.LOAD.LIBRARY(&PROG),DISP=SHR
//*
//*--------------------------------------------------------------*
//* BORRA REPORTE ANTERIOR SIN FALLAR SI NO EXISTE              *
//*--------------------------------------------------------------*
//LIMPIEZA EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE KC03G24.GRUPO6.REPORTES.OUTPUT3
  SET MAXCC = 0
/*
//*
//*--------------------------------------------------------------*
//* BIND Y EJECUCION                                            *
//*--------------------------------------------------------------*
//STEP1    EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT)
//STEPLIB  DD DSN=DSND10.SDSNLOAD,DISP=SHR
//         DD DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR
//         DD DSN=DSND10.DBDG.RUNLIB.LOAD,DISP=SHR
//         DD DSN=KC02814.GRUPO6.LOAD.LIBRARY,DISP=SHR
//DBRMLIB  DD DSN=KC02814.GRUPO6.DBRM,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//ENTRADA  DD DSN=KC03G24.GRUPO6.DATA.INPUT3,DISP=SHR
//REPORTE  DD DSN=KC03G24.GRUPO6.REPORTES.OUTPUT3,
//            DISP=(NEW,CATLG,DELETE),
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=1330),
//            SPACE=(TRK,(5,5)),UNIT=SYSALLDA
//SYSTSIN  DD *
  DSN SYSTEM(DBDG)
  BIND PLAN(GRUPO6) MEMBER(PRESTAM) -
       ACTION(REPLACE) ISOLATION(CS) ENCODING(EBCDIC)
  RUN PROGRAM(PRESTAM) PLAN(GRUPO6) -
      LIB('KC02814.GRUPO6.LOAD.LIBRARY')
  END
/*
