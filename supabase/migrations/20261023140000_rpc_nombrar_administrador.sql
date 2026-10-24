-- rpc nombrar_administrador
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.4 y 6

-- un administrador nombra a otro participante del mismo plan. el rol es permanente
-- y no existe rpc para retirarlo. nombrar a quien ya es administrador no cambia nada
create function public.nombrar_administrador(p_plan_id uuid, p_perfil_id uuid)
returns void
language plpgsql
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

  if not exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id
      and perfil_id = v_usuario
      and rol = 'administrador'
  ) then
    raise exception 'no_autorizado';
  end if;

  select estado into v_estado from public.planes where id = p_plan_id;
  if v_estado = 'cancelado' then
    raise exception 'plan_cancelado';
  end if;

  -- una sola sentencia: si falla, los roles anteriores se conservan
  update public.participaciones
  set rol = 'administrador'
  where plan_id = p_plan_id
    and perfil_id = p_perfil_id;
  if not found then
    raise exception 'participante_no_encontrado';
  end if;
end;
$$;

revoke execute on function public.nombrar_administrador(uuid, uuid) from public, anon;
grant execute on function public.nombrar_administrador(uuid, uuid) to authenticated;
