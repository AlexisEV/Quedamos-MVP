-- cerrar votacion: tabla actividades_itinerario y rpc cerrar_votacion y resolver_empate (rf08, rb05, rb06)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.6, 3.8, 5 y 6

-- ---------------------------------------------------------------
-- tabla
-- ---------------------------------------------------------------

create table public.actividades_itinerario (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.planes (id) on delete cascade,
  lugar_id uuid not null references public.lugares (id),
  -- origen en la votacion; null tras un reemplazo
  candidato_id uuid unique references public.candidatos (id),
  posicion smallint not null check (posicion between 1 and 5),
  -- null indica actividad sin fecha y hora asignadas
  inicio timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- diferida para reordenar dentro de una transaccion
  constraint actividades_itinerario_plan_posicion_key
    unique (plan_id, posicion) deferrable initially deferred
);

create trigger actividades_itinerario_fijar_updated_at
  before update on public.actividades_itinerario
  for each row execute function public.fijar_updated_at();

alter table public.actividades_itinerario enable row level security;

-- sin politicas de escritura: solo las rpc escriben
create policy actividades_itinerario_select_participante on public.actividades_itinerario
  for select to authenticated
  using (public.es_participante(plan_id));

-- ---------------------------------------------------------------
-- rpc cerrar_votacion
-- ---------------------------------------------------------------

-- un administrador cierra la votacion de forma manual e irreversible.
-- guarda los totales, selecciona los candidatos con al menos un voto hasta max_actividades
-- y crea sus actividades; si hay empate en el ultimo puesto los empatados quedan sin
-- seleccionar para que un administrador elija con resolver_empate.
-- pendiente: anular los avisos de voto cuando exista la tabla notificaciones
create function public.cerrar_votacion(p_plan_id uuid)
returns public.planes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_corte integer;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  -- bloqueo exclusivo: espera a los votos en curso y bloquea los nuevos hasta terminar
  select * into v_plan from public.planes where id = p_plan_id for update;
  if not found or not exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = v_usuario and rol = 'administrador'
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_plan.estado = 'recibiendo_propuestas' then
    raise exception 'votacion_no_abierta';
  end if;
  if v_plan.estado = 'cancelado' then
    raise exception 'plan_cancelado';
  end if;
  -- ya cerrada: devuelve el plan para que un reintento no falle
  if v_plan.estado <> 'en_votacion' then
    return v_plan;
  end if;

  if not exists (select 1 from public.candidatos where plan_id = p_plan_id) then
    raise exception 'sin_candidatos';
  end if;
  if not exists (select 1 from public.votos where plan_id = p_plan_id) then
    raise exception 'sin_votos';
  end if;

  update public.candidatos c
  set total_votos = (select count(*) from public.votos v where v.candidato_id = c.id)
  where c.plan_id = p_plan_id;

  -- total del candidato votado en el ultimo puesto disponible; null si caben todos los votados
  select total_votos into v_corte
  from public.candidatos
  where plan_id = p_plan_id and total_votos > 0
  order by total_votos desc
  offset v_plan.max_actividades - 1
  limit 1;

  if v_corte is null or (
    select count(*) from public.candidatos
    where plan_id = p_plan_id and total_votos >= v_corte
  ) <= v_plan.max_actividades then
    -- sin empate en el corte: pasan todos los votados que caben
    update public.candidatos
    set seleccionado = true
    where plan_id = p_plan_id and total_votos > 0
      and total_votos >= coalesce(v_corte, 1);
  else
    -- empate en el corte: solo pasan los que superan el total empatado
    update public.candidatos
    set seleccionado = true
    where plan_id = p_plan_id and total_votos > v_corte;
  end if;

  -- posiciones iniciales por votos; el orden de ejecucion lo define luego un administrador
  insert into public.actividades_itinerario (plan_id, lugar_id, candidato_id, posicion)
  select p_plan_id, c.lugar_id, c.id,
    row_number() over (order by c.total_votos desc, c.created_at, c.id)
  from public.candidatos c
  where c.plan_id = p_plan_id and c.seleccionado;

  update public.planes
  set estado = 'preparando_itinerario', votacion_cerrada_en = now()
  where id = p_plan_id
  returning * into v_plan;

  return v_plan;
end;
$$;

revoke execute on function public.cerrar_votacion(uuid) from public, anon;
grant execute on function public.cerrar_votacion(uuid) to authenticated;

-- ---------------------------------------------------------------
-- rpc resolver_empate
-- ---------------------------------------------------------------

-- un administrador elige entre los empatados del ultimo puesto exactamente los cupos libres.
-- los empatados son los votados sin seleccionar con el mayor total entre ellos.
-- la eleccion es definitiva y crea las actividades que faltan al final del itinerario.
create function public.resolver_empate(p_plan_id uuid, p_candidato_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_elegidos uuid[];
  v_seleccionados integer;
  v_votados integer;
  v_cupos integer;
  v_total_empate integer;
  v_ultima_posicion integer;
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
    raise exception 'fase_no_permite_desempate';
  end if;

  -- quita nulos y repetidos
  select coalesce(array_agg(distinct candidato), '{}') into v_elegidos
  from unnest(coalesce(p_candidato_ids, '{}')) as candidato
  where candidato is not null;

  select count(*) filter (where seleccionado), count(*) filter (where total_votos > 0)
  into v_seleccionados, v_votados
  from public.candidatos
  where plan_id = p_plan_id;

  v_cupos := least(v_plan.max_actividades, v_votados) - v_seleccionados;
  if v_cupos <= 0 then
    -- reintento de un desempate ya guardado con la misma eleccion
    if cardinality(v_elegidos) > 0 and not exists (
      select 1 from unnest(v_elegidos) as candidato
      where not exists (
        select 1 from public.candidatos
        where id = candidato and plan_id = p_plan_id and seleccionado
      )
    ) then
      return;
    end if;
    raise exception 'sin_empate_pendiente';
  end if;

  select max(total_votos) into v_total_empate
  from public.candidatos
  where plan_id = p_plan_id and total_votos > 0 and not seleccionado;

  if exists (
    select 1 from unnest(v_elegidos) as candidato
    where not exists (
      select 1 from public.candidatos
      where id = candidato and plan_id = p_plan_id
        and not seleccionado and total_votos = v_total_empate
    )
  ) then
    raise exception 'candidato_no_empatado';
  end if;

  if cardinality(v_elegidos) <> v_cupos then
    raise exception 'cantidad_desempate_invalida';
  end if;

  update public.candidatos
  set seleccionado = true
  where id = any (v_elegidos);

  select coalesce(max(posicion), 0) into v_ultima_posicion
  from public.actividades_itinerario
  where plan_id = p_plan_id;

  insert into public.actividades_itinerario (plan_id, lugar_id, candidato_id, posicion)
  select p_plan_id, c.lugar_id, c.id,
    v_ultima_posicion + row_number() over (order by c.created_at, c.id)
  from public.candidatos c
  where c.id = any (v_elegidos);
end;
$$;

revoke execute on function public.resolver_empate(uuid, uuid[]) from public, anon;
grant execute on function public.resolver_empate(uuid, uuid[]) to authenticated;
