-- catalogo manual de lugares de arequipa (rf11, rb09)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.2 y 5

create table public.lugares (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  categoria public.lugar_categoria not null,
  zona public.lugar_zona not null,
  direccion text,
  latitud numeric(9,6) check (latitud between -90 and 90),
  longitud numeric(9,6) check (longitud between -180 and 180),
  -- null significa desconocido; la app no rellena valores
  horario_atencion text,
  -- precio estimado por persona en soles; null significa desconocido
  precio_estimado_pen numeric(10,2) check (precio_estimado_pen >= 0),
  precio_nota text,
  imagen_path text,
  -- procedencia y fecha de verificacion del dato (rnf07)
  fuente text not null check (length(trim(fuente)) > 0),
  fecha_revision date not null,
  publicado boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger lugares_fijar_updated_at
  before update on public.lugares
  for each row execute function public.fijar_updated_at();

alter table public.lugares enable row level security;

-- solo se leen los lugares publicados; sin politicas de escritura, solo el equipo modifica el catalogo
create policy lugares_select_publicados on public.lugares
  for select to authenticated
  using (publicado);
