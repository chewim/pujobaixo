# Avisos automàtics (sol·licituds i ofertes)

Quan es publica una oferta que encaixa amb una sol·licitud activa, el **passatger** rep un correu amb el viatge i un enllaç directe, i el **conductor** rep un correu amb la sol·licitud. El mateix en publicar una sol·licitud contra ofertes existents. Cada rol pot desactivar el seu avís des del formulari (targeta "T'avisem quan…").

Migracions, en ordre: `2026-08-30_avisos_solicituds.sql` (base) i `2026-08-31_avisos_v2.sql` (ambdós rols, trigger blindat, comptadors).

## Com funciona

- **Cruce**: mateix *sentit* (`baixa` = destinació conté "Barcelona", `puja` = origen conté "Barcelona"), dia dins del marge (`date_window`: 0 = només aquest dia, 1 = ±1 dia) i hora del dia dins del marge (`time_window`: 60/120/180 min). Es pren el marge **més ampli** dels dos viatges. Es cruza per sentit i no per ruta exacta perquè un cotxe Konvent → Barcelona serveix a algú de Gironella. Vista: `v_matches`.
- **Enviament**: trigger `trg_notify_matches` (after insert a `trips`) → `send_match_email(request, offer, rol)` → `pg_net` → API de Resend. La clau és a Vault (`resend_api_key`). El trigger captura qualsevol error d'enviament (`exception when others`): **publicar mai depèn del correu**.
- **Sense repeticions**: `match_notifications` guarda una fila per parella i rol (`recipient_role`: passenger/driver).
- **Comptador a "Els meus"**: cada targeta pròpia mostra "Avís actiu · ±2 h · només aquest dia · N avisos enviats" (línia informativa, no interactiva). El propietari pot llegir les files de `match_notifications` dels seus viatges (política RLS `owner reads own trip notifications`).
- **Enllaç del correu**: `https://pujobaixo.cat/?trip=<id>`. L'app obre la llista sobre aquest viatge (amb login pel mig si cal) i el ressalta 4 s.
- **Baixa**: el passatger desmarca "Avisa'm per correu" editant la sol·licitud (`notify_email = false`).

## Desplegament (una sola vegada)

1. Resend → API Keys → crea una clau amb permís d'enviament. Comprova que el domini `pujobaixo.cat` està verificat i que el remitent `avisos@pujobaixo.cat` és vàlid (o canvia `v_from` a la migració pel que facis servir).
2. Supabase → Project Settings → Vault → **Add new secret**: nom `resend_api_key`, valor la clau.
3. Supabase → SQL Editor → enganxa `supabase/migrations/2026-08-30_avisos_solicituds.sql` sencer → Run. Després `2026-08-31_avisos_v2.sql`.
4. Puja el nou `index.html`.

## Prova

1. Amb l'usuari A, publica una sol·licitud: Gironella → Barcelona, demà 18:00, ±2 h, avís marcat.
2. Amb l'usuari B, publica una oferta: Konvent → Barcelona, demà 17:15.
3. A ha de rebre el correu "Hi ha un viatge que encaixa…" i B el correu "Algú busca un viatge que encaixa…", en menys d'un minut.

Si no arriba:
```sql
select * from public.v_matches;
select request_id, offer_id, recipient_role, sent_at from public.match_notifications order by sent_at desc;
select id, status_code, content from net._http_response order by id desc limit 5;  -- resposta de Resend
```
Un `status_code` 403/422 vol dir remitent no verificat o clau incorrecta.

## Límits coneguts

- Només s'avisa en **inserir**. Editar l'hora d'una oferta no torna a cruzar. Si cal, afegir `after update of depart_at`.
- Sense reintents: si Resend falla, la parella queda registrada igualment. Es pot esborrar la fila de `match_notifications` per tornar a enviar.
- Si el trigger falla, queda un `WARNING` als logs de Postgres (`notify_matches_after_insert: …`) i el viatge es publica igualment.
