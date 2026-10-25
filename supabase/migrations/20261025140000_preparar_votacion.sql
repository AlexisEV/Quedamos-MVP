-- preparar votacion: rpc actualizar_limites, definir_candidatos, definir_plazos y abrir_votacion
-- (rf05, rf14, rf18, rb03, rb07, rb14)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.3, 3.6 y 6

-- ---------------------------------------------------------------
-- rpc actualizar_limites
-- ---------------------------------------------------------------

-- un administrador ajusta candidatos, selecciones y actividades antes de abrir la votacion.
-- el maximo de propuestas por persona no cambia despues de crear el plan
create function public.actualizar_limites(
  p_plan_id uuid,
  p_max_candidatos integer,
  p_max_selecciones integer,
  p_max_actividades integer
)
returns public.planes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_candidatos integer;
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

  if v_plan.estado <> 'recibiendo_propuestas' then
    raise exception 'fase_no_permite_preparacion';
  end if;

  if p_max_candidatos is null or p_max_candidatos not between 2 and 10
     or p_max_selecciones is null or p_max_selecciones not between 1 and 5
     or p_max_actividades is null or p_max_actividades not between 1 and 5 then
    raise exception 'limite_fuera_de_rango';
  end if;

  if p_max_selecciones > p_max_candidatos then
    raise exception 'selecciones_mayores_que_candidatos';
  end if;

  -- la lista guardada siempre respeta el maximo vigente
  select count(*) into v_candidatos
  from public.candidatos
  where plan_id = p_plan_id;
  if v_candidatos > p_max_candidatos then
    raise exception 'candidatos_superan_maximo';
  end if;

  update public.planes
  set max_candidatos = p_max_candidatos,
      max_selecciones = p_max_selecciones,
      max_actividades = p_max_actividades
  where id = p_plan_id
  returning * into v_plan;
  return v_plan;
end;
$$;

revoke execute on function public.actualizar_limites(uuid, integer, integer, integer)
  from public, anon;
grant execute on function public.actualizar_limites(uuid, integer, integer, integer)
  to authenticated;

-- ---------------------------------------------------------------
-- rpc definir_candidatos
-- ---------------------------------------------------------------

-- un administrador reemplaza la lista final con lugares propuestos en el plan.
-- conserva las filas de los lugares que siguen en la lista para que un reintento no cambie ids
create function public.definir_candidatos(p_plan_id uuid, p_lugar_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_lugares uuid[];
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

  if v_plan.estado <> 'recibiendo_propuestas' then
    raise exception 'fase_no_permite_preparacion';
  end if;

  -- quita nulos y repetidos
  select coalesce(array_agg(distinct lugar), '{}') into v_lugares
  from unnest(coalesce(p_lugar_ids, '{}')) as lugar
  where lugar is not null;

  if cardinality(v_lugares) > v_plan.max_candidatos then
    raise exception 'candidatos_superan_maximo';
  end if;

  if exists (
    select 1 from unnest(v_lugares) as lugar
    where not exists (
      select 1 from public.propuestas
      where plan_id = p_plan_id and lugar_id = lugar
    )
  ) then
    raise exception 'lugar_no_propuesto';
  end if;

  delete from public.candidatos
  where plan_id = p_plan_id and lugar_id <> all (v_lugares);

  insert into public.candidatos (plan_id, lugar_id)
  select p_plan_id, lugar from unnest(v_lugares) as lugar
  on conflict (plan_id, lugar_id) do nothing;
end;
$$;

revoke execute on function public.definir_candidatos(uuid, uuid[]) from public, anon;
grant execute on function public.definir_candidatos(uuid, uuid[]) to authenticated;

-- ---------------------------------------------------------------
-- rpc definir_plazos
-- ---------------------------------------------------------------

-- un administrador fija o quita los plazos de voto y asistencia (null = sin plazo).
-- solo rechaza una fecha pasada cuando cambia, para poder reenviar un plazo ya vencido.
-- pendiente: llamar a sincronizar_notificaciones_plan cuando exista la tabla notificaciones
create function public.definir_plazos(
  p_plan_id uuid,
  p_fecha_limite_voto timestamptz,
  p_fecha_limite_asistencia timestamptz
)
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
    raise exception 'plan_cancelado';
  end if;

  if (p_fecha_limite_voto is distinct from v_plan.fecha_limite_voto
      and p_fecha_limite_voto <= now())
     or (p_fecha_limite_asistencia is distinct from v_plan.fecha_limite_asistencia
      and p_fecha_limite_asistencia <= now()) then
    raise exception 'plazo_en_pasado';
  end if;

  update public.planes
  set fecha_limite_voto = p_fecha_limite_voto,
      fecha_limite_asistencia = p_fecha_limite_asistencia
  where id = p_plan_id
  returning * into v_plan;
  return v_plan;
end;
$$;

revoke execute on function public.definir_plazos(uuid, timestamptz, timestamptz)
  from public, anon;
grant execute on function public.definir_plazos(uuid, timestamptz, timestamptz)
  to authenticated;

-- ---------------------------------------------------------------
-- rpc abrir_votacion
-- ---------------------------------------------------------------

-- un administrador abre la votacion con al menos un candidato; es irreversible.
-- si el plan ya esta en votacion devuelve el plan, para que un reintento no falle.
-- pendiente: llamar a sincronizar_notificaciones_plan cuando exista la tabla notificaciones
create function public.abrir_votacion(p_plan_id uuid)
returns public.planes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_candidatos integer;
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

  if v_plan.estado = 'en_votacion' then
    return v_plan;
  end if;

  if v_plan.estado <> 'recibiendo_propuestas' then
    raise exception 'fase_no_permite_preparacion';
  end if;

  select count(*) into v_candidatos
  from public.candidatos
  where plan_id = p_plan_id;
  if v_candidatos = 0 then
    raise exception 'sin_candidatos';
  end if;

  update public.planes
  set estado = 'en_votacion',
      votacion_abierta_en = now()
  where id = p_plan_id
  returning * into v_plan;
  return v_plan;
end;
$$;

revoke execute on function public.abrir_votacion(uuid) from public, anon;
grant execute on function public.abrir_votacion(uuid) to authenticated;
