-- migracion base: enums, perfiles, planes, participaciones, funciones auxiliares y rls
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 2, 3.1, 3.3, 3.4, 4 y 5

-- ---------------------------------------------------------------
-- tipos enumerados
-- ---------------------------------------------------------------

-- estados definitivos; el flujo es unidireccional y no se retrocede de fase
create type public.plan_estado as enum (
  'recibiendo_propuestas', 'en_votacion', 'preparando_itinerario', 'confirmado', 'cancelado'
);

create type public.rol_plan as enum ('administrador', 'participante');
create type public.asistencia_estado as enum ('pendiente', 'asistire', 'no_asistire');
create type public.notificacion_tipo as enum ('actividad', 'voto', 'asistencia', 'cambio', 'cancelacion');
create type public.notificacion_estado as enum ('activa', 'anulada');

-- las etiquetas visibles con tildes y mayusculas se resuelven en la app
create type public.lugar_zona as enum (
  'centro_historico', 'yanahuara', 'cayma', 'vallecito', 'cercado'
);

create type public.lugar_categoria as enum (
  'restaurantes', 'cafes_y_postres', 'bares', 'entretenimiento_y_cultura'
);

-- ---------------------------------------------------------------
-- funcion comun para mantener updated_at
-- ---------------------------------------------------------------

create function public.fijar_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------
-- perfiles (1:1 con auth.users)
-- ---------------------------------------------------------------

create table public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre_visible text not null
    check (length(trim(nombre_visible)) between 1 and 40),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger perfiles_fijar_updated_at
  before update on public.perfiles
  for each row execute function public.fijar_updated_at();

-- crea el perfil al registrarse con el nombre_visible enviado en signUp
create function public.crear_perfil_de_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfiles (id, nombre_visible)
  values (new.id, trim(new.raw_user_meta_data ->> 'nombre_visible'));
  return new;
end;
$$;

create trigger crear_perfil_al_registrarse
  after insert on auth.users
  for each row execute function public.crear_perfil_de_usuario();

-- ---------------------------------------------------------------
-- planes
-- ---------------------------------------------------------------

create table public.planes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  estado public.plan_estado not null default 'recibiendo_propuestas',
  presupuesto_soles numeric(10, 2) not null check (presupuesto_soles >= 0),
  max_propuestas_por_persona smallint not null default 3
    check (max_propuestas_por_persona between 1 and 5),
  max_candidatos smallint not null default 6
    check (max_candidatos between 2 and 10),
  max_selecciones smallint not null default 3
    check (max_selecciones between 1 and 5),
  max_actividades smallint not null default 3
    check (max_actividades between 1 and 5),
  fecha_limite_voto timestamptz,
  fecha_limite_asistencia timestamptz,
  codigo_invitacion char(6) not null unique
    check (codigo_invitacion ~ '^[A-Z0-9]{6}$'),
  creado_por uuid not null references public.perfiles (id),
  votacion_abierta_en timestamptz,
  votacion_cerrada_en timestamptz,
  confirmado_en timestamptz,
  cancelado_en timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (max_selecciones <= max_candidatos)
);

create trigger planes_fijar_updated_at
  before update on public.planes
  for each row execute function public.fijar_updated_at();

-- ---------------------------------------------------------------
-- participaciones
-- ---------------------------------------------------------------

create table public.participaciones (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.planes (id) on delete cascade,
  perfil_id uuid not null references public.perfiles (id),
  rol public.rol_plan not null default 'participante',
  es_creador boolean not null default false,
  asistencia public.asistencia_estado not null default 'pendiente',
  asistencia_actualizada_en timestamptz,
  votos_guardados_en timestamptz,
  unido_en timestamptz not null default now(),
  -- unirse dos veces no duplica la participacion
  unique (plan_id, perfil_id)
);

-- acelera la lista de planes del usuario y las politicas rls
create index participaciones_perfil_id_idx on public.participaciones (perfil_id);

-- ---------------------------------------------------------------
-- funciones auxiliares
-- ---------------------------------------------------------------

-- devuelve true si el usuario actual participa en el plan
create function public.es_participante(p_plan_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = auth.uid()
  );
$$;

-- devuelve true si el usuario actual es administrador del plan
create function public.es_administrador(p_plan_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = auth.uid()
      and rol = 'administrador'
  );
$$;

-- devuelve true si el usuario actual comparte algun plan con el perfil indicado
create function public.comparte_plan_con(p_perfil_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.participaciones propia
    join public.participaciones ajena on ajena.plan_id = propia.plan_id
    where propia.perfil_id = auth.uid() and ajena.perfil_id = p_perfil_id
  );
$$;

-- ---------------------------------------------------------------
-- rls
-- ---------------------------------------------------------------

alter table public.perfiles enable row level security;
alter table public.planes enable row level security;
alter table public.participaciones enable row level security;

-- perfil propio o de co-participantes de algun plan comun
create policy perfiles_select_propio_o_grupo on public.perfiles
  for select to authenticated
  using (id = (select auth.uid()) or public.comparte_plan_con(id));

-- solo el propio perfil y solo la columna nombre_visible
create policy perfiles_update_propio on public.perfiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

revoke update on public.perfiles from anon, authenticated;
grant update (nombre_visible) on public.perfiles to authenticated;

-- planes y participaciones solo se leen dentro del grupo; las escrituras pasan por rpc
create policy planes_select_participante on public.planes
  for select to authenticated
  using (public.es_participante(id));

create policy participaciones_select_participante on public.participaciones
  for select to authenticated
  using (public.es_participante(plan_id));
