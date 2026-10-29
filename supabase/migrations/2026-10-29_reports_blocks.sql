-- ============================================================================
-- Pujobaixo · Reportar i bloquejar
-- ----------------------------------------------------------------------------
-- Spec: docs/specs/2026-10-29_reportar-bloquejar.md
-- Requereix 2026-08-31_avisos_v2.sql. Tot és additiu: no toca les polítiques
-- de trips ni de profiles.
--
-- ABANS D'EXECUTAR: crear el secret amb l'adreça d'administració (una vegada,
-- al SQL Editor; l'adreça no va al repo, que és públic):
--   select vault.create_secret('LA-TEVA-ADREÇA@gmail.com', 'admin_email');
--
-- Executar al SQL Editor bloc a bloc (BLOC 1 … BLOC 5), confirmant "Success"
-- abans del següent (vegeu docs/GOTCHAS.md, enganxats llargs tallats).
-- ============================================================================


-- ============================================================================
-- BLOC 1 · Taules i RLS
-- ============================================================================

create table if not exists public.reports (
  id               bigint generated always as identity primary key,
  reporter_id      uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  trip_id          uuid references public.trips(id) on delete set null,
  reason           text not null,
  details          text,
  status           text not null default 'open',
  created_at       timestamptz not null default now(),
  constraint reports_reason_check  check (reason in ('unsafe', 'fake', 'spam', 'other')),
  constraint reports_status_check  check (status in ('open', 'reviewed', 'actioned')),
  constraint reports_details_check check (details is null or char_length(details) <= 1000),
  constraint reports_not_self      check (reporter_id <> reported_user_id)
);

create unique index if not exists reports_reporter_trip_uidx
  on public.reports (reporter_id, trip_id);
create index if not exists reports_reported_user_idx
  on public.reports (reported_user_id);

alter table public.reports enable row level security;

-- Només inserir, i només en nom propi. Cap lectura ni edició per a usuaris:
-- la revisió es fa des del panell de Supabase.
drop policy if exists "reports insert own" on public.reports;
create policy "reports insert own"
  on public.reports for insert
  to authenticated
  with check (reporter_id = auth.uid() and reported_user_id <> auth.uid());

revoke all on public.reports from anon, authenticated;
grant insert on public.reports to authenticated;


create table if not exists public.blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);

create index if not exists blocks_blocked_idx on public.blocks (blocked_id);

alter table public.blocks enable row level security;

drop policy if exists "blocks manage own" on public.blocks;
create policy "blocks manage own"
  on public.blocks for all
  to authenticated
  using (blocker_id = auth.uid())
  with check (blocker_id = auth.uid());

revoke all on public.blocks from anon, authenticated;
grant select, insert, delete on public.blocks to authenticated;


-- ============================================================================
-- BLOC 2 · Validació del report abans d'inserir
-- ----------------------------------------------------------------------------
-- La persona reportada es deriva del viatge (no es confia en el client) i es
-- limita a 5 reports per usuari cada 24 h. Els errors porten un codi llegible
-- perquè _friendlyDbError els tradueixi.
-- ============================================================================

create or replace function public.reports_before_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_driver uuid;
begin
  if new.trip_id is not null then
    select driver_id into v_driver from public.trips where id = new.trip_id;
    if v_driver is null then
      raise exception 'reports_trip_not_found';
    end if;
    new.reported_user_id := v_driver;
  end if;

  if (select count(*) from public.reports
      where reporter_id = new.reporter_id
        and created_at > now() - interval '24 hours') >= 5 then
    raise exception 'reports_rate_limit';
  end if;

  new.details    := nullif(trim(new.details), '');
  new.status     := 'open';
  new.created_at := now();
  return new;
end;
$fn$;

drop trigger if exists trg_reports_before_insert on public.reports;
create trigger trg_reports_before_insert
  before insert on public.reports
  for each row execute function public.reports_before_insert();


-- ============================================================================
-- BLOC 3 · Correu a administració després d'inserir
-- ----------------------------------------------------------------------------
-- Blindat: si el correu falla, el report es desa igualment (docs/GOTCHAS.md).
-- ============================================================================

create or replace function public.html_escape(p text)
returns text
language sql
immutable
as $fn$
  select replace(replace(replace(replace(coalesce(p, ''),
    '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
$fn$;

create or replace function public.reports_notify_admin()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $fn$
declare
  v_api_key  text;
  v_admin    text;
  v_reporter text;
  v_reported text;
  v_prev     int;
  v_reason   text;
  t          record;
  v_trip     text := '<em>Sense viatge associat</em>';
  v_html     text;
begin
  begin
    select decrypted_secret into v_api_key from vault.decrypted_secrets where name = 'resend_api_key' limit 1;
    select decrypted_secret into v_admin   from vault.decrypted_secrets where name = 'admin_email'    limit 1;
    if v_api_key is null or v_admin is null then
      raise warning 'reports_notify_admin: falta resend_api_key o admin_email al Vault';
      return new;
    end if;

    select coalesce(nullif(trim(first_name || ' ' || coalesce(last_name, '')), ''), '(sense nom)')
      into v_reporter from public.profiles where id = new.reporter_id;
    select coalesce(nullif(trim(first_name || ' ' || coalesce(last_name, '')), ''), '(sense nom)')
      into v_reported from public.profiles where id = new.reported_user_id;

    select count(*) - 1 into v_prev from public.reports where reported_user_id = new.reported_user_id;

    v_reason := case new.reason
      when 'unsafe' then 'Comportament inadequat o insegur'
      when 'fake'   then 'Perfil o viatge fals'
      when 'spam'   then 'Spam o publicitat'
      else 'Altres' end;

    if new.trip_id is not null then
      select origin, destination, depart_at, trip_type into t from public.trips where id = new.trip_id;
      if found then
        v_trip := html_escape(t.origin) || ' → ' || html_escape(t.destination) || ' · ' || public.ca_datetime(t.depart_at)
          || ' (' || case when t.trip_type = 'request' then 'sol·licitud' else 'oferta' end || ')'
          || '<br><a href="https://pujobaixo.cat/?trip=' || new.trip_id || '">Obrir el viatge</a>';
      end if;
    end if;

    v_html :=
      '<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:560px;color:#14151A;line-height:1.5">'
      || '<p style="font-size:16px"><strong>Report nou #' || new.id || '</strong> · ' || v_reason || '</p>'
      || '<table style="font-size:14px;border-collapse:collapse">'
      || '<tr><td style="padding:4px 12px 4px 0;color:#6B6F7B">Reportat</td><td>' || html_escape(v_reported)
      || ' <span style="color:#6B6F7B">(' || new.reported_user_id || ')</span></td></tr>'
      || '<tr><td style="padding:4px 12px 4px 0;color:#6B6F7B">Reports previs</td><td>' || v_prev || '</td></tr>'
      || '<tr><td style="padding:4px 12px 4px 0;color:#6B6F7B">Per</td><td>' || html_escape(v_reporter) || '</td></tr>'
      || '<tr><td style="padding:4px 12px 4px 0;color:#6B6F7B;vertical-align:top">Viatge</td><td>' || v_trip || '</td></tr>'
      || '</table>'
      || '<div style="background:#F3F4F8;border-radius:14px;padding:16px;margin:16px 0;white-space:pre-wrap;font-size:14px">'
      || coalesce(html_escape(new.details), '<em>Sense detalls</em>') || '</div>'
      || '<p style="font-size:12px;color:#8F93A1">Revisa-ho a Supabase → Table Editor → reports. Rebut el ' || public.ca_datetime(now()) || '.</p>'
      || '</div>';

    perform net.http_post(
      url     := 'https://api.resend.com/emails',
      headers := jsonb_build_object('Authorization', 'Bearer ' || v_api_key, 'Content-Type', 'application/json'),
      body    := jsonb_build_object(
                   'from',    'Pujobaixo <avisos@pujobaixo.cat>',
                   'to',      jsonb_build_array(v_admin),
                   'subject', '[Report] ' || v_reason || ' · ' || v_reported || case when v_prev > 0 then ' · ' || (v_prev + 1) || ' reports' else '' end,
                   'html',    v_html)
    );
  exception when others then
    raise warning 'reports_notify_admin: %', sqlerrm;
  end;
  return new;
end;
$fn$;

drop trigger if exists trg_reports_notify_admin on public.reports;
create trigger trg_reports_notify_admin
  after insert on public.reports
  for each row execute function public.reports_notify_admin();


-- ============================================================================
-- BLOC 4 · Funcions per al client
-- ----------------------------------------------------------------------------
-- hidden_user_ids(): ids a amagar per a l'usuari actual, en les dues direccions.
--   Qui ha estat bloquejat també els amaga, sense poder llegir la taula blocks.
-- my_blocks(): llista de "Persones bloquejades" a Perfil, amb el nom encara que
--   la persona ja no tingui viatges actius (profiles_select_scoped no ho deixaria).
-- ============================================================================

create or replace function public.hidden_user_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $fn$
  select blocked_id from public.blocks where blocker_id = auth.uid()
  union
  select blocker_id from public.blocks where blocked_id = auth.uid();
$fn$;

create or replace function public.my_blocks()
returns table (blocked_id uuid, first_name text, last_initial text, avatar_url text, created_at timestamptz)
language sql
stable
security definer
set search_path = public
as $fn$
  select b.blocked_id, p.first_name, left(p.last_name, 1), p.avatar_url, b.created_at
  from public.blocks b
  left join public.profiles p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$fn$;

revoke all on function public.hidden_user_ids() from public, anon;
revoke all on function public.my_blocks()       from public, anon;
grant execute on function public.hidden_user_ids() to authenticated;
grant execute on function public.my_blocks()       to authenticated;


-- ============================================================================
-- BLOC 5 · Sense avisos de coincidència entre persones bloquejades
-- ----------------------------------------------------------------------------
-- Mateixa vista que a avisos_v2, amb una condició més al final del join.
-- ============================================================================

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
  -- bloquejos en qualsevol direcció
  and not exists (
    select 1 from public.blocks b
    where (b.blocker_id = r.driver_id and b.blocked_id = o.driver_id)
       or (b.blocker_id = o.driver_id and b.blocked_id = r.driver_id)
  )
where r.trip_type = 'request'
  and r.status = 'active'
  and r.depart_at > now() - interval '1 day'
  and public.trip_sense(r.origin, r.destination) is not null;

revoke all on public.v_matches from anon, authenticated;


-- ============================================================================
-- COMPROVACIÓ (després dels 5 blocs)
-- ============================================================================
--   select tablename, policyname, cmd from pg_policies where tablename in ('reports', 'blocks');
--   select count(*) from public.v_matches;                       -- no ha de petar
--   select decrypted_secret is not null as admin_ok
--     from vault.decrypted_secrets where name = 'admin_email';   -- ha de ser true
