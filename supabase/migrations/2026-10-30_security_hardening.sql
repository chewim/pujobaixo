-- ============================================================================
-- Pujobaixo · Enduriment de seguretat (avisos del Security Advisor, 30/10/2026)
-- ----------------------------------------------------------------------------
-- 1. Funcions SECURITY DEFINER d'una versió antiga que l'app ja no crida
--    (mark_trip_full, reopen_trip, update_trip_seats_manual,
--    mark_verification_screen_shown, calculate_commission). Saltaven RLS i
--    qualsevol usuari amb sessió les podia cridar per /rest/v1/rpc: es treu
--    el permís. No s'esborren; només les pot executar el panell (postgres).
-- 2. Funcions de trigger dels reports: es treu EXECUTE a anon/authenticated.
--    Els triggers continuen funcionant (el permís es comprova en crear-los).
-- 3. search_path fix a les funcions auxiliars.
-- 4. events: la inserció anònima queda limitada a l'únic esdeveniment que
--    registra l'app (whatsapp_click) en lloc de "with check (true)".
-- 5. Bucket avatars: fora la lectura general de storage.objects (permetia
--    llistar tots els fitxers i, per les carpetes, tots els ids d'usuari).
--    Les fotos es continuen veient per URL pública; cada usuari pot llegir
--    només la seva carpeta (la pujada amb upsert ho necessita).
--
-- No toca hidden_user_ids, my_blocks ni public_profile: l'app les crida,
-- només retornen dades de l'usuari actual o camps públics, i ja estan
-- tancades a anon.
-- Executar sencer al SQL Editor.
-- ============================================================================

-- 1. Funcions antigues sense ús
revoke execute on function public.mark_trip_full(uuid)                      from public, anon, authenticated;
revoke execute on function public.mark_trip_full()                          from public, anon, authenticated;  -- també existia sense arguments
revoke execute on function public.reopen_trip(uuid, integer)                from public, anon, authenticated;
revoke execute on function public.update_trip_seats_manual(uuid, integer, text) from public, anon, authenticated;
revoke execute on function public.mark_verification_screen_shown(uuid)      from public, anon, authenticated;
revoke execute on function public.calculate_commission(numeric, text)       from public, anon, authenticated;

-- 2. Funcions de trigger
revoke execute on function public.reports_before_insert() from public, anon, authenticated;
revoke execute on function public.reports_notify_admin()  from public, anon, authenticated;

-- 3. search_path fix (cap no fa servir extensions)
alter function public.html_escape set search_path = public, pg_catalog;
alter function public.place_key   set search_path = public, pg_catalog;
alter function public.trip_sense  set search_path = public, pg_catalog;
alter function public.ca_datetime set search_path = public, pg_catalog;

-- 4. events
drop policy if exists "anyone can insert events" on public.events;
create policy "anyone can insert whatsapp clicks" on public.events
  for insert to anon, authenticated
  with check (event_type = 'whatsapp_click');

-- 5. avatars
drop policy if exists "Anyone can view avatars" on storage.objects;
drop policy if exists "avatars read own folder" on storage.objects;
create policy "avatars read own folder" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- Comprovació: les funcions antigues ja no són executables per authenticated (ha de sortir 0 files)
select p.proname
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('mark_trip_full','reopen_trip','update_trip_seats_manual',
                    'mark_verification_screen_shown','calculate_commission',
                    'reports_before_insert','reports_notify_admin')
  and has_function_privilege('authenticated', p.oid, 'execute');
