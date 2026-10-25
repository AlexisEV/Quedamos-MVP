-- votar: tabla votos y rpc guardar_votos y obtener_totales_votacion (rf06, rf07, rb03, rb04)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.4, 3.7, 5 y 6

-- ---------------------------------------------------------------
-- tabla
-- ---------------------------------------------------------------

create table public.votos (
  id uuid primary key default gen_random_uuid(),
  -- redundante con el candidato para filtrar por plan
  plan_id uuid not null references public.planes (id) on delete cascade,
  candidato_id uuid not null references public.candidatos (id) on delete cascade,
  perfil_id uuid not null references public.perfiles (id),
  created_at timestamptz not null default now(),
  -- cada lugar cuenta una vez por persona
  unique (candidato_id, perfil_id)
);

create index votos_plan_perfil_idx on public.votos (plan_id, perfil_id);

alter table public.votos enable row level security;

-- cada persona solo ve su propia seleccion; sin politicas de escritura: solo guardar_votos escribe
create policy votos_select_propio on public.votos
  for select to authenticated
  using (perfil_id = (select auth.uid()));

-- ---------------------------------------------------------------
-- rpc guardar_votos
-- ---------------------------------------------------------------

-- un participante reemplaza su seleccion completa mientras la votacion esta abierta.
-- conserva las filas que siguen elegidas para que un reintento no duplique ni cambie votos.
-- pendiente: anular el aviso de voto cuando exista la tabla notificaciones
create function public.guardar_votos(p_plan_id uuid, p_candidato_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_candidatos uuid[];
  v_total_candidatos integer;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  -- bloqueo compartido: los votos no se bloquean entre si, pero esperan a un cierre en curso
  select * into v_plan from public.planes where id = p_plan_id for share;
  if not found or not exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = v_usuario
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_plan.estado = 'recibiendo_propuestas' then
    raise exception 'votacion_no_abierta';
  end if;
  if v_plan.estado <> 'en_votacion' then
    raise exception 'votacion_cerrada';
  end if;

  -- quita nulos y repetidos
  select coalesce(array_agg(distinct candidato), '{}') into v_candidatos
  from unnest(coalesce(p_candidato_ids, '{}')) as candidato
  where candidato is not null;

  if cardinality(v_candidatos) = 0 then
    raise exception 'seleccion_vacia';
  end if;

  if exists (
    select 1 from unnest(v_candidatos) as candidato
    where not exists (
      select 1 from public.candidatos
      where id = candidato and plan_id = p_plan_id
    )
  ) then
    raise exception 'candidato_no_valido';
  end if;

  select count(*) into v_total_candidatos
  from public.candidatos
  where plan_id = p_plan_id;
  if cardinality(v_candidatos) > least(v_plan.max_selecciones, v_total_candidatos) then
    raise exception 'limite_selecciones_superado';
  end if;

  delete from public.votos
  where plan_id = p_plan_id and perfil_id = v_usuario
    and candidato_id <> all (v_candidatos);

  insert into public.votos (plan_id, candidato_id, perfil_id)
  select p_plan_id, candidato, v_usuario from unnest(v_candidatos) as candidato
  on conflict (candidato_id, perfil_id) do nothing;

  -- guardar elecciones completa la accion de voto
  update public.participaciones
  set votos_guardados_en = now()
  where plan_id = p_plan_id and perfil_id = v_usuario;
end;
$$;

revoke execute on function public.guardar_votos(uuid, uuid[]) from public, anon;
grant execute on function public.guardar_votos(uuid, uuid[]) to authenticated;

-- ---------------------------------------------------------------
-- rpc obtener_totales_votacion
-- ---------------------------------------------------------------

-- totales por candidato sin identificar votantes; incluye candidatos con 0 votos
create function public.obtener_totales_votacion(p_plan_id uuid)
returns table (candidato_id uuid, lugar_id uuid, total integer)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_estado public.plan_estado;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  select p.estado into v_estado from public.planes p where p.id = p_plan_id;
  if not found or not exists (
    select 1 from public.participaciones pa
    where pa.plan_id = p_plan_id and pa.perfil_id = v_usuario
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_estado = 'recibiendo_propuestas' then
    raise exception 'votacion_no_abierta';
  end if;

  return query
  select c.id, c.lugar_id, count(v.id)::integer
  from public.candidatos c
  left join public.votos v on v.candidato_id = c.id
  where c.plan_id = p_plan_id
  group by c.id, c.lugar_id, c.created_at
  order by c.created_at, c.id;
end;
$$;

revoke execute on function public.obtener_totales_votacion(uuid) from public, anon;
grant execute on function public.obtener_totales_votacion(uuid) to authenticated;
