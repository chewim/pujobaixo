-- ============================================================================
-- Pujobaixo · Viatges recurrents
-- ----------------------------------------------------------------------------
-- Spec: docs/specs/2026-10-29_viatges-recurrents.md
-- Additiu: dues columnes noves i el trigger d'avisos amb un control de
-- duplicats per sèries. Executar al SQL Editor en dos blocs.
-- ============================================================================


-- ============================================================================
-- BLOC 1 · Columnes de sèrie
-- ============================================================================

alter table public.trips
  add column if not exists series_id   uuid,
  add column if not exists series_days smallint[];

alter table public.trips drop constraint if exists trips_series_days_check;
alter table public.trips add constraint trips_series_days_check
  check (series_days is null or series_days <@ array[1,2,3,4,5,6,7]::smallint[]);

create index if not exists trips_series_idx on public.trips (series_id) where series_id is not null;


-- ============================================================================
-- BLOC 2 · Un sol avís per persona i parella de sèries
-- ----------------------------------------------------------------------------
-- Una sèrie publica ~12 viatges d'un cop; sense aquest control, si encaixa
-- amb una altra sèrie, la mateixa persona rebria un correu per cada dia.
-- Els viatges solts es comporten igual que abans (la parella exacta ja la
-- deduplica send_match_email).
-- ============================================================================

create or replace function public.match_already_notified(p_request_id uuid, p_offer_id uuid, p_role text)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  with cur as (
    select r.series_id as rs, o.series_id as os
    from public.trips r, public.trips o
    where r.id = p_request_id and o.id = p_offer_id
  )
  select exists (
    select 1
    from public.match_notifications mn
    join public.trips r2 on r2.id = mn.request_id
    join public.trips o2 on o2.id = mn.offer_id
    cross join cur
    where mn.recipient_role = p_role
      and (mn.request_id = p_request_id or (cur.rs is not null and r2.series_id = cur.rs))
      and (mn.offer_id   = p_offer_id   or (cur.os is not null and o2.series_id = cur.os))
  );
$fn$;

revoke all on function public.match_already_notified(uuid, uuid, text) from public, anon, authenticated;

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
        if r.request_notify and not public.match_already_notified(r.request_id, r.offer_id, 'passenger') then
          perform public.send_match_email(r.request_id, r.offer_id, 'passenger');
        end if;
        if new.notify_email and not public.match_already_notified(r.request_id, r.offer_id, 'driver') then
          perform public.send_match_email(r.request_id, r.offer_id, 'driver');
        end if;
      end loop;
    elsif new.trip_type = 'request' then
      for r in select * from public.v_matches where request_id = new.id loop
        if new.notify_email and not public.match_already_notified(r.request_id, r.offer_id, 'passenger') then
          perform public.send_match_email(r.request_id, r.offer_id, 'passenger');
        end if;
        if r.offer_notify and not public.match_already_notified(r.request_id, r.offer_id, 'driver') then
          perform public.send_match_email(r.request_id, r.offer_id, 'driver');
        end if;
      end loop;
    end if;
  exception when others then
    raise warning 'notify_matches_after_insert: % (trip %)', sqlerrm, new.id;
  end;
  return new;
end;
$fn$;
-- El trigger trg_notify_matches ja apunta a aquesta funció; no cal recrear-lo.
