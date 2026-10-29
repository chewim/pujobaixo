-- ============================================================================
-- Pujobaixo · Perfil públic mínim
-- ----------------------------------------------------------------------------
-- Spec: docs/specs/2026-10-29_reportar-bloquejar.md (secció Perfil públic)
-- Requereix 2026-10-29_reports_blocks.sql (fa servir public.blocks).
-- Additiu: no toca les polítiques de profiles ni de trips.
--
-- Privacitat per disseny: la funció només retorna els camps que es mostren al
-- perfil públic. Mai cognom complet, telèfon, correu, data d'alta ni rating.
-- Executar sencer al SQL Editor (és curt).
-- ============================================================================

create or replace function public.public_profile(p_id uuid)
returns json
language sql
stable
security definer
set search_path = public
as $fn$
  select json_build_object(
    'id',             p.id,
    'first_name',     p.first_name,
    'last_initial',   left(p.last_name, 1),
    'avatar_url',     p.avatar_url,
    'interests',      p.interests,
    'offers_count',   (select count(*) from public.trips t
                       where t.driver_id = p.id and t.trip_type = 'offer'   and t.status <> 'cancelled'),
    'requests_count', (select count(*) from public.trips t
                       where t.driver_id = p.id and t.trip_type = 'request' and t.status <> 'cancelled')
  )
  from public.profiles p
  where p.id = p_id
    and auth.uid() is not null
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
         or (b.blocker_id = p.id and b.blocked_id = auth.uid())
    );
$fn$;

revoke all on function public.public_profile(uuid) from public, anon;
grant execute on function public.public_profile(uuid) to authenticated;

-- COMPROVACIÓ
--   select public.public_profile('<un id de profiles>');
--   -- Al SQL Editor torna null (no hi ha auth.uid()); és l'esperat.
--   -- La prova real és des de l'app amb sessió iniciada.
