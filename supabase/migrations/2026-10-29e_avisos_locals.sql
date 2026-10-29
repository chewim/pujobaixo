-- ============================================================================
-- Pujobaixo · Avisos de coincidència també per a viatges locals
-- ----------------------------------------------------------------------------
-- Fins ara v_matches només creuava viatges amb Barcelona (trip_sense: baixa /
-- puja). Un "Olvan → Berga" no tenia sentit i quedava fora dels avisos.
-- Ara dos viatges també encaixen si van del mateix poble al mateix poble,
-- comparant els noms sense majúscules, accents, guions ni espais.
--
-- Additiu: mateixes columnes de v_matches (send_match_email no canvia).
-- Executar sencer al SQL Editor.
-- ============================================================================

-- Clau per comparar noms de lloc: "Puig-reig", "puigreig" i "Puig reig" → "puigreig".
-- Els accents es treuen abans de lower(): segons la configuració regional de la BD,
-- lower() pot no convertir lletres accentuades en majúscula ("À").
create or replace function public.place_key(p text)
returns text
language sql
immutable
as $fn$
  select nullif(regexp_replace(
           lower(translate(btrim(coalesce(p, '')), 'àáâäèéêëìíîïòóôöùúûüçñÀÁÂÄÈÉÊËÌÍÎÏÒÓÔÖÙÚÛÜÇÑ', 'aaaaeeeeiiiioooouuuucnaaaaeeeeiiiioooouuuucn')),
           '[^a-z0-9]', '', 'g'), '');
$fn$;

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
  and (
        -- amb Barcelona: mateix sentit (un Konvent → Barcelona serveix a qui baixa des de Gironella)
        ( public.trip_sense(r.origin, r.destination) is not null
          and public.trip_sense(o.origin, o.destination) = public.trip_sense(r.origin, r.destination) )
        -- locals (i qualsevol altre): mateix origen i mateixa destinació
        or ( public.place_key(o.origin) = public.place_key(r.origin)
             and public.place_key(o.destination) = public.place_key(r.destination) )
      )
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
  and r.depart_at > now() - interval '1 day';

revoke all on public.v_matches from anon, authenticated;


-- ============================================================================
-- COMPROVACIÓ (no escriu res)
-- ============================================================================
--   select public.place_key('Puig-reig') = public.place_key('puig reig')  as guio_i_espais,
--          public.place_key('Olvan')     = public.place_key('OLVÀN')      as accents,
--          public.place_key('Berga')    <> public.place_key('Bagà')       as pobles_diferents;
--   -- Han de sortir tres true.
--   select count(*) from public.v_matches;   -- no ha de petar
