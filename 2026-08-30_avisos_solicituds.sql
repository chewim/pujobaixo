-- ============================================================================
-- Pujobaixo · Avisos automàtics per a sol·licituds
-- ----------------------------------------------------------------------------
-- Quan es publica una OFERTA, s'avisa per correu els passatgers amb una
-- SOL·LICITUD activa que encaixi (mateix sentit, dia i hora dins del marge).
-- Quan es publica una SOL·LICITUD, s'avisa el passatger de les ofertes que
-- ja existeixen i encaixen.
--
-- Un sol correu per parella sol·licitud–oferta (taula match_notifications).
-- L'enviament el fa Postgres via pg_net contra l'API de Resend. La clau
-- viu a Supabase Vault amb el nom 'resend_api_key'.
--
-- Tot és additiu: no toca columnes, triggers ni polítiques existents.
-- Executar sencer al SQL Editor de Supabase.
-- ============================================================================

-- 0. Extensió per fer crides HTTP des de Postgres (ve amb Supabase)
create extension if not exists pg_net with schema extensions;

-- 1. Columnes noves a trips (només tenen sentit per a trip_type = 'request')
alter table public.trips
  add column if not exists time_window  integer not null default 120,
  add column if not exists date_window  integer not null default 0,
  add column if not exists notify_email boolean not null default true;

alter table public.trips drop constraint if exists trips_time_window_check;
alter table public.trips add constraint trips_time_window_check check (time_window in (60, 120, 180));
alter table public.trips drop constraint if exists trips_date_window_check;
alter table public.trips add constraint trips_date_window_check check (date_window in (0, 1));

-- 2. Registre d'avisos enviats (una fila per parella; evita repetir)
create table if not exists public.match_notifications (
  id           bigint generated always as identity primary key,
  request_id   uuid not null references public.trips(id) on delete cascade,
  offer_id     uuid not null references public.trips(id) on delete cascade,
  passenger_id uuid not null,
  sent_at      timestamptz not null default now(),
  http_request bigint,
  unique (request_id, offer_id)
);
alter table public.match_notifications enable row level security;
-- Sense polítiques: només hi escriu el trigger (security definer). Ningú la llegeix des del client.

-- 3. Sentit del trajecte: 'baixa' (cap a Barcelona) o 'puja' (des de Barcelona)
create or replace function public.trip_sense(p_origin text, p_destination text)
returns text language sql immutable as $$
  select case
    when p_destination ilike '%barcelona%' then 'baixa'
    when p_origin      ilike '%barcelona%' then 'puja'
    else null
  end;
$$;

-- 4. Vista de cruces pendents d'avisar. Es pot consultar a mà per auditar.
create or replace view public.v_pending_matches
with (security_invoker = false) as
select
  r.id          as request_id,
  o.id          as offer_id,
  r.driver_id   as passenger_id,
  o.driver_id   as driver_id,
  r.depart_at   as request_depart_at,
  o.depart_at   as offer_depart_at,
  o.origin, o.destination, o.available_seats, o.price_per_seat
from public.trips r
join public.trips o
  on  o.trip_type = 'offer'
  and o.status = 'active'
  and o.available_seats > 0
  and o.depart_at > now()
  and o.driver_id <> r.driver_id
  and public.trip_sense(o.origin, o.destination) = public.trip_sense(r.origin, r.destination)
  -- dia dins del marge (0 = mateix dia, 1 = dia abans o després), en hora local
  and abs( (o.depart_at at time zone 'Europe/Madrid')::date
         - (r.depart_at at time zone 'Europe/Madrid')::date ) <= r.date_window
  -- hora del dia dins del marge, en minuts
  and abs( extract(epoch from (o.depart_at at time zone 'Europe/Madrid')::time)
         - extract(epoch from (r.depart_at at time zone 'Europe/Madrid')::time) ) / 60 <= r.time_window
where r.trip_type = 'request'
  and r.status = 'active'
  and r.notify_email
  and r.depart_at > now() - interval '1 day'
  and public.trip_sense(r.origin, r.destination) is not null
  and not exists (
    select 1 from public.match_notifications m
    where m.request_id = r.id and m.offer_id = o.id
  );

-- 5. Format de dates en català (sense dependre de lc_time)
create or replace function public.ca_datetime(p_ts timestamptz)
returns text language sql immutable as $$
  with t as (select p_ts at time zone 'Europe/Madrid' as l)
  select (array['diumenge','dilluns','dimarts','dimecres','dijous','divendres','dissabte'])[extract(dow from l)::int + 1]
      || ' ' || extract(day from l)::int
      || ' ' || (array['de gener','de febrer','de març','d''abril','de maig','de juny','de juliol','d''agost','de setembre','d''octubre','de novembre','de desembre'])[extract(month from l)::int]
      || ' a les ' || to_char(l, 'HH24:MI')
  from t;
$$;

-- 6. Enviament d'un avís concret (crida a Resend i registre)
create or replace function public.send_match_email(p_request_id uuid, p_offer_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_api_key   text;
  v_from      text := 'Pujobaixo <avisos@pujobaixo.cat>';  -- ha de ser un remitent verificat a Resend
  v_email     text;
  v_pass_name text;
  v_drv_name  text;
  m           record;
  v_link      text;
  v_html      text;
  v_req_id    bigint;
begin
  select decrypted_secret into v_api_key
  from vault.decrypted_secrets where name = 'resend_api_key' limit 1;
  if v_api_key is null then
    raise warning 'send_match_email: no resend_api_key at Vault';
    return;
  end if;

  select * into m from public.v_pending_matches
  where request_id = p_request_id and offer_id = p_offer_id;
  if not found then return; end if;

  select u.email, coalesce(nullif(trim(p.first_name), ''), 'hola')
    into v_email, v_pass_name
  from auth.users u left join public.profiles p on p.id = u.id
  where u.id = m.passenger_id;
  if v_email is null then return; end if;

  select coalesce(nullif(trim(p.first_name || ' ' || coalesce(left(p.last_name, 1) || '.', '')), ''), 'Un conductor')
    into v_drv_name
  from public.profiles p where p.id = m.driver_id;

  v_link := 'https://pujobaixo.cat/?trip=' || m.offer_id;

  v_html :=
    '<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:520px;margin:0 auto;color:#14151A;line-height:1.5">'
    || '<p style="font-size:16px">Hola ' || v_pass_name || ',</p>'
    || '<p style="font-size:16px"><strong>' || coalesce(v_drv_name, 'Un conductor') || '</strong> ha publicat un viatge que encaixa amb la teva sol·licitud:</p>'
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

  select net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object('Authorization', 'Bearer ' || v_api_key, 'Content-Type', 'application/json'),
    body    := jsonb_build_object(
      'from',    v_from,
      'to',      jsonb_build_array(v_email),
      'subject', 'Hi ha un viatge que encaixa amb la teva sol·licitud',
      'html',    v_html
    )
  ) into v_req_id;

  insert into public.match_notifications (request_id, offer_id, passenger_id, http_request)
  values (m.request_id, m.offer_id, m.passenger_id, v_req_id)
  on conflict (request_id, offer_id) do nothing;
end;
$$;

-- 7. Trigger: després d'inserir un viatge, avisa els cruces nous
create or replace function public.notify_matches_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare r record;
begin
  if new.trip_type = 'offer' then
    for r in select request_id, offer_id from public.v_pending_matches where offer_id = new.id loop
      perform public.send_match_email(r.request_id, r.offer_id);
    end loop;
  elsif new.trip_type = 'request' and new.notify_email then
    for r in select request_id, offer_id from public.v_pending_matches where request_id = new.id loop
      perform public.send_match_email(r.request_id, r.offer_id);
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_matches on public.trips;
create trigger trg_notify_matches
  after insert on public.trips
  for each row execute function public.notify_matches_after_insert();

-- Cap usuari ha de poder cridar aquestes funcions des del client
revoke all on function public.send_match_email(uuid, uuid) from public, anon, authenticated;
revoke all on function public.notify_matches_after_insert() from public, anon, authenticated;
revoke all on public.v_pending_matches from anon, authenticated;

-- ============================================================================
-- Comprovacions ràpides (executar a part):
--   select * from public.v_pending_matches;                      -- cruces pendents
--   select * from public.match_notifications order by sent_at desc;
--   select id, status_code, content from net._http_response order by id desc limit 5;  -- resposta de Resend
-- ============================================================================
