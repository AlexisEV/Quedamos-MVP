-- propuestas y candidatos con las rpc proponer_lugar y retirar_propuesta (rf05, rb02, rb07)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.5, 3.6, 5 y 6

-- ---------------------------------------------------------------
-- tablas
-- ---------------------------------------------------------------

create table public.propuestas (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.planes (id) on delete cascade,
  lugar_id uuid not null references public.lugares (id),
  propuesto_por uuid not null references public.perfiles (id),
  created_at timestamptz not null default now(),
  -- un lugar solo puede proponerse una vez por plan
  unique (plan_id, lugar_id)
);

-- lista final elegida por administradores; inmutable desde en_votacion
create table public.candidatos (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.planes (id) on delete cascade,
  lugar_id uuid not null references public.lugares (id),
  -- instantanea calculada al cerrar la votacion
  total_votos integer,
  seleccionado boolean not null default false,
  created_at timestamptz not null default now(),
  unique (plan_id, lugar_id)
);

alter table public.propuestas enable row level security;
alter table public.candidatos enable row level security;

-- sin politicas de escritura: solo las rpc escriben
create policy propuestas_select_participante on public.propuestas
  for select to authenticated
  using (public.es_participante(plan_id));

create policy candidatos_select_participante on public.candidatos
  for select to authenticated
  using (public.es_participante(plan_id));

-- ---------------------------------------------------------------
-- rpc proponer_lugar
-- ---------------------------------------------------------------

-- un participante propone un lugar publicado del catalogo mientras el plan recibe propuestas.
-- si el mismo usuario ya lo propuso devuelve esa propuesta, para que un reintento no falle
create function public.proponer_lugar(p_plan_id uuid, p_lugar_id uuid)
returns public.propuestas
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.planes;
  v_existente public.propuestas;
  v_propias integer;
  v_nueva public.propuestas;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  -- el bloqueo del plan serializa las propuestas simultaneas para respetar el limite
  select * into v_plan from public.planes where id = p_plan_id for update;
  if not found or not exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = v_usuario
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_plan.estado <> 'recibiendo_propuestas' then
    raise exception 'fase_no_permite_propuestas';
  end if;

  if not exists (
    select 1 from public.lugares where id = p_lugar_id and publicado
  ) then
    raise exception 'lugar_no_disponible';
  end if;

  select * into v_existente
  from public.propuestas
  where plan_id = p_plan_id and lugar_id = p_lugar_id;
  if found then
    if v_existente.propuesto_por = v_usuario then
      return v_existente;
    end if;
    raise exception 'lugar_ya_propuesto';
  end if;

  select count(*) into v_propias
  from public.propuestas
  where plan_id = p_plan_id and propuesto_por = v_usuario;
  if v_propias >= v_plan.max_propuestas_por_persona then
    raise exception 'limite_propuestas_alcanzado';
  end if;

  insert into public.propuestas (plan_id, lugar_id, propuesto_por)
  values (p_plan_id, p_lugar_id, v_usuario)
  returning * into v_nueva;
  return v_nueva;
end;
$$;

revoke execute on function public.proponer_lugar(uuid, uuid) from public, anon;
grant execute on function public.proponer_lugar(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------
-- rpc retirar_propuesta
-- ---------------------------------------------------------------

-- el autor o un administrador retira una propuesta mientras el plan recibe propuestas.
-- libera el cupo del autor y quita el lugar de la lista de candidatos si estaba.
-- una propuesta que ya no existe no cambia nada, para que un reintento no falle
create function public.retirar_propuesta(p_propuesta_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_propuesta public.propuestas;
  v_estado public.plan_estado;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  select * into v_propuesta from public.propuestas where id = p_propuesta_id;
  if not found then
    return;
  end if;

  select estado into v_estado
  from public.planes
  where id = v_propuesta.plan_id
  for update;

  if v_propuesta.propuesto_por <> v_usuario and not exists (
    select 1 from public.participaciones
    where plan_id = v_propuesta.plan_id
      and perfil_id = v_usuario
      and rol = 'administrador'
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_estado <> 'recibiendo_propuestas' then
    raise exception 'fase_no_permite_propuestas';
  end if;

  delete from public.candidatos
  where plan_id = v_propuesta.plan_id and lugar_id = v_propuesta.lugar_id;
  delete from public.propuestas where id = p_propuesta_id;
end;
$$;

revoke execute on function public.retirar_propuesta(uuid) from public, anon;
grant execute on function public.retirar_propuesta(uuid) to authenticated;
