# Catálogo de lugares: instrucciones de llenado

`supabase/catalogo_lugares.csv` es la fuente del catálogo manual (RF11 · RB09). A partir de él se genera `seed.sql`
(un `insert` idempotente por fila: no repite un lugar con el mismo `nombre` y `zona`).

- Una fila por lugar real de Arequipa; total entre 20 y 30, repartidos en las 5 zonas y las 4 categorías.
- Codificación UTF-8 y separador coma. Si un texto lleva comas, va entre comillas dobles.
- **Dato desconocido o sin verificar: celda vacía.** Nunca `0`, `-` ni valores aproximados inventados.
- `nombre`, `direccion` y `horario_atencion` se muestran en la app: sin citas de fuente ni notas internas.
- `precio_nota` y `fuente` son referencia interna del equipo: `precio_nota` no se carga en la base y
  `fuente` se guarda pero la app no la muestra.

| Columna | Obligatoria | Formato |
|---|---|---|
| `nombre` | sí | texto |
| `categoria` | sí | `restaurantes`, `cafes_y_postres`, `bares`, `entretenimiento_y_cultura` |
| `zona` | sí | `centro_historico`, `yanahuara`, `cayma`, `vallecito`, `cercado` |
| `direccion` | no | texto, por ejemplo `Calle Jerusalén 123` |
| `latitud`, `longitud` | no | decimal con punto y hasta 6 decimales, por ejemplo `-16.398800` |
| `horario_atencion` | no | `Lun–Vie: 08:00–20:00; Sáb–Dom: 09:00–21:00`; día sin atención: `Lun: Cerrado` |
| `precio_estimado_pen` | no | soles por persona con punto decimal, por ejemplo `38.00`; `0` solo si es gratis de verdad |
| `precio_nota` | no | nota interna sobre cómo se estimó el precio (no se carga) |
| `fuente` | sí | procedencia del dato: visita, carta, página oficial, llamada, etc. |
| `fecha_revision` | sí | fecha en que se verificó, `AAAA-MM-DD` |
