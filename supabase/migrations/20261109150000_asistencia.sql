-- asistencia: rpc responder_asistencia (rf16)
-- referencia: docs/04_DATABASE_SCHEMA.md secciones 3.3 y 6

-- ---------------------------------------------------------------
-- rpc responder_asistencia
-- ---------------------------------------------------------------

-- cada integrante responde para toda la salida, solo con el plan confirmado.
-- pendiente es solo el valor inicial: el servidor no acepta volver a el.
-- el plazo de asistencia no bloquea: se puede responder aunque haya vencido.
-- pendiente: anular o restituir avisos cuando exista la tabla notificaciones (rf14)
create function public.responder_asistencia(p_plan_id uuid, p_estado text)
returns public.participaciones
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_estado_plan public.plan_estado;
  v_participacion public.participaciones;
begin
  if v_usuario is null then
    raise exception 'no_autenticado';
  end if;

  if p_estado is null or p_estado not in ('asistire', 'no_asistire') then
    raise exception 'asistencia_invalida';
  end if;

  select estado into v_estado_plan from public.planes where id = p_plan_id;
  if not found or not exists (
    select 1 from public.participaciones
    where plan_id = p_plan_id and perfil_id = v_usuario
  ) then
    raise exception 'no_autorizado';
  end if;

  if v_estado_plan = 'cancelado' then
    raise exception 'plan_cancelado';
  end if;
  if v_estado_plan <> 'confirmado' then
    raise exception 'plan_no_confirmado';
  end if;

  update public.participaciones
  set asistencia = p_estado::public.asistencia_estado,
      asistencia_actualizada_en = now()
  where plan_id = p_plan_id and perfil_id = v_usuario
  returning * into v_participacion;
  return v_participacion;
end;
$$;

revoke execute on function public.responder_asistencia(uuid, text) from public, anon;
grant execute on function public.responder_asistencia(uuid, text) to authenticated;
