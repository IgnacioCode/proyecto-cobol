# Trabajo Práctico Integrador Final

## Sistema de Gestión de Biblioteca Universitaria

Materia: **Electiva I - Lenguaje Orientado a Negocios (COBOL)**  
Universidad: **Universidad Nacional de La Matanza - DIIT**  
Responsable: **Ing. Adrian Gonzalez**  
Año académico: **2026**

---

## Información general

El proyecto consiste en desarrollar un sistema completo de gestión de biblioteca universitaria utilizando tecnologías Mainframe vistas durante la cursada.

El sistema debe integrar programas batch, programas CICS, base de datos DB2, JCL, copybooks y reportes.

### Objetivo funcional

Construir un sistema que permita:

- Gestionar préstamos de libros.
- Administrar usuarios: estudiantes, docentes y administrativos.
- Mantener inventario de libros.
- Generar reportes estadísticos.
- Proveer interfaces interactivas para consultas y operaciones.

### Tecnologías requeridas

- Lenguaje: COBOL.
- Plataforma: IBM z/OS Mainframe.
- Acceso: Zowe CLI / z/OSMF.
- Base de datos: DB2.
- Interfaz interactiva: CICS con mapas BMS.
- Control de trabajos: JCL.

---

## Arquitectura del sistema

El sistema se organiza en tres grandes bloques:

```text
+-------------------+   +-------------------+   +-------------------+
| PROGRAMAS BATCH   |   | INTERFACES CICS   |   | BASE DE DATOS DB2 |
+-------------------+   +-------------------+   +-------------------+
| CARGINI           |   | BIBMENU           |   | USUARIOS          |
| USUMANT           |   | BIBCONS           |   | LIBROS            |
| PRESTAM           |   | BIBPRES           |   | PRESTAMOS         |
| REPORTES          |   |                   |   |                   |
+-------------------+   +-------------------+   +-------------------+
```

### Flujo general de datos

1. **Carga inicial**: programas batch cargan datos maestros.
2. **Operaciones diarias**: CICS maneja consultas y transacciones.
3. **Reportes**: programas batch generan estadísticas y listados.
4. **Mantenimiento**: CICS y/o batch permiten actualizar datos.

---

## Especificaciones funcionales

## 1. Gestión de usuarios

### Tipos de usuario

| Tipo | Código | Límite de libros | Días de préstamo |
|---|---:|---:|---:|
| Estudiante | E | 3 | 15 |
| Docente | D | 10 | 30 |
| Administrativo | A | 5 | 20 |

### Funciones

- Alta, baja y modificación de usuarios.
- Validación de límites de préstamos.
- Control de usuarios con préstamos vencidos.
- Validación de email único.
- Validación de tipo de usuario.

## 2. Gestión de libros

### Información del libro

- Código único de 10 caracteres.
- Título.
- Autor.
- Editorial.
- Categoría.
- Stock total.
- Stock disponible.
- Ubicación física.

### Funciones

- Carga masiva de libros.
- Consulta por código, título, autor o categoría.
- Control de stock en tiempo real.

## 3. Gestión de préstamos

### Reglas de negocio

- Validar stock disponible.
- Verificar límites por tipo de usuario.
- No permitir préstamos cuando el usuario tenga préstamos vencidos.
- Calcular fecha de devolución automáticamente.
- Registrar multas por retraso.

### Funciones

- Registro de préstamos.
- Proceso de devoluciones.
- Consulta de préstamos activos.
- Cálculo de multas.

## 4. Reportes

Reportes requeridos:

- Libros más prestados.
- Usuarios con préstamos vencidos.
- Estadísticas mensuales.
- Inventario por categoría.

---

## Componentes técnicos a desarrollar

## A. Programas batch COBOL

### 1. CARGINI - Carga inicial de libros

Función: procesar archivo de libros y cargar la base de datos.

- Entrada: archivo con datos de libros.
- Salida: tabla `LIBROS` actualizada y reporte de carga.
- Validaciones: código único, datos obligatorios y formato.

### 2. USUMANT - Mantenimiento de usuarios

Función: procesar transacciones o registros de usuarios.

- Entrada: archivo de usuarios/transacciones.
- Salida: tabla `USUARIOS` actualizada y reporte del proceso.
- Validaciones: email único y tipo de usuario válido.

Implementación adoptada en este repo:

- Programa: `COBOL.SOURCE/USUMANT.cbl`.
- JCL: `JCL.SOURCE/USUMANT.jcl`.
- Entrada: `KC03G24.GRUPO6.DATA.INPUT2`.
- Salida: `KC03G24.GRUPO6.REPORTES.OUTPUT2`.
- Lógica: si el usuario existe se actualiza; si no existe se inserta.
- Baja lógica: se representa con `ESTADO = 'I'`.

### 3. PRESTAM - Procesamiento de préstamos

Función: procesar préstamos y devoluciones.

- Entrada: archivo de transacciones de préstamos.
- Salida: tablas actualizadas y control de stock.
- Validaciones: reglas de negocio completas.

### 4. REPORTES - Generación de reportes

Función: generar reportes estadísticos.

- Entrada: parámetros de fechas.
- Salida: reportes formateados.
- Contenido: estadísticas de uso y control.

---

## B. Programas CICS COBOL + BMS

### 1. BIBMENU - Menú principal

Pantalla principal del sistema.

Opciones esperadas:

- 1 - Consultas.
- 2 - Usuarios.
- 3 - Préstamos.
- 4 - Reportes.
- X - Salir.

Debe controlar el flujo entre transacciones.

### 2. BIBCONS - Consulta de libros

Pantalla de búsqueda de libros por múltiples criterios.

Debe permitir:

- Consulta interactiva.
- Paginación.
- Visualización de resultados con datos relevantes.

### 3. BIBPRES - Préstamos y devoluciones

Pantalla para registrar préstamos y devoluciones.

Debe permitir:

- Validación en tiempo real.
- Integración con DB2.
- Actualización de stock.
- Registro de préstamos y devoluciones.

---

## C. Base de datos DB2

Tablas principales:

- `USUARIOS`: datos de estudiantes, docentes y administrativos.
- `LIBROS`: catálogo completo de libros.
- `PRESTAMOS`: registro de transacciones de préstamo y devolución.

Características requeridas:

- Claves primarias.
- Claves foráneas.
- Índices para optimizar consultas.
- Constraints para validar datos.
- Triggers de auditoría opcionales.

### Esquema de usuarios usado como referencia actual

```sql
CREATE TABLE KC03G24.USUARIOS (
  COD_USUARIO    CHAR(10)     NOT NULL,
  NOMBRE         VARCHAR(30)  NOT NULL,
  APELLIDO       VARCHAR(30)  NOT NULL,
  TIPO_USUARIO   CHAR(1)      NOT NULL,
  EMAIL          VARCHAR(50)  NOT NULL,
  TELEFONO       VARCHAR(20),
  DIRECCION      VARCHAR(60),
  FECHA_ALTA     DATE,
  FECHA_BAJA     DATE,
  ESTADO         CHAR(1)      DEFAULT 'A',
  CONSTRAINT PK_USUARIOS PRIMARY KEY (COD_USUARIO),
  CONSTRAINT CK_TIPO CHECK (TIPO_USUARIO IN ('E','D','A')),
  CONSTRAINT CK_ESTADO_USU CHECK (ESTADO IN ('A','I'))
) IN UNLAM.G6USU;
```

---

## Estructura de archivos esperada

Datasets requeridos por la consigna:

```text
KC03xxx.COBOL.SOURCE     Programas fuente COBOL
KC03xxx.COBOL.COPYLIB    Copybooks compartidos
KC03xxx.BMS.SOURCE       Mapas CICS
KC03xxx.JCL.SOURCE       Procedimientos JCL
KC03xxx.SQL.SOURCE       Scripts de base de datos
KC03xxx.DATA.INPUT       Archivos de entrada
KC03xxx.LOAD.LIBRARY     Programas compilados
KC03xxx.REPORTES.OUTPUT  Reportes generados
```

Estructura equivalente dentro del repo:

```text
COBOL.SOURCE/
COBOL.COPYLIB/
BMS.SOURCE/
JCL.SOURCE/
SQL.SOURCE/
DBRM/
LOAD.LIBRARY/
DOCS/
```

---

## Copybooks necesarios

- `LIBRO`: estructura de datos de libros.
- `USUARIO`: estructura de datos de usuarios.
- `PRESTAMO`: estructura de préstamos.
- `CONSTANT`: constantes del sistema.
- `MENSAJES`: mensajes de error.
- `LINREP`: layouts de reportes.

---

## Entregables

## 1. Código fuente

Programas y artefactos requeridos:

- 4 programas COBOL batch compilados y funcionando.
- 3 programas CICS con mapas BMS.
- 6 copybooks documentados.
- Scripts SQL para crear y poblar tablas.
- JCL para compilación y ejecución.

## 2. Testing y validación

Evidencia esperada:

- Casos de prueba documentados.
- Screenshots de ejecuciones exitosas.
- Manejo de casos de error.
- Datos de prueba consistentes.

## 3. Presentación

Demo en vivo de 15 a 20 minutos.

Debe incluir:

- Demostración del sistema funcionando.
- Explicación de decisiones técnicas.
- Respuesta a preguntas del profesor.
- Dominio técnico del código desarrollado.

---

## Notas de implementación del repo

Estas notas reflejan decisiones y estado actual del proyecto local:

- Owner/esquema usado en DB2: `KC03G24`.
- Grupo: `GRUPO6`.
- Subsistema DB2 observado en JCL: `DBDG`.
- Planes observados: `GRUPO6`, `CURSOG06`, `DSNTEP13`.
- `RUNSQL.jcl` contiene el DDL operativo con nombres de columnas sin prefijo para `USUARIOS`, por ejemplo `COD_USUARIO`, `NOMBRE`, `EMAIL`.
- `USUMANT.cbl` debe alinearse con ese DDL real para evitar `SQLCODE -206`.
- Los archivos de entrada de ancho fijo deben tener `LRECL` compatible con el layout COBOL.
