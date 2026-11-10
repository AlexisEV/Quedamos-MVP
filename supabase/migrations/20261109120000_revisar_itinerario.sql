-- revisar itinerario: rpc guardar_itinerario, confirmar_plan y obtener_estimacion_presupuesto
-- (rf08, rf09, rf12, rb08, rb13)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.8 y 6

-- ---------------------------------------------------------------
-- funcion auxiliar
-- ---------------------------------------------------------------

-- hay empate pendiente si quedan cupos del itinerario sin elegir entre los votados
-- (misma regla que resolver_empate)
create function public.tiene_empate_pendiente(p_plan_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select least(p.max_actividades, count(*) filter (where c.total_votos > 0))
       > count(*) filter (where c.seleccionado)
     from public.planes p
     left join public.candidatos c on c.plan_id = p.id
     where p.id = p_plan_id
     group by p.max_actividades),
    false
  );
$$;

revoke execute on function public.tiene_empate_pendiente(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------
-- rpc guardar_itinerario
-- ---------------------------------------------------------------

-- un administrador guarda el orden y la fecha y hora de inicio de todas las actividades.
-- p_actividades es una lista [{id, inicio}] en el orden de ejecucion; inicio null deja la
-- actividad sin fecha y hora. un inicio nuevo debe ser futuro; uno sin cambios se acepta.
-- pendiente: en confirmado registrar cambios_plan tipo horario y sincronizar avisos (rf10)
create function public.guardar_itinerario(p_plan_id uuid, p_actividades jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_enviadas integer;
  v_ids uuid[];
  v_inicios timestamptz[];
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

  if v_plan.estado <> 'preparando_itinerario' then
    raise exception 'fase_no_permite_itinerario';
  end if;
  if public.tiene_empate_pendiente(p_plan_id) then
    raise exception 'empate_pendiente';
  end if;

  if p_actividades is null or jsonb_typeof(p_actividades) <> 'array' then
    raise exception 'actividades_no_coinciden';
  end if;

  -- la posicion de cada actividad es su indice en la lista
  select coalesce(array_agg((elemento ->> 'id')::uuid order by orden), '{}'),
    coalesce(
      array_agg(nullif(elemento ->> 'inicio', '')::timestamptz order by orden),
      '{}'
    )
  into v_ids, v_inicios
  from jsonb_array_elements(p_actividades) with ordinality as e (elemento, orden);

  -- la lista debe contener exactamente las actividades del plan, cada una una vez
  select count(distinct n.actividad_id) into v_enviadas
  from unnest(v_ids) as n (actividad_id)
  where n.actividad_id is not null;
  if v_enviadas <> cardinality(v_ids)
    or v_enviadas <> (
      select count(*) from public.actividades_itinerario where plan_id = p_plan_id
    )
    or exists (
      select 1 from unnest(v_ids) as n (actividad_id)
      where not exists (
        select 1 from public.actividades_itinerario a
        where a.id = n.actividad_id and a.plan_id = p_plan_id
      )
    ) then
    raise exception 'actividades_no_coinciden';
  end if;

  if exists (
    select 1 from unnest(v_ids, v_inicios) as n (id, inicio)
    join public.actividades_itinerario a on a.id = n.id
    where n.inicio is not null
      and n.inicio is distinct from a.inicio
      and n.inicio <= now()
  ) then
    raise exception 'inicio_en_pasado';
  end if;

  -- la restriccion unica de posicion es diferida y permite intercambiar posiciones
  update public.actividades_itinerario a
  set posicion = n.posicion, inicio = n.inicio
  from unnest(v_ids, v_inicios) with ordinality as n (id, inicio, posicion)
  where a.id = n.id
    and (a.posicion is distinct from n.posicion or a.inicio is distinct from n.inicio);
end;
$$;

revoke execute on function public.guardar_itinerario(uuid, jsonb) from public, anon;
grant execute on function public.guardar_itinerario(uuid, jsonb) to authenticated;

-- ---------------------------------------------------------------
-- rpc confirmar_plan
-- ---------------------------------------------------------------

-- un administrador confirma el itinerario de forma irreversible. el exceso de presupuesto
-- no lo impide; todas las actividades necesitan fecha y hora.
-- pendiente: generar los avisos de actividad cuando exista la tabla notificaciones
create function public.confirmar_plan(p_plan_id uuid)
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

  -- ya confirmado: devuelve el plan para que un reintento no falle
  if v_plan.estado = 'confirmado' then
    return v_plan;
  end if;
  if v_plan.estado <> 'preparando_itinerario' then
    raise exception 'fase_no_permite_confirmar';
  end if;
  if public.tiene_empate_pendiente(p_plan_id) then
    raise exception 'empate_pendiente';
  end if;
  if not exists (
    select 1 from public.actividades_itinerario where plan_id = p_plan_id
  ) then
    raise exception 'sin_actividades';
  end if;
  if exists (
    select 1 from public.actividades_itinerario
    where plan_id = p_plan_id and inicio is null
  ) then
    raise exception 'actividades_sin_horario';
  end if;

  update public.planes
  set estado = 'confirmado', confirmado_en = now()
  where id = p_plan_id
  returning * into v_plan;

  return v_plan;
end;
$$;

revoke execute on function public.confirmar_plan(uuid) from public, anon;
grant execute on function public.confirmar_plan(uuid) to authenticated;

-- ---------------------------------------------------------------
-- rpc obtener_estimacion_presupuesto
-- ---------------------------------------------------------------

-- suma por persona de los precios conocidos de las actividades del itinerario (rb08).
-- incompleta indica que alguna actividad no tiene precio; excede compara la suma
-- disponible con el presupuesto por persona.
create function public.obtener_estimacion_presupuesto(p_plan_id uuid)
returns table (
  presupuesto_soles numeric,
  total_estimado numeric,
  actividades integer,
  sin_precio integer,
  incompleta boolean,
  excede boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;
  if not exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = v_usuario
  ) then
    raise exception 'no_autorizado';
  end if;

  return query
  select p.presupuesto_soles,
    coalesce(sum(l.precio_estimado_pen), 0)::numeric,
    count(a.id)::integer,
    (count(a.id) - count(l.precio_estimado_pen))::integer,
    count(a.id) > count(l.precio_estimado_pen),
    coalesce(sum(l.precio_estimado_pen), 0) > p.presupuesto_soles
  from public.planes p
  left join public.actividades_itinerario a on a.plan_id = p.id
  left join public.lugares l on l.id = a.lugar_id
  where p.id = p_plan_id
  group by p.presupuesto_soles;
end;
$$;

revoke execute on function public.obtener_estimacion_presupuesto(uuid) from public, anon;
grant execute on function public.obtener_estimacion_presupuesto(uuid) to authenticated;
