-- ============================================================================
-- Pujobaixo · Avisos v2: també al conductor, trigger blindat, comptadors
-- ----------------------------------------------------------------------------
-- Requereix la migració 2026-08-30_avisos_solicituds.sql. Tot és additiu.
-- Executar sencer al SQL Editor de Supabase (si es talla, pegar per blocs).
-- ============================================================================

-- 1. match_notifications: qui rep l'avís (passatger o conductor)
alter table public.match_notifications
  add column if not exists recipient_role text not null default 'passenger',
  add column if not exists recipient_id uuid;

update public.match_notifications set recipient_id = passenger_id where recipient_id is null;

alter table public.match_notifications drop constraint if exists match_notifications_recipient_role_check;
alter table public.match_notifications add constraint match_notifications_recipient_role_check
  check (recipient_role in ('passenger', 'driver'));

-- una fila per parella i rol (abans: una per parella)
alter table public.match_notifications drop constraint if exists match_notifications_request_id_offer_id_key;
create unique index if not exists match_notifications_pair_role_uidx
  on public.match_notifications (request_id, offer_id, recipient_role);

-- El propietari d'un viatge pot llegir els avisos que ha generat (per al comptador)
drop policy if exists "owner reads own trip notifications" on public.match_notifications;
create policy "owner reads own trip notifications"
  on public.match_notifications for select
  to authenticated
  using (
    exists (
      select 1 from public.trips t
      where t.id in (match_notifications.request_id, match_notifications.offer_id)
        and t.driver_id = auth.uid()
    )
  );
grant select on public.match_notifications to authenticated;

-- 2. Vista de cruces: sense filtre d'avís ni dedupe (ho decideix cada rol)
drop view if exists public.v_pending_matches;
create or replace view public.v_matches
with (security_invoker = false) as
select
  r.id            as request_id,
  o.id            as offer_id,
  r.driver_id     as passenger_id,
  o.driver_id     as driver_id,
  r.notify_email  as request_notify,
  o.notify_email  as offer_notify,
  r.depart_at     as request_depart_at,
  o.depart_at     as offer_depart_at,
  r.origin        as request_origin,
  r.destination   as request_destination,
  r.available_seats as request_people,
  o.origin, o.destination, o.available_seats, o.price_per_seat
from public.trips r
join public.trips o
  on  o.trip_type = 'offer'
  and o.status = 'active'
  and o.available_seats > 0
  and o.depart_at > now()
  and o.driver_id <> r.driver_id
  and public.trip_sense(o.origin, o.destination) = public.trip_sense(r.origin, r.destination)
  -- marge de dia i d'hora: el més ampli dels dos
  and abs( (o.depart_at at time zone 'Europe/Madrid')::date
         - (r.depart_at at time zone 'Europe/Madrid')::date ) <= greatest(r.date_window, o.date_window)
  and abs( extract(epoch from (o.depart_at at time zone 'Europe/Madrid')::time)
         - extract(epoch from (r.depart_at at time zone 'Europe/Madrid')::time) ) / 60 <= greatest(r.time_window, o.time_window)
where r.trip_type = 'request'
  and r.status = 'active'
  and r.depart_at > now() - interval '1 day'
  and public.trip_sense(r.origin, r.destination) is not null;

revoke all on public.v_matches from anon, authenticated;

-- 3. Enviament d'un avís a un rol concret
create or replace function public.send_match_email(p_request_id uuid, p_offer_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $fn$
declare
  v_api_key   text;
  v_from      text := 'Pujobaixo <avisos@pujobaixo.cat>';
  v_to_id     uuid;
  v_email     text;
  v_to_name   text;
  v_other     text;
  m           record;
  v_link      text;
  v_subject   text;
  v_html      text;
  v_req_id    bigint;
begin
  if exists (select 1 from public.match_notifications
             where request_id = p_request_id and offer_id = p_offer_id and recipient_role = p_role) then
    return;
  end if;

  select decrypted_secret into v_api_key
  from vault.decrypted_secrets where name = 'resend_api_key' limit 1;
  if v_api_key is null then
    raise warning 'send_match_email: no resend_api_key at Vault';
    return;
  end if;

  select * into m from public.v_matches
  where request_id = p_request_id and offer_id = p_offer_id;
  if not found then return; end if;

  v_to_id := case when p_role = 'driver' then m.driver_id else m.passenger_id end;

  select u.email, coalesce(nullif(trim(p.first_name), ''), 'hola')
    into v_email, v_to_name
  from auth.users u left join public.profiles p on p.id = u.id
  where u.id = v_to_id;
  if v_email is null then return; end if;

  select coalesce(nullif(trim(p.first_name || ' ' || coalesce(left(p.last_name, 1) || '.', '')), ''), null)
    into v_other
  from public.profiles p
  where p.id = case when p_role = 'driver' then m.passenger_id else m.driver_id end;

  if p_role = 'driver' then
    v_link    := 'https://pujobaixo.cat/?trip=' || m.request_id;
    v_subject := 'Algú busca un viatge que encaixa amb el teu';
    v_html :=
      '<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:520px;margin:0 auto;color:#14151A;line-height:1.5">'
      || '<p style="font-size:16px">Hola ' || v_to_name || ',</p>'
      || '<p style="font-size:16px"><strong>' || coalesce(v_other, 'Un passatger') || '</strong> busca un viatge que encaixa amb el que has publicat:</p>'
      || '<div style="background:#F3F4F8;border-radius:14px;padding:16px;margin:16px 0">'
      || '<div style="font-size:19px;font-weight:800">' || m.request_origin || ' → ' || m.request_destination || '</div>'
      || '<div style="margin-top:8px;font-size:15px">' || public.ca_datetime(m.request_depart_at) || '</div>'
      || '<div style="margin-top:4px;font-size:13px;color:#6B6F7B">El teu viatge: ' || public.ca_datetime(m.offer_depart_at) || '</div>'
      || '<div style="margin-top:8px;font-size:14px">' || m.request_people || case when m.request_people = 1 then ' persona' else ' persones' end || '</div>'
      || '</div>'
      || '<p><a href="' || v_link || '" style="display:inline-block;background:#5B4CFB;color:#fff;text-decoration:none;font-weight:700;padding:12px 24px;border-radius:14px;font-size:15px">Veure la sol·licitud i contactar</a></p>'
      || '<p style="font-size:13px;color:#6B6F7B;margin-top:24px">Reps aquest correu perquè has publicat un viatge a Pujobaixo amb l''avís activat. Pots desactivar-lo editant el viatge.</p>'
      || '</div>';
  else
    v_link    := 'https://pujobaixo.cat/?trip=' || m.offer_id;
    v_subject := 'Hi ha un viatge que encaixa amb la teva sol·licitud';
    v_html :=
      '<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:520px;margin:0 auto;color:#14151A;line-height:1.5">'
      || '<p style="font-size:16px">Hola ' || v_to_name || ',</p>'
      || '<p style="font-size:16px"><strong>' || coalesce(v_other, 'Un conductor') || '</strong> ha publicat un viatge que encaixa amb la teva sol·licitud:</p>'
      || '<div style="background:#F3F4F8;border-radius:14px;padding:16px;margin:16px 0">'
      || '<div style="font-size:19px;font-weight:800">' || m.origin || ' → ' || m.destination || '</div>'
      || '<div style="margin-top:8px;font-size:15px">' || public.ca_datetime(m.offer_depart_at) || '</div>'
      || '<div style="margin-top:4px;font-size:13px;color:#6B6F7B">Tu demanaves ' || public.ca_datetime(m.request_depart_at) || '</div>'
      || '<div style="margin-top:8px;font-size:14px">' || m.available_seats || ' places'
      || case when m.price_per_seat is not null then ' · ' || to_char(m.price_per_seat, 'FM999990.00') || ' € per plaça' else '' end
      || '</div></div>'
      || '<p><a href="' || v_link || '" style="display:inline-block;background:#5B4CFB;color:#fff;text-decoration:none;font-weight:700;padding:12px 24px;border-radius:14px;font-size:15px">Veure el viatge i contactar</a></p>'
      || '<p style="font-size:13px;color:#6B6F7B;margin-top:24px">Reps aquest correu perquè has publicat una sol·licitud a Pujobaixo amb l''avís activat. Pots desactivar-lo editant la sol·licitud.</p>'
      || '</div>';
  end if;

  select net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object('Authorization', 'Bearer ' || v_api_key, 'Content-Type', 'application/json'),
    body    := jsonb_build_object('from', v_from, 'to', jsonb_build_array(v_email), 'subject', v_subject, 'html', v_html)
  ) into v_req_id;

  insert into public.match_notifications (request_id, offer_id, passenger_id, recipient_role, recipient_id, http_request)
  values (m.request_id, m.offer_id, m.passenger_id, p_role, v_to_id, v_req_id)
  on conflict (request_id, offer_id, recipient_role) do nothing;
end;
$fn$;

-- l'antiga signatura de dos arguments ja no cal
drop function if exists public.send_match_email(uuid, uuid);
revoke all on function public.send_match_email(uuid, uuid, text) from public, anon, authenticated;

-- 4. Trigger blindat: un error d'enviament no pot impedir mai la publicació
create or replace function public.notify_matches_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
declare r record;
begin
  begin
    if new.trip_type = 'offer' then
      for r in select * from public.v_matches where offer_id = new.id loop
        if r.request_notify then perform public.send_match_email(r.request_id, r.offer_id, 'passenger'); end if;
        if new.notify_email  then perform public.send_match_email(r.request_id, r.offer_id, 'driver'); end if;
      end loop;
    elsif new.trip_type = 'request' then
      for r in select * from public.v_matches where request_id = new.id loop
        if new.notify_email then perform public.send_match_email(r.request_id, r.offer_id, 'passenger'); end if;
        if r.offer_notify   then perform public.send_match_email(r.request_id, r.offer_id, 'driver'); end if;
      end loop;
    end if;
  exception when others then
    raise warning 'notify_matches_after_insert: % (trip %)', sqlerrm, new.id;
  end;
  return new;
end;
$fn$;

drop trigger if exists trg_notify_matches on public.trips;
create trigger trg_notify_matches
  after insert on public.trips
  for each row execute function public.notify_matches_after_insert();

revoke all on function public.notify_matches_after_insert() from public, anon, authenticated;

-- ============================================================================
-- Comprovacions:
--   select * from public.v_matches;
--   select request_id, offer_id, recipient_role, sent_at from public.match_notifications order by sent_at desc;
-- ============================================================================
