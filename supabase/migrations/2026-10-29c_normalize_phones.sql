-- ============================================================================
-- Pujobaixo · Normalitzar telèfons existents al format internacional (+34…)
-- ----------------------------------------------------------------------------
-- Context: wa.me necessita el prefix de país. Fins al 29 oct. 2026 el
-- telèfon es desava tal com s'escrivia ("612 34 56 78") i el botó de WhatsApp
-- obria un número inexistent. Des d'ara l'app normalitza en desar; aquest
-- script arregla els que ja hi ha. Mateixes regles que _normalizePhone():
--   +XX…            → es manté (només dígits)
--   00XX…           → +XX…
--   9 xifres 6/7/8/9 → +34…
--   34 + 9 xifres    → +34…
--   la resta        → no es toca (cal que la persona el corregeixi al perfil)
--
-- Executar al SQL Editor en dos passos.
-- ============================================================================

-- PAS 1 · Previsualització (no canvia res): quants es corregiran i quants no es poden
with n as (
  select id, phone, d,
    case
      when btrim(phone) like '+%'      then '+' || d
      when d ~ '^00'                    then '+' || substr(d, 3)
      when d ~ '^[6789][0-9]{8}$'       then '+34' || d
      when d ~ '^34[6789][0-9]{8}$'     then '+' || d
    end as norm
  from (select id, phone, regexp_replace(phone, '\D', '', 'g') as d
        from public.profiles where coalesce(btrim(phone), '') <> '') x
), v as (
  select *, (norm is not null
             and length(norm) between 9 and 16
             and (norm !~ '^\+34' or norm ~ '^\+34[6789][0-9]{8}$')) as ok
  from n
)
select
  count(*) filter (where ok and norm = phone)                       as ja_correctes,
  count(*) filter (where ok and norm <> phone
                   and not exists (select 1 from public.profiles p
                                   where p.phone = v.norm and p.id <> v.id)) as es_corregiran,
  count(*) filter (where ok and norm <> phone
                   and exists (select 1 from public.profiles p
                               where p.phone = v.norm and p.id <> v.id))     as duplicats_no_tocats,
  count(*) filter (where not ok)                                    as invalids_no_tocats
from v;

-- PAS 2 · Aplicar la correcció
with n as (
  select id, phone, d,
    case
      when btrim(phone) like '+%'      then '+' || d
      when d ~ '^00'                    then '+' || substr(d, 3)
      when d ~ '^[6789][0-9]{8}$'       then '+34' || d
      when d ~ '^34[6789][0-9]{8}$'     then '+' || d
    end as norm
  from (select id, phone, regexp_replace(phone, '\D', '', 'g') as d
        from public.profiles where coalesce(btrim(phone), '') <> '') x
)
update public.profiles p
set phone = n.norm
from n
where p.id = n.id
  and n.norm is not null
  and n.norm <> n.phone
  and length(n.norm) between 9 and 16
  and (n.norm !~ '^\+34' or n.norm ~ '^\+34[6789][0-9]{8}$')
  and not exists (select 1 from public.profiles q where q.phone = n.norm and q.id <> n.id);
