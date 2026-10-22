-- rpc crear_plan y generador del codigo de invitacion
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.3, 3.4 y 6

-- codigo de 6 caracteres alfanumericos en mayusculas; la unicidad la asegura la tabla
create function public.generar_codigo_invitacion()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_alfabeto constant text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  v_codigo text := '';
begin
  for i in 1..6 loop
    v_codigo := v_codigo || substr(v_alfabeto, 1 + floor(random() * 36)::int, 1);
  end loop;
  return v_codigo;
end;
$$;

revoke execute on function public.generar_codigo_invitacion() from public, anon, authenticated;

-- crea el plan, su codigo y la participacion del creador como primer administrador.
-- p_plan_id lo genera la app: repetir la llamada con el mismo id devuelve el plan
-- ya creado en lugar de duplicarlo
create function public.crear_plan(
  p_plan_id uuid,
  p_nombre text,
  p_presupuesto_soles numeric,
  p_max_propuestas integer,
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
  v_nombre text := trim(coalesce(p_nombre, ''));
  v_plan public.planes;
  v_intentos integer := 0;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;
  if p_plan_id is null then
    raise exception 'plan_id_requerido';
  end if;

  -- reintento del mismo pedido
  select * into v_plan from public.planes where id = p_plan_id;
  if found then
    if v_plan.creado_por <> v_usuario then
      raise exception 'no_autorizado';
    end if;
    return v_plan;
  end if;

  if length(v_nombre) = 0 then
    raise exception 'nombre_requerido';
  end if;
  -- el limite superior evita el desborde de numeric(10, 2)
  if p_presupuesto_soles is null
     or p_presupuesto_soles < 0
     or p_presupuesto_soles >= 100000000 then
    raise exception 'presupuesto_invalido';
  end if;
  if p_max_propuestas is null or p_max_propuestas not between 1 and 5
     or p_max_candidatos is null or p_max_candidatos not between 2 and 10
     or p_max_selecciones is null or p_max_selecciones not between 1 and 5
     or p_max_actividades is null or p_max_actividades not between 1 and 5 then
    raise exception 'limite_fuera_de_rango';
  end if;
  if p_max_selecciones > p_max_candidatos then
    raise exception 'selecciones_mayores_que_candidatos';
  end if;

  loop
    v_intentos := v_intentos + 1;
    begin
      insert into public.planes (
        id, nombre, presupuesto_soles, max_propuestas_por_persona,
        max_candidatos, max_selecciones, max_actividades,
        codigo_invitacion, creado_por
      )
      values (
        p_plan_id, v_nombre, round(p_presupuesto_soles, 2), p_max_propuestas,
        p_max_candidatos, p_max_selecciones, p_max_actividades,
        public.generar_codigo_invitacion(), v_usuario
      )
      returning * into v_plan;
      exit;
    exception when unique_violation then
      -- un pedido concurrente con el mismo id ya creo el plan
      select * into v_plan from public.planes where id = p_plan_id;
      if found then
        if v_plan.creado_por <> v_usuario then
          raise exception 'no_autorizado';
        end if;
        return v_plan;
      end if;
      -- si no, choco el codigo: se genera otro
      if v_intentos >= 10 then
        raise exception 'codigo_no_disponible';
      end if;
    end;
  end loop;

  insert into public.participaciones (plan_id, perfil_id, rol, es_creador)
  values (p_plan_id, v_usuario, 'administrador', true);

  return v_plan;
end;
$$;

revoke execute on function public.crear_plan(uuid, text, numeric, integer, integer, integer, integer)
  from public, anon;
grant execute on function public.crear_plan(uuid, text, numeric, integer, integer, integer, integer)
  to authenticated;
