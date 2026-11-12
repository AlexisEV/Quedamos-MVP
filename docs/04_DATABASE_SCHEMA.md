# 04 · Esquema de base de datos — Supabase / PostgreSQL

Versión 1.7 · 2026-11-11 (13 migraciones aplicadas en desarrollo y en `quedamos-demo`, ver §0) · Versión 1.6 · 2026-10-24 · Basado en `06_REQUIREMENTS.md` §11 (modelo conceptual) y decisiones del 2026-10-21 (sin FCM, sin Edge Functions ni Cron en la primera iteración) y del 2026-10-22 (propuestas únicas por plan, retiro de propuestas, recomendaciones, plazos opcionales, asistencia sin vuelta a pendiente). v1.3: `crear_plan` implementada con `p_plan_id` idempotente. v1.4: `unirse_con_codigo` y `nombrar_administrador` implementadas. v1.5: tabla `lugares` creada. v1.6: `propuestas`, `candidatos`, `proponer_lugar` y `retirar_propuesta` implementadas.

> **§0 · Migraciones (2026-11-11).** Aplicadas en desarrollo y en `quedamos-demo` (etiqueta `semana-3`), en este orden: `20261022120000_crear_tablas_base` · `20261022140000_rpc_crear_plan` · `20261023120000_rpc_unirse_con_codigo` · `20261023140000_rpc_nombrar_administrador` · `20261024120000_crear_tabla_lugares` · `20261025120000_propuestas_y_candidatos` · `20261025140000_preparar_votacion` · `20261025160000_votar` · `20261025180000_cerrar_votacion` · `20261109120000_revisar_itinerario` · `20261109150000_asistencia` · `20261110120000_reemplazo_y_cancelacion` · `20261110150000_notificaciones`. Una migración nueva lleva prefijo de fecha posterior, **solo agrega objetos** (no edita migraciones ya aplicadas), se prueba en un bloque revertido y se aplica primero en desarrollo; a la demo llega con el procedimiento semanal (`05_ARCHITECTURE.md` §6).
>
> Historial anterior (detalle de verificación de las primeras migraciones): `20261022120000_crear_tablas_base.sql` (2026-10-22; enums, `perfiles`, `planes`, `participaciones`, funciones auxiliares, RLS de esas 3 tablas) · `20261022140000_rpc_crear_plan.sql` (2026-10-22; `generar_codigo_invitacion()` interna y RPC `crear_plan`) · `20261023120000_rpc_unirse_con_codigo.sql` (2026-10-23; RPC `unirse_con_codigo`) · `20261023140000_rpc_nombrar_administrador.sql` (2026-10-23; RPC `nombrar_administrador`) · `20261024120000_crear_tabla_lugares.sql` (2026-10-24; tabla `lugares`, trigger `lugares_fijar_updated_at`, RLS `lugares_select_publicados`; verificado con SQL revertido: solo se leen publicados, `insert` de `authenticated` rechazado por RLS, `update` sin filas afectadas) · `20261025120000_propuestas_y_candidatos.sql` (2026-10-24; tablas `propuestas` y `candidatos` con RLS de lectura `es_participante`, RPC `proponer_lugar` y `retirar_propuesta`; verificadas con SQL revertido y dos cuentas).
>
> Este documento es el **diseño de referencia**. La fuente ejecutable serán las migraciones en `supabase/migrations/*.sql` (nombres `snake_case` con prefijo de fecha). Si se cambia una tabla, actualizar primero aquí y luego crear la migración.

## 1. Convenciones

- Identificadores SQL (tablas, columnas, funciones, tipos) en `snake_case`, plural para tablas. En Dart se mapean a propiedades `camelCase` (`presupuesto_soles` → `presupuestoSoles`).
- Claves primarias `uuid` con `gen_random_uuid()`; fechas en `timestamptz` (UTC en base; la app muestra y programa en `America/Lima`).
- Dinero en `numeric(10,2)` en soles (PEN).
- **Toda escritura con reglas de negocio pasa por funciones RPC** `security definer` (transaccionales, validan rol, fase y límites). Las tablas no tienen políticas de `insert/update/delete` para el rol `authenticated` salvo las indicadas. Ocultar un botón en la app no sustituye esta validación (RNF03).
- Comentarios SQL en minúsculas, sin signos `!` ni `?` (ver `AGENTS.md`).

## 2. Tipos enumerados

```sql
-- estados definitivos; el flujo es unidireccional y no se retrocede de fase
create type plan_estado as enum (
  'recibiendo_propuestas', 'en_votacion', 'preparando_itinerario', 'confirmado', 'cancelado'
);

create type rol_plan as enum ('administrador', 'participante');
create type asistencia_estado as enum ('pendiente', 'asistire', 'no_asistire');
create type notificacion_tipo as enum ('actividad', 'voto', 'asistencia', 'cambio', 'cancelacion');
create type notificacion_estado as enum ('activa', 'anulada');

create type lugar_zona as enum (
  'centro_historico', 'yanahuara', 'cayma', 'vallecito', 'cercado'
); -- etiquetas visibles: centro histórico, yanahuara, cayma, vallecito, cercado

create type lugar_categoria as enum (
  'restaurantes', 'cafes_y_postres', 'bares', 'entretenimiento_y_cultura'
); -- etiquetas visibles: restaurantes, cafés y postres, bares, entretenimiento y cultura
```

Las etiquetas con tildes y mayúsculas (`Centro Histórico`, `Cafés y Postres`, …) se resuelven en la app (`core/utils`), no en la base.

**Transiciones permitidas** (validadas en cada RPC):

```
recibiendo_propuestas ─▶ en_votacion ─▶ preparando_itinerario ─▶ confirmado
          └──────────────────┴───────────────────┴──────────────────┴─▶ cancelado
```

No existe reapertura de votación ni retroceso de fase. `cancelado` es final.

## 3. Tablas

### 3.1 `perfiles` (1:1 con `auth.users`)

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | `references auth.users(id) on delete cascade` |
| nombre_visible | text not null | obligatorio en el registro; `check (length(trim(nombre_visible)) between 1 and 40)` |
| created_at / updated_at | timestamptz | `default now()` |

Se crea con un trigger `after insert on auth.users` que copia `raw_user_meta_data->>'nombre_visible'` (la app lo envía en `signUp(data: {...})`). El correo se lee de `auth.users` (no se duplica). Auth con **«Confirm email» desactivado**: el registro deja la sesión iniciada sin correo de confirmación; no se usa SMTP.

### 3.2 `lugares` (catálogo manual — RF11)

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| nombre | text not null | |
| categoria | lugar_categoria not null | 4 categorías fijas |
| zona | lugar_zona not null | 5 zonas fijas |
| direccion | text null | |
| latitud / longitud | numeric(9,6) null | |
| horario_atencion | text null | texto libre; null = desconocido |
| precio_estimado_pen | numeric(10,2) null | por persona; null = desconocido (no inventar) |
| precio_nota | text null | componentes/unidad del precio |
| imagen_path | text null | ruta en Storage bucket `lugares` (opcional en MVP) |
| fuente | text not null | procedencia del dato (RNF07) |
| fecha_revision | date not null | fecha en que el equipo verificó el dato |
| publicado | boolean default true | |
| created_at / updated_at | timestamptz | |

Checks implementados: `nombre` y `fuente` no vacíos tras `trim`, `precio_estimado_pen >= 0`, latitud entre −90 y 90 y longitud entre −180 y 180; `publicado` y fechas `not null`. Las imágenes se omiten por ahora (`imagen_path` null).

Carga: `supabase/seed.sql` (generado desde `supabase/catalogo_lugares.csv`; `precio_nota` no se carga, ver `03_DECISIONS.md` 2026-10-25; 28 lugares en desarrollo) con **20–30 lugares reales** de Arequipa repartidos en las 5 zonas y 4 categorías. Solo el equipo modifica el catálogo (SQL / dashboard).

### 3.3 `planes`

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| nombre | text not null | obligatorio |
| estado | plan_estado | default `recibiendo_propuestas` |
| presupuesto_soles | numeric(10,2) not null | por persona, solo actividades, toda la salida |
| max_propuestas_por_persona | smallint default 3 | `check between 1 and 5`; se fija al crear |
| max_candidatos | smallint default 6 | `check between 2 and 10` |
| max_selecciones | smallint default 3 | `check between 1 and 5` y `check (max_selecciones <= max_candidatos)` |
| max_actividades | smallint default 3 | `check between 1 and 5` |
| fecha_limite_voto | timestamptz null | **opcional**; lo fija un administrador; sin valor no hay recordatorio de voto |
| fecha_limite_asistencia | timestamptz null | **opcional**; *soft deadline*: sin valor no hay recordatorio; vencido no bloquea respuestas |
| codigo_invitacion | char(6) unique not null | `check (codigo_invitacion ~ '^[A-Z0-9]{6}$')`; generado en servidor |
| creado_por | uuid FK → perfiles | |
| votacion_abierta_en / votacion_cerrada_en / confirmado_en / cancelado_en | timestamptz null | trazabilidad de fases |
| created_at / updated_at | timestamptz | |

Check: `presupuesto_soles >= 0`. El código **no caduca**; queda inactivo solo cuando `estado = 'cancelado'` (no hay columna aparte).

### 3.4 `participaciones`

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| plan_id | uuid FK → planes | `on delete cascade` |
| perfil_id | uuid FK → perfiles | |
| rol | rol_plan | default `participante`; creador = `administrador` |
| es_creador | boolean default false | el creador no puede perder el rol ni abandonar el plan |
| asistencia | asistencia_estado | default `pendiente` solo como valor inicial; la RPC solo acepta `asistire` / `no_asistire` (RF16) |
| asistencia_actualizada_en | timestamptz null | |
| votos_guardados_en | timestamptz null | no nulo = ya guardó elecciones (completa la acción de voto) |
| unido_en | timestamptz default now() | |

`unique (plan_id, perfil_id)` → unirse dos veces no duplica (RF02). El rol de administrador es **permanente**: no existe RPC para retirarlo.

### 3.5 `propuestas`

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| plan_id | uuid FK → planes | |
| lugar_id | uuid FK → lugares | solo lugares del catálogo |
| propuesto_por | uuid FK → perfiles | |
| created_at | timestamptz | |

`unique (plan_id, lugar_id)` → **un lugar solo puede proponerse una vez por plan**. Si ya fue propuesto por otro integrante, la RPC devuelve `lugar_ya_propuesto` y la UI lo muestra como «Ya propuesto»; no consume el límite de nadie más. El límite `max_propuestas_por_persona` cuenta las filas con `propuesto_por = auth.uid()` en el plan. Altas y retiros solo en `recibiendo_propuestas`.

### 3.6 `candidatos` (lista final elegida por administradores)

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| plan_id | uuid FK → planes | |
| lugar_id | uuid FK → lugares | |
| total_votos | integer null | instantánea calculada al cerrar la votación |
| seleccionado | boolean default false | pasa al itinerario (tras cierre y desempate) |
| created_at | timestamptz | |

`unique (plan_id, lugar_id)`. Inmutable desde `en_votacion` (RB07).

### 3.7 `votos`

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| plan_id | uuid FK → planes | redundante para filtrar/RLS |
| candidato_id | uuid FK → candidatos | `on delete cascade` |
| perfil_id | uuid FK → perfiles | |
| created_at | timestamptz | |

`unique (candidato_id, perfil_id)` → cada lugar cuenta una vez por persona. Índice `votos_plan_perfil_idx (plan_id, perfil_id)`. `guardar_votos` reemplaza la selección completa en una transacción, de modo que el recuento usa solo la última selección (RF06). **Implementada** (migración `20261025160000_votar`).

### 3.8 `actividades_itinerario`

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| plan_id | uuid FK → planes | |
| lugar_id | uuid FK → lugares | |
| candidato_id | uuid FK → candidatos null | origen en la votación; null tras un reemplazo |
| posicion | smallint not null | orden manual |
| inicio | timestamptz null | null = sin fecha/hora asignada (estado visible) |
| created_at / updated_at | timestamptz | |

`unique (plan_id, posicion) deferrable initially deferred` para reordenar en una transacción; `candidato_id unique`; `check (posicion between 1 and 5)`; trigger `fijar_updated_at`. Cantidad ≤ `planes.max_actividades`. **Implementada** (migración `20261025180000_cerrar_votacion`): la crean `cerrar_votacion` y `resolver_empate` con `inicio` null.

### 3.9 `cambios_plan` (historial — RF10)

**Implementada** (migración `20261110120000_reemplazo_y_cancelacion`, aplicada en desarrollo y en la demo): `tipo text check in ('reemplazo', 'horario', 'cancelacion')`, índice `(plan_id, created_at)`, RLS de lectura `es_participante(plan_id)` y sin escritura directa. En un `horario` `lugar_anterior_id = lugar_nuevo_id` (lugar de la actividad). Los avisos `cambio`/`cancelacion` los generará la tarea de `notificaciones` a partir de estas filas.

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| plan_id | uuid FK → planes | |
| actividad_id | uuid FK → actividades_itinerario null | null en cancelación |
| tipo | text | `reemplazo`, `horario`, `cancelacion` |
| lugar_anterior_id / lugar_nuevo_id | uuid null | |
| inicio_anterior / inicio_nuevo | timestamptz null | |
| realizado_por | uuid FK → perfiles | |
| created_at | timestamptz | |

### 3.10 `notificaciones` (historial + fuente de avisos locales)

**Implementada** (migración `20261110150000_notificaciones`, aplicada en desarrollo y en la demo): FK con `on delete cascade`, índices `(perfil_id, programada_para desc)` y `(plan_id)`. Una fila por destinatario y evento. Los triggers de §7 la mantienen (las RPC no se modificaron); la app la lee para la pestaña Notificaciones y para programar `flutter_local_notifications` en el dispositivo.

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| id_local | integer generated always as identity | id entero para `flutter_local_notifications` |
| perfil_id | uuid FK → perfiles | destinatario |
| plan_id | uuid FK → planes | |
| actividad_id | uuid FK null | para tipo `actividad` |
| tipo | notificacion_tipo | |
| titulo / cuerpo | text | incluye el nombre del plan |
| ruta_destino | text | ruta de go_router (p. ej. `/salidas/<id>/votacion`) |
| programada_para | timestamptz not null | actividad: `inicio - 30 min`; voto/asistencia: `fecha_limite_* - 1 h`; cambio/cancelación: `now()` |
| estado | notificacion_estado | default `activa`; `anulada` si dejó de aplicar |
| clave | text not null | p. ej. `actividad:<actividad_id>:<inicio>`, `voto:<plan_id>:<plazo>`, `cambio:<cambio_id>` |
| entregada_en | timestamptz null | la app la mostró como aviso local (eventos inmediatos) |
| leida_en | timestamptz null | |
| created_at | timestamptz | |

`unique (perfil_id, clave)` → sin duplicados. En la pestaña se listan las `activa` con `programada_para <= now()`.

### 3.11 Relaciones (resumen)

```
auth.users 1─1 perfiles 1─* participaciones *─1 planes
planes 1─* propuestas *─1 lugares
planes 1─* candidatos *─1 lugares ; candidatos 1─* votos *─1 perfiles
planes 1─* actividades_itinerario *─1 lugares
planes 1─* cambios_plan
planes 1─* notificaciones *─1 perfiles
```

## 4. Funciones auxiliares

```sql
-- devuelve true si el usuario actual participa en el plan
create function es_participante(p_plan_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from participaciones
                 where plan_id = p_plan_id and perfil_id = auth.uid());
$$;

-- devuelve true si el usuario actual es administrador del plan
create function es_administrador(p_plan_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from participaciones
                 where plan_id = p_plan_id and perfil_id = auth.uid()
                   and rol = 'administrador');
$$;
```

- `comparte_plan_con(p_perfil_id)` (`security definer`): true si el usuario actual comparte algún plan con ese perfil; la usa la política `select` de `perfiles` para evitar recursión de RLS sobre `participaciones`.
- `fijar_updated_at()`: trigger `before update` que mantiene `updated_at` en `perfiles` y `planes`.
- `crear_perfil_de_usuario()`: trigger `after insert on auth.users` (§3.1); si falta `nombre_visible`, el `check` de longitud rechaza el registro.
- En la implementación todas las funciones usan `set search_path = ''` y nombres calificados (`public.`), más estricto que el ejemplo de arriba.
- `generar_codigo_invitacion()`: 6 caracteres de `[A-Z0-9]` al azar; reintenta si choca con uno existente.
- `sincronizar_notificaciones_plan(p_plan_id)` (interna, no expuesta): recalcula las filas de `notificaciones` del plan según el estado vigente — anula las que ya no aplican e inserta las que faltan (idempotente por `clave`). Ver §7. **Implementada** (`20261110150000`) junto con `notificaciones_deseadas(p_plan_id)` (recordatorios futuros que deben existir), `formatear_hora_lima(momento)` (`4:00 p.m.`), `sincronizar_notificaciones_trigger()` y `crear_avisos_cambio()`; ninguna tiene `execute` para clientes.

## 5. Políticas RLS

`alter table ... enable row level security;` en **todas** las tablas. Resumen (rol `authenticated`):

| Tabla | select | insert / update / delete directo |
|---|---|---|
| perfiles | propio o de co‑participantes de algún plan común | update propio (`id = auth.uid()`), solo `nombre_visible` |
| lugares | `publicado = true` | ninguno (solo equipo / `service_role`) |
| planes | `es_participante(id)` | ninguno → RPC |
| participaciones | `es_participante(plan_id)` (asistencia y roles visibles al grupo) | ninguno → RPC |
| propuestas | `es_participante(plan_id)` | ninguno → RPC |
| candidatos | `es_participante(plan_id)`; `total_votos` solo se llena al cerrar | ninguno → RPC |
| **votos** | **solo `perfil_id = auth.uid()`** (nadie ve votos ajenos) | ninguno → RPC `guardar_votos` |
| actividades_itinerario | `es_participante(plan_id)` | ninguno → RPC |
| cambios_plan | `es_participante(plan_id)` | ninguno → RPC |
| notificaciones | `perfil_id = auth.uid()` | ninguno → RPC `marcar_notificaciones` |

```sql
alter table votos enable row level security;

-- cada persona solo ve su propia seleccion
create policy votos_select_propio on votos
  for select to authenticated
  using (perfil_id = auth.uid());
-- sin politicas de insert, update ni delete: solo la rpc guardar_votos escribe
```

**Totales sin identidad (RB04).** `obtener_totales_votacion(p_plan_id)` (`security definer`) valida `es_participante` y devuelve solo `(candidato_id, lugar_id, total)`, nunca `perfil_id`.

**Realtime.** No se usa en el MVP; los totales y las notificaciones se recargan al abrir la vista, al deslizar y al volver la app a primer plano.

## 6. Funciones RPC (contratos)

Todas `security definer`, `set search_path = public`, validan `auth.uid()`, rol y fase, y lanzan excepciones con código legible (p. ej. `raise exception 'limite_propuestas_alcanzado'`) que la app traduce a mensajes. Las que cambian el estado relevante llaman a `sincronizar_notificaciones_plan`.

| RPC | Quién | Fase requerida | Efecto |
|---|---|---|---|
| `crear_plan(plan_id, nombre, presupuesto_soles, max_propuestas, max_candidatos, max_selecciones, max_actividades)` | usuario | — | **implementada**. `p_plan_id` lo genera la app (uuid v4): si ya existe y es del usuario devuelve ese plan (reintento sin duplicar; de otro usuario → `no_autorizado`). Valida nombre no vacío (`nombre_requerido`), presupuesto 0 ≤ x < 100 000 000 redondeado a 2 decimales (`presupuesto_invalido`), rangos (`limite_fuera_de_rango`) y selecciones ≤ candidatos (`selecciones_mayores_que_candidatos`); genera código `[A-Z0-9]{6}` con hasta 10 reintentos por colisión (`codigo_no_disponible`); crea participación `administrador` con `es_creador`; devuelve la fila de `planes` (RF01). `execute` solo para `authenticated` |
| `unirse_con_codigo(codigo)` | usuario | cualquiera excepto `cancelado` | **implementada**. `no_autenticado` sin sesión; normaliza con `upper(trim())`; código inexistente o de plan `cancelado` → `codigo_invalido`; inserta participación `participante` con `on conflict (plan_id, perfil_id) do nothing` (idempotente); devuelve `jsonb` `{plan_id, ya_participaba}`. `execute` solo `authenticated`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `nombrar_administrador(plan_id, perfil_id)` | admin | excepto `cancelado` | **implementada**. `no_autenticado` sin sesión; quien llama no es admin del plan → `no_autorizado`; plan `cancelado` → `plan_cancelado`; destino que no participa → `participante_no_encontrado`; `update` de una sola sentencia (si falla, los roles se conservan); nombrar a un admin no cambia nada; devuelve `void`. Rol permanente. `execute` solo `authenticated` (RF17) |
| `proponer_lugar(plan_id, lugar_id)` | participante | `recibiendo_propuestas` | **implementada**. `no_autenticado`; plan inexistente o sin participación → `no_autorizado`; bloquea la fila del plan (`for update`) para contar el límite sin carreras; otra fase (incluido `cancelado`) → `fase_no_permite_propuestas`; lugar inexistente o no publicado → `lugar_no_disponible`; ya propuesto por otro → `lugar_ya_propuesto`; ya propuesto por el mismo usuario → devuelve esa fila (reintento idempotente); cupo lleno → `limite_propuestas_alcanzado`; devuelve la fila de `propuestas` (RF05) |
| `retirar_propuesta(propuesta_id)` | autor de la propuesta o admin | `recibiendo_propuestas` | **implementada**. `no_autenticado`; propuesta inexistente → no hace nada (reintento idempotente); ni autor ni admin → `no_autorizado`; otra fase → `fase_no_permite_propuestas`; elimina la propuesta y, si el lugar estaba en `candidatos`, también ese candidato; libera el cupo del autor; devuelve `void` (RF05) |
| `actualizar_limites(plan_id, max_candidatos, max_selecciones, max_actividades)` | admin | `recibiendo_propuestas` | **implementada**. `no_autenticado`; plan inexistente o no admin → `no_autorizado`; otra fase → `fase_no_permite_preparacion`; nulo o fuera de 2–10 / 1–5 / 1–5 → `limite_fuera_de_rango`; selecciones > candidatos → `selecciones_mayores_que_candidatos`; lista guardada mayor que el nuevo máximo → `candidatos_superan_maximo`; `max_propuestas_por_persona` no cambia; devuelve la fila de `planes` (RF18) |
| `definir_candidatos(plan_id, lugar_ids[])` | admin | `recibiendo_propuestas` | **implementada**. Mismas validaciones de sesión, rol y fase; quita nulos y repetidos; más que `max_candidatos` → `candidatos_superan_maximo`; lugar sin propuesta en el plan → `lugar_no_propuesto`; reemplaza la lista conservando las filas que siguen (reintento idempotente); lista vacía permitida; devuelve `void` (RF05) |
| `definir_plazos(plan_id, fecha_limite_voto, fecha_limite_asistencia)` | admin | excepto `cancelado` | **implementada**. Ambos opcionales (`null` = sin plazo) y se reemplazan juntos; `cancelado` → `plan_cancelado`; una fecha que cambia y no es futura → `plazo_en_pasado` (se puede reenviar un plazo ya vencido); devuelve la fila de `planes`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `abrir_votacion(plan_id)` | admin | `recibiendo_propuestas` | **implementada**. Ya `en_votacion` → devuelve el plan (reintento); otra fase → `fase_no_permite_preparacion`; 0 candidatos → `sin_candidatos`; estado → `en_votacion` y `votacion_abierta_en = now()`; irreversible; devuelve la fila de `planes`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `guardar_votos(plan_id, candidato_ids[])` | participante | `en_votacion` | **implementada**. `no_autenticado`; plan inexistente o sin participación → `no_autorizado`; bloquea el plan `for share` (espera a un cierre en curso sin bloquear otros votos); `recibiendo_propuestas` → `votacion_no_abierta`; otra fase → `votacion_cerrada`; quita nulos y repetidos; vacía → `seleccion_vacia` (mínimo 1); candidato de otro plan → `candidato_no_valido`; más que `least(max_selecciones, nº candidatos)` → `limite_selecciones_superado`; borra lo que dejó de elegir e inserta lo nuevo con `on conflict do nothing` (reintento sin duplicar); marca `votos_guardados_en = now()`; devuelve `void`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `obtener_totales_votacion(plan_id)` | participante | `en_votacion` o posterior | **implementada** (`stable`). `no_autenticado`; sin participación → `no_autorizado`; `recibiendo_propuestas` → `votacion_no_abierta`; devuelve `(candidato_id, lugar_id, total)` de todos los candidatos (incluye 0) en orden de `created_at`, nunca `perfil_id` (RF07) |
| `cerrar_votacion(plan_id)` | admin | `en_votacion` | **implementada**. `no_autenticado`; plan inexistente o no admin → `no_autorizado`; bloquea el plan `for update`; `recibiendo_propuestas` → `votacion_no_abierta`; `cancelado` → `plan_cancelado`; ya cerrada → devuelve el plan (reintento); 0 candidatos → `sin_candidatos`; 0 votos → `sin_votos` (sigue abierta); guarda `total_votos` de todos; selecciona los votados hasta `max_actividades`; si el total del último puesto se repite fuera del corte, solo selecciona los que lo superan y deja el empate al admin; crea `actividades_itinerario` de los seleccionados (posición por votos, `inicio` null); estado → `preparando_itinerario` y `votacion_cerrada_en = now()`; devuelve la fila de `planes`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `resolver_empate(plan_id, candidato_ids[])` | admin | `preparando_itinerario` | **implementada**. `no_autenticado`; no admin → `no_autorizado`; otra fase → `fase_no_permite_desempate`; cupos = `least(max_actividades, nº votados) − seleccionados`; sin cupos → `sin_empate_pendiente` (salvo reintento con los mismos ya seleccionados, que no falla); empatados = votados sin seleccionar con el mayor total entre ellos; otro → `candidato_no_empatado`; cantidad distinta de los cupos → `cantidad_desempate_invalida`; marca `seleccionado` y crea sus actividades al final; definitiva; devuelve `void` (RF08) |
| `guardar_itinerario(plan_id, actividades jsonb)` | admin | `preparando_itinerario` (luego también `confirmado`, RF10) | **implementada** (`20261109120000_revisar_itinerario`). `actividades` = lista `[{id, inicio}]` en orden de ejecución (posición = índice; `inicio` null = sin fecha/hora). `no_autenticado`; no admin → `no_autorizado`; otra fase → `fase_no_permite_itinerario`; empate pendiente → `empate_pendiente`; lista que no contiene exactamente las actividades del plan, cada una una vez → `actividades_no_coinciden`; un `inicio` que cambia y no es futuro → `inicio_en_pasado`; actualiza solo filas con cambios (reintento sin efecto); devuelve `void`. En `confirmado` no se usa: el horario cambia con `cambiar_horario_actividad` (decisión 2026-11-10) |
| `confirmar_plan(plan_id)` | admin | `preparando_itinerario` | **implementada**. `no_autenticado`; no admin → `no_autorizado`; ya `confirmado` → devuelve el plan (reintento); otra fase → `fase_no_permite_confirmar`; empate pendiente → `empate_pendiente`; sin actividades → `sin_actividades`; alguna sin `inicio` → `actividades_sin_horario`; el exceso de presupuesto no bloquea (la app lo muestra con `obtener_estimacion_presupuesto`); estado → `confirmado`, `confirmado_en = now()`; irreversible; devuelve la fila de `planes`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `reemplazar_actividad(actividad_id, lugar_id)` | admin | `confirmado` | **implementada** (`20261110120000`). `no_autenticado`; actividad inexistente o no admin → `no_autorizado`; bloquea el plan; `cancelado` → `plan_cancelado`; otra fase → `plan_no_confirmado`; lugar nulo, inexistente o no publicado → `lugar_no_disponible`; mismo lugar → devuelve la actividad (reintento); lugar ya en el itinerario → `lugar_en_itinerario`; registra `cambios_plan` tipo `reemplazo`; cambia `lugar_id`, `candidato_id = null`, conserva posición e `inicio`; devuelve la fila de `actividades_itinerario`. Alternativas en la app: candidatos no elegidos + catálogo (decisión 2026-11-10). Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `cambiar_horario_actividad(actividad_id, inicio)` | admin | `confirmado` | **implementada** (`20261110120000`). Mismas validaciones de sesión, rol y fase; `inicio` nulo → `inicio_requerido`; mismo inicio → devuelve la actividad (reintento); no futuro → `inicio_en_pasado`; registra `cambios_plan` tipo `horario`; sin reordenar; devuelve la fila. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `cancelar_plan(plan_id)` | admin | excepto `cancelado` | **implementada** (`20261110120000`). `no_autenticado`; plan inexistente o no admin → `no_autorizado`; ya `cancelado` → devuelve el plan (reintento); registra `cambios_plan` tipo `cancelacion`; estado → `cancelado`, `cancelado_en = now()` (código inactivo); irreversible; devuelve la fila de `planes`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `responder_asistencia(plan_id, estado)` | integrante (admins incluidos) | solo `confirmado` | **implementada** (`20261109150000_asistencia`, `p_estado text`). Solo `asistire` / `no_asistire` (`pendiente` o null → `asistencia_invalida`); ajeno → `no_autorizado`; `cancelado` → `plan_cancelado`; otra fase → `plan_no_confirmado` (decisión 2026-11-09); permitido aunque `fecha_limite_asistencia` haya vencido; guarda `asistencia_actualizada_en` y devuelve la fila de `participaciones`. Avisos: los mantienen los triggers de `20261110150000_notificaciones` (§7) |
| `obtener_estimacion_presupuesto(plan_id)` | participante | — | **implementada** (`stable`). `no_autenticado`; sin participación → `no_autorizado`; devuelve una fila `(presupuesto_soles, total_estimado, actividades, sin_precio, incompleta, excede)`: suma de `precio_estimado_pen` conocidos de las actividades, `incompleta` si alguna no tiene precio, `excede` si la suma supera el presupuesto (RB08) |
| `tiene_empate_pendiente(plan_id)` | interna | — | **implementada**. `least(max_actividades, nº votados) > seleccionados`; sin `execute` para clientes; la usan `guardar_itinerario` y `confirmar_plan` |
| `marcar_notificaciones(ids[], entregada, leida)` | destinatario | — | **implementada** (`20261110150000`). `no_autenticado`; fija `entregada_en` / `leida_en` de filas propias conservando la primera fecha (reintento sin cambio); ids ajenos o inexistentes se ignoran; devuelve `void` |

### 6.1 Consulta de recomendaciones (RF13)

Lectura directa con RLS (no requiere RPC). Las tres entradas son obligatorias:

```sql
-- recomendaciones por zona, categoria y presupuesto, de mas economico a mas caro
select * from lugares
where publicado
  and zona = :zona
  and categoria = :categoria
  and precio_estimado_pen <= :presupuesto_soles
order by precio_estimado_pen asc, nombre asc
limit 10;
```

Los lugares con precio desconocido (`null`) quedan fuera de las recomendaciones, pero siguen visibles en Explorar. Equivalente en Dart: `.eq('zona', …).eq('categoria', …).lte('precio_estimado_pen', …).order('precio_estimado_pen', ascending: true).order('nombre', ascending: true).limit(10)` (en `postgrest-dart` `.order()` es descendente por defecto, ver `03_DECISIONS.md`).

## 7. Avisos (primera iteración: sin push remoto)

**Generación en servidor** (`sincronizar_notificaciones_plan`), destinatarios:

| Tipo | Cuándo existe una fila `activa` | Destinatarios | `programada_para` |
|---|---|---|---|
| `voto` | plan `en_votacion` y `fecha_limite_voto` no nula | participantes con `votos_guardados_en is null` | `fecha_limite_voto - 1 h` |
| `asistencia` | plan no cancelado y `fecha_limite_asistencia` no nula | participantes con `asistencia = 'pendiente'` | `fecha_limite_asistencia - 1 h` |
| `actividad` | plan `confirmado` y actividad con `inicio` | participantes con asistencia `pendiente` o `asistire` | `inicio - 30 min` |
| `cambio` | reemplazo u horario cambiado en `confirmado` | participantes con asistencia `pendiente` o `asistire` | `now()` |
| `cancelacion` | plan pasa a `cancelado` | participantes con asistencia `pendiente` o `asistire` | `now()` |

Si `fecha_limite_voto` o `fecha_limite_asistencia` es `null`, no se crea el recordatorio de esa acción. Si `programada_para` ya pasó al generarse (plazo con menos de 1 h, actividad con menos de 30 min), la fila de recordatorio no se crea.

**Integración con las RPC (implementada, `20261110150000`, decisión 2026-11-10).** Triggers `after` por fila, sin modificar RPC:
- `planes_sincronizar_notificaciones`: cambio de `estado`, `fecha_limite_voto` o `fecha_limite_asistencia` (abrir/cerrar votación, confirmar, cancelar, `definir_plazos`).
- `participaciones_alta_sincronizar_notificaciones` (unirse) y `participaciones_cambio_sincronizar_notificaciones` (`asistencia`, `votos_guardados_en`).
- `actividades_sincronizar_notificaciones`: cambio de `lugar_id` o `inicio` (reemplazo, horario).
- `cambios_plan_crear_avisos`: cada fila crea `cambio` (reemplazo u horario) o `cancelacion` con `programada_para = now()`, a asistencia `pendiente`/`asistire` **excepto `realizado_por`**.

La sincronización solo toca recordatorios (`voto`, `asistencia`, `actividad`) futuros: los pasados quedan en el historial. Restituye a `activa` un anulado que vuelve a aplicar (misma clave). Claves: `voto:<plan>:<epoch plazo>`, `asistencia:<plan>:<epoch plazo>`, `actividad:<actividad>:<lugar>:<epoch inicio>` (reemplazo u horario → clave nueva), `cambio:<cambio_id>`, `cancelacion:<cambio_id>`. Textos y rutas: `03_DECISIONS.md` (2026-11-10). La migración sincronizó los planes existentes no cancelados.

**Programación en el dispositivo** (`features/notificaciones`, ver `05_ARCHITECTURE.md`):
1. Al iniciar sesión, abrir la app, volver a primer plano y deslizar para recargar: leer las filas propias.
2. Filas `activa` futuras → `zonedSchedule` con `id_local`; filas `anulada` → `cancel(id_local)`.
3. Filas `cambio`/`cancelacion` con `entregada_en is null` → mostrar aviso inmediato y marcar `entregada`.
4. Tras una acción propia confirmada por el servidor (votar, responder asistencia) → cancelar al instante el aviso local correspondiente.

**Limitación aceptada del MVP.** Sin push remoto, los cambios hechos por otra persona (cambio de horario, reemplazo, cancelación, cierre de votación) llegan al dispositivo cuando la app se abre o vuelve a primer plano. Hasta entonces puede sonar un recordatorio con el horario anterior. FCM + Edge Function + Cron queda como mejora posterior.

## 8. Storage

- Bucket `lugares` (lectura para `authenticated`; escritura solo equipo). **No creado**: imágenes omitidas por ahora (2026-10-24). Imágenes propias o con permiso de uso, optimizadas para móvil. Opcional en el MVP.
