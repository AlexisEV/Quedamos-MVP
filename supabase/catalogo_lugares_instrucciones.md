# Catálogo de lugares: instrucciones de llenado

`catalogo_lugares.csv` es la fuente del catálogo manual (RF11 · RB09). A partir de él se genera `seed.sql`.

- Una fila por lugar real de Arequipa; total entre 20 y 30, repartidos en las 5 zonas y las 4 categorías.
- Codificación UTF-8 y separador coma. Si un texto lleva comas, va entre comillas dobles.
- **Dato desconocido o sin verificar: celda vacía.** Nunca `0`, `-` ni valores aproximados inventados.

| Columna | Obligatoria | Formato |
|---|---|---|
| `nombre` | sí | texto |
| `categoria` | sí | `restaurantes`, `cafes_y_postres`, `bares`, `entretenimiento_y_cultura` |
| `zona` | sí | `centro_historico`, `yanahuara`, `cayma`, `vallecito`, `cercado` |
| `direccion` | no | texto, por ejemplo `Calle Jerusalén 123` |
| `latitud`, `longitud` | no | decimal con punto y hasta 6 decimales, por ejemplo `-16.398800` |
| `horario_atencion` | no | texto libre, por ejemplo `Lun a sáb 12:00–17:00` |
| `precio_estimado_pen` | no | soles por persona con punto decimal, por ejemplo `38.00`; `0` solo si es gratis de verdad |
| `precio_nota` | no | qué incluye el precio, por ejemplo `plato de fondo y bebida` |
| `fuente` | sí | procedencia del dato: visita, carta, página oficial, llamada, etc. |
| `fecha_revision` | sí | fecha en que se verificó, `AAAA-MM-DD` |
