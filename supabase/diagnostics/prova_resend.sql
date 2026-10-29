-- ============================================================================
-- Pujobaixo · Diagnòstic: comprova que Resend envia des de la BD
-- ----------------------------------------------------------------------------
-- No és una migració: no crea ni modifica res, ni comptes ni viatges.
-- Fa servir el mateix camí que send_match_email (Vault → pg_net → Resend,
-- remitent avisos@pujobaixo.cat) i envia un sol correu de prova.
-- Executar al SQL Editor de Supabase en tres passos, un per bloc.
-- ============================================================================

-- PAS 1 · Hi ha clau al Vault? Ha de tornar 1 (no mostra la clau).
select count(*) as claus_resend
from vault.decrypted_secrets where name = 'resend_api_key';

-- PAS 2 · Envia el correu de prova. Canvia l'adreça abans d'executar.
-- Torna un número (id de la petició): apunta'l.
select net.http_post(
  url     := 'https://api.resend.com/emails',
  headers := jsonb_build_object(
               'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'resend_api_key' limit 1),
               'Content-Type', 'application/json'),
  body    := jsonb_build_object(
               'from',    'Pujobaixo <avisos@pujobaixo.cat>',
               'to',      jsonb_build_array('CANVIA-AIXO@exemple.com'),
               'subject', '[Prova] Resend des de Supabase',
               'html',    '<p>Si llegeixes això, el camí Vault → pg_net → Resend funciona.</p>')
) as peticio_id;

-- PAS 3 · Espera 5-10 segons i mira la resposta de Resend.
-- 200 = acceptat · 401/403 = clau incorrecta · 422 = remitent/domini no verificat
-- Si no surt cap fila, torna-ho a provar en uns segons.
select id, status_code, left(content::text, 300) as resposta, created
from net._http_response
order by id desc limit 3;

-- EXTRA · Historial d'avisos reals ja enviats (quants i quan).
select recipient_role, count(*) as enviats, max(sent_at) as ultim
from public.match_notifications
group by recipient_role;
