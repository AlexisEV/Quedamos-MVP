-- rpc unirse_con_codigo
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.3, 3.4 y 6

-- une al usuario actual como participante del plan del codigo. el codigo se
-- normaliza a mayusculas; un codigo inexistente o de un plan cancelado es invalido.
-- si ya participaba no se duplica la fila y se informa con ya_participaba.
-- la sincronizacion de avisos se agrega cuando exista la tabla notificaciones
create function public.unirse_con_codigo(p_codigo text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_codigo text := upper(trim(coalesce(p_codigo, '')));
  v_plan_id uuid;
  v_insertada uuid;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  select id into v_plan_id
  from public.planes
  where codigo_invitacion = v_codigo
    and estado <> 'cancelado';
  if not found then
    raise exception 'codigo_invalido';
  end if;

  insert into public.participaciones (plan_id, perfil_id, rol)
  values (v_plan_id, v_usuario, 'participante')
  on conflict (plan_id, perfil_id) do nothing
  returning id into v_insertada;

  return jsonb_build_object(
    'plan_id', v_plan_id,
    'ya_participaba', v_insertada is null
  );
end;
$$;

revoke execute on function public.unirse_con_codigo(text) from public, anon;
grant execute on function public.unirse_con_codigo(text) to authenticated;
