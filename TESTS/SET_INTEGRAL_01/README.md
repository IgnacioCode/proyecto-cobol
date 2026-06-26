# Set integral 01 - Biblioteca Grupo 6

Este set prueba el flujo completo de los 4 programas batch:

1. `CARGINI` carga libros.
2. `USUMANT` carga, actualiza y rechaza usuarios.
3. `PRESTAM` registra prestamos, devoluciones y errores funcionales.
4. `REPORTES` genera los 4 reportes sobre el estado final.

## Precondiciones

- Ejecutar sobre una base limpia, idealmente despues de recrear objetos con `RUNSQL`.
- La secuencia `KC03G24.SEQ_PRESTAMOS` debe arrancar en 1.
- Ejecutar los programas en este orden: `CARGINI`, `USUMANT`, `PRESTAM`, `REPORTES`.
- Subir estos archivos a los datasets reales:

| Archivo local | Dataset destino | LRECL |
|---|---|---:|
| `DATA.INPUT` | `KC03G24.GRUPO6.DATA.INPUT` | 200 |
| `DATA.INPUT2` | `KC03G24.GRUPO6.DATA.INPUT2` | 229 |
| `DATA.INPUT3` | `KC03G24.GRUPO6.DATA.INPUT3` | 140 |
| `DATA.INPUT4` | `KC03G24.GRUPO6.DATA.INPUT4` | 80 |

Si la base no esta limpia, pueden cambiar los resultados por duplicados,
stock previo, usuarios existentes o numeros de prestamo distintos.

## Entrada 1 - CARGINI

`DATA.INPUT` contiene 6 libros. Cinco son validos y uno fuerza error por
stock no numerico.

| # | Codigo | Categoria | Stock | Resultado esperado |
|---:|---|---|---:|---|
| 1 | `LIBTST0001` | `PROGRAMACION` | 2 | Insert OK |
| 2 | `LIBTST0002` | `BASE DE DATOS` | 1 | Insert OK |
| 3 | `LIBTST0003` | `MATEMATICA` | 3 | Insert OK |
| 4 | `LIBTST0004` | `REDES` | 1 | Insert OK |
| 5 | `LIBTST0005` | `SISTEMAS` | 1 | Insert OK |
| 6 | `LIBTST0006` | `PRUEBAS` | `ABC` | Error de validacion |

Salida esperada en `REPORTES.OUTPUT`:

| Metrica | Esperado |
|---|---:|
| Registros leidos | 6 |
| Libros insertados/procesados | 5 |
| Errores | 1 |

## Entrada 2 - USUMANT

`DATA.INPUT2` contiene altas, una actualizacion y errores de usuario.

| # | Codigo | Tipo | Estado | Caso | Resultado esperado |
|---:|---|---|---|---|---|
| 1 | `USUTST0001` | `E` | `A` | Alta estudiante | Insert OK |
| 2 | `USUTST0002` | `D` | `A` | Alta docente | Insert OK |
| 3 | `USUTST0003` | `A` | `A` | Alta administrativo | Insert OK |
| 4 | `USUTST0004` | `E` | `I` | Usuario inactivo | Insert OK |
| 5 | `USUTST0005` | `E` | `A` | Alta estudiante | Insert OK |
| 6 | `USUTST0006` | `D` | `A` | Alta docente | Insert OK |
| 7 | `USUTST0007` | `X` | `A` | Tipo invalido | Rechazado |
| 8 | `USUTST0001` | `E` | `A` | Misma PK, datos nuevos | Update OK |
| 9 | `USUTST0008` | `E` | `A` | Email duplicado con usuario 2 | SQL -803 esperado |

Salida esperada en `REPORTES.OUTPUT2`:

| Metrica | Esperado |
|---|---:|
| Registros leidos | 9 |
| Insertados | 6 |
| Actualizados | 1 |
| Errores | 2 |

## Entrada 3 - PRESTAM

`DATA.INPUT3` cubre prestamos validos, errores funcionales, devoluciones
con multa y un prestamo pendiente vencido para el reporte.

| # | Op | Prestamo esperado | Usuario | Libro | Fecha | Resultado esperado |
|---:|---|---:|---|---|---|---|
| 1 | `P` | 1 | `USUTST0001` | `LIBTST0001` | 2026-06-01 | Prestamo OK |
| 2 | `P` | 2 | `USUTST0002` | `LIBTST0001` | 2026-06-02 | Prestamo OK |
| 3 | `P` | 3 | `USUTST0003` | `LIBTST0002` | 2026-06-03 | Prestamo OK |
| 4 | `P` | 4 | `USUTST0005` | `LIBTST0003` | 2026-06-10 | Prestamo OK; queda vencido al 2026-06-30 |
| 5 | `P` | - | `USUTST0004` | `LIBTST0003` | 2026-06-04 | Error usuario inactivo |
| 6 | `P` | - | `USUTST9999` | `LIBTST0003` | 2026-06-05 | Error usuario inexistente |
| 7 | `P` | - | `USUTST0005` | `LIBTST9999` | 2026-06-06 | Error libro inexistente |
| 8 | `P` | - | `USUTST0006` | `LIBTST0001` | 2026-06-11 | Error sin stock |
| 9 | `D` | 1 | `USUTST0001` | `LIBTST0001` | 2026-06-20 | Devolucion OK; multa 200.00 |
| 10 | `P` | 5 | `USUTST0006` | `LIBTST0001` | 2026-06-21 | Prestamo OK tras devolucion |
| 11 | `D` | 3 | `USUTST0003` | `LIBTST0002` | 2026-06-25 | Devolucion OK; multa 100.00 |
| 12 | `D` | 99 | - | - | 2026-06-26 | Error prestamo inexistente |

Salida esperada en `REPORTES.OUTPUT3`:

| Metrica | Esperado |
|---|---:|
| Registros leidos | 12 |
| Prestamos OK | 5 |
| Devoluciones OK | 2 |
| Errores | 4 |

Estado esperado despues de `PRESTAM`:

| Libro | Stock total | Stock disponible esperado | Motivo |
|---|---:|---:|---|
| `LIBTST0001` | 2 | 0 | Prestamos 2 y 5 pendientes; prestamo 1 devuelto |
| `LIBTST0002` | 1 | 1 | Prestamo 3 devuelto |
| `LIBTST0003` | 3 | 2 | Prestamo 4 pendiente vencido |
| `LIBTST0004` | 1 | 1 | Sin movimientos |
| `LIBTST0005` | 1 | 1 | Sin movimientos |

## Entrada 4 - REPORTES

`DATA.INPUT4` filtra el periodo completo de junio:

```text
2026-06-01 2026-06-30
```

Salida esperada en `REPORTES.OUTPUT4`:

| Seccion | Resultado esperado |
|---|---|
| Libros mas prestados | `LIBTST0001` con 3 prestamos; `LIBTST0002` con 1; `LIBTST0003` con 1 |
| Usuarios con prestamos vencidos | Prestamo 4, usuario `USUTST0005`, libro `LIBTST0003`, limite 2026-06-25, estado `P` |
| Estadisticas mensuales | Mes 2026-06: 5 prestamos, 2 devoluciones, multas 300.00 |
| Inventario por categoria | `PROGRAMACION` stock 2/0, `BASE DE DATOS` 1/1, `MATEMATICA` 3/2, `REDES` 1/1, `SISTEMAS` 1/1 |

## Criterios de aceptacion

- Los 4 jobs terminan con RC aceptable (`0` o `4`, segun mensajes del entorno).
- No aparecen `SQLCODE -206` ni `SQLCODE -204`.
- Los errores funcionales esperados se reportan sin ABEND.
- Los totales de cada output coinciden con las tablas anteriores.
- `OUTPUT4` contiene informacion en las cuatro secciones.
