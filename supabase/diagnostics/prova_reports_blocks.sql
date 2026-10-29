-- ============================================================================
-- Pujobaixo · Prova automàtica de reportar, bloquejar i perfil públic
-- ----------------------------------------------------------------------------
-- Simula dues persones usuàries (A i B) amb el rol `authenticated`, com faria
-- l'app, i comprova RLS, triggers i funcions. Al final llança un error a
-- propòsit amb els resultats: així Postgres DESFÀ TOT el que s'ha fet
-- (cap report, cap bloqueig, cap correu). L'"error" és el resultat de la prova.
--
-- Requereix: almenys un viatge actiu i dos perfils. Executar sencer al SQL Editor.
-- ============================================================================

do $t$
declare
  a      uuid;
  b      uuid;
  trip   uuid;
  r      text := '';
  ok     boolean;
  v      json;
  n      int;
  stored uuid;
begin
  -- B = qui té el proper viatge actiu; A = qualsevol altra persona
  select t.driver_id, t.id into b, trip
  from public.trips t where t.status = 'active' and t.depart_at > now()
  order by t.depart_at limit 1;
  if b is null then raise exception 'Cal almenys un viatge actiu per fer la prova.'; end if;
  select id into a from public.profiles where id <> b limit 1;
  if a is null then raise exception 'Cal almenys dos perfils per fer la prova.'; end if;

  -- 1 · Sense sessió (anon) no es pot cridar public_profile
  execute 'set local role anon';
  begin
    perform public.public_profile(b);
    ok := false;
  exception when insufficient_privilege then ok := true;
  end;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '1. Sense sessió no es pot veure cap perfil' || chr(10);

  -- A partir d'aquí, som A
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', a::text, true);
  execute 'set local role authenticated';

  -- 2 · public_profile només retorna els camps permesos
  v := public.public_profile(b);
  ok := v is not null and (select array_agg(k order by k) from json_object_keys(v) k)
        = array['avatar_url','first_name','id','interests','last_initial','offers_count','requests_count']::text[];
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '2. El perfil públic només dona nom, inicial, foto, preferències i comptadors' || chr(10);

  -- 3 · Report: la persona reportada la decideix el servidor (s'envia un id fals)
  begin
    insert into public.reports (reporter_id, reported_user_id, trip_id, reason, details)
    values (a, gen_random_uuid(), trip, 'other', 'prova-automatica');
    execute 'reset role';
    select reported_user_id into stored from public.reports where reporter_id = a and trip_id = trip;
    execute 'set local role authenticated';
    ok := stored = b;
  exception when others then ok := false; r := r || '      (' || sqlerrm || ')' || chr(10);
  end;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '3. El report es desa i apunta a qui ha publicat el viatge' || chr(10);

  -- 4 · No es pot reportar dues vegades el mateix viatge
  begin
    insert into public.reports (reporter_id, reported_user_id, trip_id, reason) values (a, b, trip, 'spam');
    ok := false;
  exception when unique_violation then ok := true;
  end;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '4. Un segon report del mateix viatge es rebutja' || chr(10);

  -- 5 · Ningú pot llegir els reports des de l'app
  begin
    perform count(*) from public.reports;
    ok := false;
  exception when insufficient_privilege then ok := true;
  end;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '5. Els reports no es poden llegir des de l''app' || chr(10);

  -- 6 · Límit de 5 reports en 24 h (ja n'hi ha 1)
  begin
    for n in 1..4 loop
      insert into public.reports (reporter_id, reported_user_id, reason) values (a, b, 'other');
    end loop;
    begin
      insert into public.reports (reporter_id, reported_user_id, reason) values (a, b, 'other');
      ok := false;
    exception when others then ok := sqlerrm like '%reports_rate_limit%';
    end;
  exception when others then ok := false; r := r || '      (' || sqlerrm || ')' || chr(10);
  end;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '6. El 6è report en 24 h es rebutja' || chr(10);

  -- 7 · A bloqueja B: A deixa de veure B
  insert into public.blocks (blocker_id, blocked_id) values (a, b);
  ok := b = any (array(select public.hidden_user_ids()));
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '7. Qui bloqueja deixa de veure la persona bloquejada' || chr(10);

  -- 8 · El perfil de B ja no és visible per a A
  ok := public.public_profile(b) is null;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '8. Amb bloqueig, el perfil públic no es mostra' || chr(10);

  -- 9 · La llista "Persones bloquejades" d'A inclou B
  ok := exists (select 1 from public.my_blocks() m where m.blocked_id = b);
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '9. La llista de persones bloquejades funciona' || chr(10);

  -- Ara som B
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', b::text, true);

  -- 10 · B tampoc veu A, però no pot saber qui l'ha bloquejat
  ok := a = any (array(select public.hidden_user_ids()));
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '10. La persona bloquejada tampoc veu qui l''ha bloquejat' || chr(10);
  select count(*) into n from public.blocks;
  ok := n = 0;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '11. La persona bloquejada no pot llegir la taula de bloquejos' || chr(10);

  -- Ara som A: desbloquejar
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', a::text, true);
  delete from public.blocks where blocker_id = a and blocked_id = b;
  ok := not (b = any (array(select public.hidden_user_ids()))) and public.public_profile(b) is not null;
  r := r || case when ok then 'OK    ' else 'FALLA ' end || '12. Desbloquejar torna a mostrar la persona' || chr(10);

  execute 'reset role';
  raise exception using message = 'RESULTATS (tot desfet, res desat, cap correu):' || chr(10) || r;
end
$t$;
