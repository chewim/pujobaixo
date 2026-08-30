# Avisos automàtics per a sol·licituds

Quan es publica una oferta que encaixa amb una sol·licitud activa, el passatger rep un correu amb el viatge i un enllaç directe. També a l'inrevés: en publicar una sol·licitud, s'avisa de les ofertes que ja existeixen.

## Com funciona

- **Cruce**: mateix *sentit* (`baixa` = destinació conté "Barcelona", `puja` = origen conté "Barcelona"), dia dins del marge (`date_window`: 0 = només aquest dia, 1 = ±1 dia) i hora del dia dins del marge (`time_window`: 60/120/180 min). Es cruza per sentit i no per ruta exacta perquè un cotxe Konvent → Barcelona serveix a algú de Gironella.
- **Enviament**: trigger `trg_notify_matches` (after insert a `trips`) → `send_match_email()` → `pg_net` → API de Resend. La clau és a Vault (`resend_api_key`).
- **Sense repeticions**: `match_notifications` guarda una fila per parella sol·licitud–oferta.
- **Enllaç del correu**: `https://pujobaixo.cat/?trip=<id>`. L'app obre la llista sobre aquest viatge (amb login pel mig si cal) i el ressalta 4 s.
- **Baixa**: el passatger desmarca "Avisa'm per correu" editant la sol·licitud (`notify_email = false`).

## Desplegament (una sola vegada)

1. Resend → API Keys → crea una clau amb permís d'enviament. Comprova que el domini `pujobaixo.cat` està verificat i que el remitent `avisos@pujobaixo.cat` és vàlid (o canvia `v_from` a la migració pel que facis servir).
2. Supabase → Project Settings → Vault → **Add new secret**: nom `resend_api_key`, valor la clau.
3. Supabase → SQL Editor → enganxa `supabase/migrations/2026-08-30_avisos_solicituds.sql` sencer → Run.
4. Puja el nou `index.html`.

## Prova

1. Amb l'usuari A, publica una sol·licitud: Gironella → Barcelona, demà 18:00, ±2 h, avís marcat.
2. Amb l'usuari B, publica una oferta: Konvent → Barcelona, demà 17:15.
3. A ha de rebre el correu en menys d'un minut.

Si no arriba:
```sql
select * from public.v_pending_matches;                     -- hauria de ser buit (ja avisat)
select * from public.match_notifications order by sent_at desc;
select id, status_code, content from net._http_response order by id desc limit 5;  -- resposta de Resend
```
Un `status_code` 403/422 vol dir remitent no verificat o clau incorrecta.

## Límits coneguts

- Només s'avisa en **inserir**. Editar l'hora d'una oferta no torna a cruzar. Si cal, afegir `after update of depart_at`.
- Sense reintents: si Resend falla, la parella queda registrada igualment. Es pot esborrar la fila de `match_notifications` per tornar a enviar.
- El conductor no rep avís quan apareix una sol·licitud que li encaixa (pendent, segona fase).
