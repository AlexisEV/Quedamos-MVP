-- reemplazo y cancelacion: tabla cambios_plan y rpc reemplazar_actividad,
-- cambiar_horario_actividad y cancelar_plan (rf10, rb11)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.9, 5 y 6
-- los avisos de cambio y cancelacion los genera la tarea de notificaciones a partir de cambios_plan

-- ---------------------------------------------------------------
-- tabla
-- ---------------------------------------------------------------

create table public.cambios_plan (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.planes (id) on delete cascade,
  -- null en una cancelacion
  actividad_id uuid references public.actividades_itinerario (id) on delete cascade,
  tipo text not null check (tipo in ('reemplazo', 'horario', 'cancelacion')),
  lugar_anterior_id uuid references public.lugares (id),
  lugar_nuevo_id uuid references public.lugares (id),
  inicio_anterior timestamptz,
  inicio_nuevo timestamptz,
  realizado_por uuid not null references public.perfiles (id),
  created_at timestamptz not null default now()
);

create index cambios_plan_plan_id_idx on public.cambios_plan (plan_id, created_at);

alter table public.cambios_plan enable row level security;

-- sin politicas de escritura: solo las rpc escriben
create policy cambios_plan_select_participante on public.cambios_plan
  for select to authenticated
  using (public.es_participante(plan_id));

-- ---------------------------------------------------------------
-- rpc reemplazar_actividad
-- ---------------------------------------------------------------

-- un administrador reemplaza el lugar de una actividad de un plan confirmado, sin votacion.
-- conserva posicion e inicio; el lugar nuevo no puede repetir otro del itinerario.
-- elegir el mismo lugar devuelve la actividad sin cambios para que un reintento no falle.
create function public.reemplazar_actividad(p_actividad_id uuid, p_lugar_id uuid)
returns public.actividades_itinerario
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_actividad public.actividades_itinerario;
  v_plan public.planes;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  select * into v_actividad from public.actividades_itinerario where id = p_actividad_id;
  if not found then
    raise exception 'no_autorizado';
  end if;

  select * into v_plan from public.planes where id = v_actividad.plan_id for update;
  if not exists (
    select 1 from public.participaciones
    where plan_id = v_plan.id and perfil_id = v_usuario and rol = 'administrador'
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_plan.estado = 'cancelado' then
    raise exception 'plan_cancelado';
  end if;
  if v_plan.estado <> 'confirmado' then
    raise exception 'plan_no_confirmado';
  end if;

  -- relee la actividad con el plan bloqueado
  select * into v_actividad from public.actividades_itinerario
  where id = p_actividad_id for update;

  if p_lugar_id is null or not exists (
    select 1 from public.lugares where id = p_lugar_id and publicado
  ) then
    raise exception 'lugar_no_disponible';
  end if;

  if v_actividad.lugar_id = p_lugar_id then
    return v_actividad;
  end if;

  if exists (
    select 1 from public.actividades_itinerario
    where plan_id = v_plan.id and lugar_id = p_lugar_id
  ) then
    raise exception 'lugar_en_itinerario';
  end if;

  insert into public.cambios_plan (
    plan_id, actividad_id, tipo, lugar_anterior_id, lugar_nuevo_id,
    inicio_anterior, inicio_nuevo, realizado_por
  ) values (
    v_plan.id, v_actividad.id, 'reemplazo', v_actividad.lugar_id, p_lugar_id,
    v_actividad.inicio, v_actividad.inicio, v_usuario
  );

  -- la actividad deja de venir de la votacion
  update public.actividades_itinerario
  set lugar_id = p_lugar_id, candidato_id = null
  where id = v_actividad.id
  returning * into v_actividad;

  return v_actividad;
end;
$$;

revoke execute on function public.reemplazar_actividad(uuid, uuid) from public, anon;
grant execute on function public.reemplazar_actividad(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------
-- rpc cambiar_horario_actividad
-- ---------------------------------------------------------------

-- un administrador cambia la fecha y hora de inicio de una actividad de un plan confirmado.
-- el inicio nuevo es obligatorio y futuro; el mismo inicio devuelve la actividad sin cambios.
create function public.cambiar_horario_actividad(p_actividad_id uuid, p_inicio timestamptz)
returns public.actividades_itinerario
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_actividad public.actividades_itinerario;
  v_plan public.planes;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  select * into v_actividad from public.actividades_itinerario where id = p_actividad_id;
  if not found then
    raise exception 'no_autorizado';
  end if;

  select * into v_plan from public.planes where id = v_actividad.plan_id for update;
  if not exists (
    select 1 from public.participaciones
    where plan_id = v_plan.id and perfil_id = v_usuario and rol = 'administrador'
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_plan.estado = 'cancelado' then
    raise exception 'plan_cancelado';
  end if;
  if v_plan.estado <> 'confirmado' then
    raise exception 'plan_no_confirmado';
  end if;

  select * into v_actividad from public.actividades_itinerario
  where id = p_actividad_id for update;

  if p_inicio is null then
    raise exception 'inicio_requerido';
  end if;
  if v_actividad.inicio = p_inicio then
    return v_actividad;
  end if;
  if p_inicio <= now() then
    raise exception 'inicio_en_pasado';
  end if;

  insert into public.cambios_plan (
    plan_id, actividad_id, tipo, lugar_anterior_id, lugar_nuevo_id,
    inicio_anterior, inicio_nuevo, realizado_por
  ) values (
    v_plan.id, v_actividad.id, 'horario', v_actividad.lugar_id, v_actividad.lugar_id,
    v_actividad.inicio, p_inicio, v_usuario
  );

  update public.actividades_itinerario
  set inicio = p_inicio
  where id = v_actividad.id
  returning * into v_actividad;

  return v_actividad;
end;
$$;

revoke execute on function public.cambiar_horario_actividad(uuid, timestamptz) from public, anon;
grant execute on function public.cambiar_horario_actividad(uuid, timestamptz) to authenticated;

-- ---------------------------------------------------------------
-- rpc cancelar_plan
-- ---------------------------------------------------------------

-- un administrador cancela el plan desde cualquier fase activa, de forma irreversible.
-- el codigo queda inactivo por el estado cancelado. un plan ya cancelado se devuelve
-- sin cambios para que un reintento no falle.
create function public.cancelar_plan(p_plan_id uuid)
returns public.planes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  select * into v_plan from public.planes where id = p_plan_id for update;
  if not found or not exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = v_usuario and rol = 'administrador'
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_plan.estado = 'cancelado' then
    return v_plan;
  end if;

  insert into public.cambios_plan (plan_id, tipo, realizado_por)
  values (p_plan_id, 'cancelacion', v_usuario);

  update public.planes
  set estado = 'cancelado', cancelado_en = now()
  where id = p_plan_id
  returning * into v_plan;

  return v_plan;
end;
$$;

revoke execute on function public.cancelar_plan(uuid) from public, anon;
grant execute on function public.cancelar_plan(uuid) to authenticated;
