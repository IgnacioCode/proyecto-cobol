//CICSMAP  JOB (UNLAM),'COMP BMS CICS',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID
//*
//*==============================================================*
//* COMPILA UN MAPA BMS DEL SISTEMA DE BIBLIOTECA                *
//* CAMBIAR MAPA POR BIBMENU, BIBCONS O BIBPRES Y REENVIAR.     *
//* GENERA:                                                      *
//* - LOAD DEL MAPSET EN KC02814.GRUPO6.LOAD.LIBRARY            *
//* - COPYBOOK COBOL EN KC02814.GRUPO6.COBOL.COPYLIB            *
//*==============================================================*
//SETMAP   SET MAPA=BIBMENU
//*
//JCLLIB   ORDER=(DFH610.CICS.ADFHPROC)
//STEP1    EXEC DFHMAPS,
//         INDEX='DFH610.CICS',
//         MAPLIB='KC02814.GRUPO6.LOAD.LIBRARY',
//         DSCTLIB='KC02814.GRUPO6.COBOL.COPYLIB',
//         MAPNAME=&MAPA
//COPY.SYSUT1 DD DSN=KC02814.GRUPO6.BMS.SOURCE(&MAPA),DISP=SHR
//LINKMAP.SYSLMOD DD DSN=KC02814.GRUPO6.LOAD.LIBRARY(&MAPA),
//         DISP=SHR
/*
