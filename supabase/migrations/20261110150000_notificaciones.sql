-- notificaciones: tabla, sincronizacion por plan, avisos de cambio y cancelacion,
-- triggers sobre las tablas existentes y rpc marcar_notificaciones (rf14, rb16, rb17)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.10, 5, 6 y 7
-- las rpc existentes no se modifican: los triggers mantienen los avisos al cambiar el plan

-- ---------------------------------------------------------------
-- tabla
-- ---------------------------------------------------------------

create table public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  -- id entero para flutter_local_notifications
  id_local integer generated always as identity,
  perfil_id uuid not null references public.perfiles (id) on delete cascade,
  plan_id uuid not null references public.planes (id) on delete cascade,
  actividad_id uuid references public.actividades_itinerario (id) on delete cascade,
  tipo public.notificacion_tipo not null,
  titulo text not null,
  cuerpo text not null,
  ruta_destino text not null,
  programada_para timestamptz not null,
  estado public.notificacion_estado not null default 'activa',
  clave text not null,
  entregada_en timestamptz,
  leida_en timestamptz,
  created_at timestamptz not null default now(),
  -- una fila por destinatario y evento: sin duplicados
  unique (perfil_id, clave)
);

create index notificaciones_perfil_programada_idx
  on public.notificaciones (perfil_id, programada_para desc);
create index notificaciones_plan_id_idx on public.notificaciones (plan_id);

alter table public.notificaciones enable row level security;

-- cada persona solo ve sus avisos; sin escritura directa
create policy notificaciones_select_propio on public.notificaciones
  for select to authenticated
  using (perfil_id = auth.uid());

-- ---------------------------------------------------------------
-- formato de hora
-- ---------------------------------------------------------------

-- hora de lima con reloj de 12 h, por ejemplo 4:00 p.m.
create function public.formatear_hora_lima(p_momento timestamptz)
returns text
language sql
immutable
set search_path = ''
as $$
  select to_char(p_momento at time zone 'America/Lima', 'FMHH12:MI')
    || case when extract(hour from p_momento at time zone 'America/Lima') < 12
         then ' a.m.' else ' p.m.' end;
$$;

revoke execute on function public.formatear_hora_lima(timestamptz) from public, anon, authenticated;

-- ---------------------------------------------------------------
-- recordatorios que deben existir segun el estado vigente
-- ---------------------------------------------------------------

-- voto: plan en votacion con plazo, a quienes no guardaron elecciones.
-- asistencia: plan no cancelado con plazo, a quienes siguen pendientes.
-- actividad: plan confirmado y actividad con inicio, a pendientes y asistire.
-- solo devuelve recordatorios cuyo momento aun no paso.
create function public.notificaciones_deseadas(p_plan_id uuid)
returns table (
  perfil_id uuid,
  actividad_id uuid,
  tipo public.notificacion_tipo,
  titulo text,
  cuerpo text,
  ruta_destino text,
  programada_para timestamptz,
  clave text
)
language sql
stable
security definer
set search_path = ''
as $$
  select d.*
  from (
    select pa.perfil_id,
           null::uuid,
           'voto'::public.notificacion_tipo,
           p.nombre || ': falta tu voto',
           'El plazo para votar vence en 1 hora.',
           '/salidas/' || p.id || '/votacion',
           p.fecha_limite_voto - interval '1 hour',
           'voto:' || p.id || ':' || extract(epoch from p.fecha_limite_voto)::bigint
    from public.planes p
    join public.participaciones pa on pa.plan_id = p.id
    where p.id = p_plan_id
      and p.estado = 'en_votacion'
      and p.fecha_limite_voto is not null
      and pa.votos_guardados_en is null

    union all

    select pa.perfil_id,
           null::uuid,
           'asistencia'::public.notificacion_tipo,
           p.nombre || ': confirma tu asistencia',
           'El plazo para responder vence en 1 hora.',
           '/salidas/' || p.id,
           p.fecha_limite_asistencia - interval '1 hour',
           'asistencia:' || p.id || ':' || extract(epoch from p.fecha_limite_asistencia)::bigint
    from public.planes p
    join public.participaciones pa on pa.plan_id = p.id
    where p.id = p_plan_id
      and p.estado <> 'cancelado'
      and p.fecha_limite_asistencia is not null
      and pa.asistencia = 'pendiente'

    union all

    select pa.perfil_id,
           a.id,
           'actividad'::public.notificacion_tipo,
           p.nombre || ': en 30 minutos',
           l.nombre || ' empieza a las ' || public.formatear_hora_lima(a.inicio),
           '/salidas/' || p.id,
           a.inicio - interval '30 minutes',
           'actividad:' || a.id || ':' || a.lugar_id || ':' || extract(epoch from a.inicio)::bigint
    from public.planes p
    join public.actividades_itinerario a on a.plan_id = p.id
    join public.lugares l on l.id = a.lugar_id
    join public.participaciones pa on pa.plan_id = p.id
    where p.id = p_plan_id
      and p.estado = 'confirmado'
      and a.inicio is not null
      and pa.asistencia in ('pendiente', 'asistire')
  ) as d (perfil_id, actividad_id, tipo, titulo, cuerpo, ruta_destino, programada_para, clave)
  where d.programada_para > now();
$$;

revoke execute on function public.notificaciones_deseadas(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------
-- sincronizacion por plan
-- ---------------------------------------------------------------

-- recalcula los recordatorios futuros del plan: anula los que dejaron de aplicar,
-- crea los que faltan y restituye los anulados que vuelven a aplicar.
-- los recordatorios ya pasados y los avisos de cambio o cancelacion no se tocan.
-- idempotente por (perfil_id, clave).
create function public.sincronizar_notificaciones_plan(p_plan_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.notificaciones n
  set estado = 'anulada'
  where n.plan_id = p_plan_id
    and n.tipo in ('voto', 'asistencia', 'actividad')
    and n.estado = 'activa'
    and n.programada_para > now()
    and not exists (
      select 1 from public.notificaciones_deseadas(p_plan_id) d
      where d.perfil_id = n.perfil_id and d.clave = n.clave
    );

  insert into public.notificaciones as n (
    perfil_id, plan_id, actividad_id, tipo, titulo, cuerpo, ruta_destino, programada_para, clave
  )
  select d.perfil_id, p_plan_id, d.actividad_id, d.tipo, d.titulo, d.cuerpo,
         d.ruta_destino, d.programada_para, d.clave
  from public.notificaciones_deseadas(p_plan_id) d
  on conflict (perfil_id, clave) do update
    set estado = 'activa'
    where n.estado = 'anulada';
end;
$$;

revoke execute on function public.sincronizar_notificaciones_plan(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------
-- triggers de sincronizacion
-- ---------------------------------------------------------------

create function public.sincronizar_notificaciones_trigger()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_name = 'planes' then
    perform public.sincronizar_notificaciones_plan(new.id);
  else
    perform public.sincronizar_notificaciones_plan(new.plan_id);
  end if;
  return null;
end;
$$;

revoke execute on function public.sincronizar_notificaciones_trigger() from public, anon, authenticated;

-- fase y plazos: abrir o cerrar votacion, confirmar, cancelar y definir plazos
create trigger planes_sincronizar_notificaciones
  after update of estado, fecha_limite_voto, fecha_limite_asistencia on public.planes
  for each row
  when (
    old.estado is distinct from new.estado
    or old.fecha_limite_voto is distinct from new.fecha_limite_voto
    or old.fecha_limite_asistencia is distinct from new.fecha_limite_asistencia
  )
  execute function public.sincronizar_notificaciones_trigger();

-- unirse con codigo
create trigger participaciones_alta_sincronizar_notificaciones
  after insert on public.participaciones
  for each row
  execute function public.sincronizar_notificaciones_trigger();

-- guardar votos y responder asistencia
create trigger participaciones_cambio_sincronizar_notificaciones
  after update of asistencia, votos_guardados_en on public.participaciones
  for each row
  when (
    old.asistencia is distinct from new.asistencia
    or old.votos_guardados_en is distinct from new.votos_guardados_en
  )
  execute function public.sincronizar_notificaciones_trigger();

-- reemplazo y cambio de horario de actividades
create trigger actividades_sincronizar_notificaciones
  after update of lugar_id, inicio on public.actividades_itinerario
  for each row
  when (old.lugar_id is distinct from new.lugar_id or old.inicio is distinct from new.inicio)
  execute function public.sincronizar_notificaciones_trigger();

-- ---------------------------------------------------------------
-- avisos de cambio y cancelacion
-- ---------------------------------------------------------------

-- cada fila de cambios_plan genera un aviso inmediato para participantes con
-- asistencia pendiente o asistire, sin incluir a quien hizo el cambio
create function public.crear_avisos_cambio()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan text;
  v_anterior text;
  v_nuevo text;
  v_autor text;
  v_tipo public.notificacion_tipo;
  v_titulo text;
  v_cuerpo text;
  v_clave text;
begin
  select nombre into v_plan from public.planes where id = new.plan_id;
  select nombre into v_anterior from public.lugares where id = new.lugar_anterior_id;
  select nombre into v_nuevo from public.lugares where id = new.lugar_nuevo_id;
  select nombre_visible into v_autor from public.perfiles where id = new.realizado_por;

  if new.tipo = 'cancelacion' then
    v_tipo := 'cancelacion';
    v_titulo := v_plan || ' se canceló';
    v_cuerpo := 'La salida fue cancelada por ' || coalesce(v_autor, 'un administrador') || '.';
    v_clave := 'cancelacion:' || new.id;
  elsif new.tipo = 'reemplazo' then
    v_tipo := 'cambio';
    v_titulo := v_plan || ': cambió una actividad';
    v_cuerpo := coalesce(v_anterior, 'Una actividad') || ' se reemplazó por '
      || coalesce(v_nuevo, 'otro lugar') || '.';
    v_clave := 'cambio:' || new.id;
  else
    v_tipo := 'cambio';
    v_titulo := v_plan || ': cambió un horario';
    v_cuerpo := coalesce(v_nuevo, 'Una actividad') || ' ahora empieza el '
      || to_char(new.inicio_nuevo at time zone 'America/Lima', 'DD/MM')
      || ' a las ' || public.formatear_hora_lima(new.inicio_nuevo);
    v_clave := 'cambio:' || new.id;
  end if;

  insert into public.notificaciones (
    perfil_id, plan_id, actividad_id, tipo, titulo, cuerpo, ruta_destino, programada_para, clave
  )
  select pa.perfil_id, new.plan_id, new.actividad_id, v_tipo, v_titulo, v_cuerpo,
         '/salidas/' || new.plan_id, now(), v_clave
  from public.participaciones pa
  where pa.plan_id = new.plan_id
    and pa.asistencia in ('pendiente', 'asistire')
    and pa.perfil_id <> new.realizado_por
  on conflict (perfil_id, clave) do nothing;

  return null;
end;
$$;

revoke execute on function public.crear_avisos_cambio() from public, anon, authenticated;

create trigger cambios_plan_crear_avisos
  after insert on public.cambios_plan
  for each row
  execute function public.crear_avisos_cambio();

-- ---------------------------------------------------------------
-- rpc marcar_notificaciones
-- ---------------------------------------------------------------

-- el destinatario marca sus avisos como entregados (mostrados como aviso local)
-- o leidos. conserva la primera fecha para que un reintento no la cambie.
create function public.marcar_notificaciones(
  p_ids uuid[],
  p_entregada boolean,
  p_leida boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  update public.notificaciones
  set entregada_en = case when coalesce(p_entregada, false)
                       then coalesce(entregada_en, now()) else entregada_en end,
      leida_en = case when coalesce(p_leida, false)
                   then coalesce(leida_en, now()) else leida_en end
  where perfil_id = v_usuario
    and id = any (coalesce(p_ids, '{}'));
end;
$$;

revoke execute on function public.marcar_notificaciones(uuid[], boolean, boolean) from public, anon;
grant execute on function public.marcar_notificaciones(uuid[], boolean, boolean) to authenticated;

-- ---------------------------------------------------------------
-- planes existentes
-- ---------------------------------------------------------------

-- genera los recordatorios vigentes de los planes ya creados
select public.sincronizar_notificaciones_plan(id)
from public.planes
where estado <> 'cancelado';
