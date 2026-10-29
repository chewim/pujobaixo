# Context — Pujobaixo

Orientació ràpida per a qualsevol sessió (Claude o humana) que comenci de zero.

## Què és

Plataforma de compartició de trajectes recurrents Berguedà ⇄ Barcelona. No és un marketplace de mobilitat a l'ús: és per a gent que **ja fa** el trajecte (feina, estudis) i té places buides, connectada amb gent que **ja necessita** fer-lo. Sense comissions, contacte directe per WhatsApp, cap intermediació en el pagament.

Diferència clau amb un BlaBlaCar: freqüència baixa, comunitat molt petita i geogràficament concentrada (una comarca rural + una ciutat), confiança per proximitat més que per ràting.

## Model

Gratuït. 0 € de comissió declarat explícitament a l'avís legal. No hi ha, avui, cap via d'ingressos activa ni planejada a curt termini — l'objectiu actual és demostrar que el mercat bilateral funciona (liquiditat), no monetitzar-lo.

## Usuari

Persones del Berguedà que es desplacen a Barcelona (o a l'inrevés) de manera habitual. Coneixement local alt, ús de WhatsApp com a eina social per defecte, sensibilitat al cost del trajecte (~42 €/anada-tornada en solitari).

## Estat a 30 d'agost de 2026

- **~90 usuaris registrats.** Creixement no orgànic: dos pics puntuals (esdeveniment 27 jul. → 10 registres; grup de WhatsApp 24 ag. → 6 registres), pla la resta del temps.
- **1 viatge actiu, 0 clics de WhatsApp** sobre viatges actius. Vegeu `ROADMAP.md` — aquesta és la restricció que decideix totes les prioritats actuals.
- **Canals que han convertit:** grup de WhatsApp local (millor ràtio esforç/resultat) i un esdeveniment presencial puntual. Cap altre canal provat encara.

### Números a 29 d'octubre de 2026

- **103 comptes, 99 confirmats.** 102 amb telèfon (tots ja en format `+34…`).
- **35 persones han publicat alguna vegada** (ofertes i sol·licituds juntes); **només 11 han ofert mai un viatge com a conductores.**
- **8 amb `last_sign_in_at` en els últims 30 dies.** Compte: aquest camp només canvia en iniciar sessió amb contrasenya; qui torna amb la sessió guardada no hi compta. És un mínim, no l'activitat real. Per a activitat real: viatges publicats i `events` (`whatsapp_click`) per setmana.
- **Últims 30 dies (dades netes, sense cancel·lats):** 3 ofertes, 1 sol·licitud, 3 contactes únics per WhatsApp (persona + viatge). En brut eren 5 viatges i 8 clics: la diferència són cancel·lacions i clics repetits.
- **Com mesurar-ho:** `events` només registra `whatsapp_click`; comptar parelles úniques `(user_id, trip_id)`, no files. No sabem quants contactes acaben en viatge (la conversa és a WhatsApp).

### Canvis del 29 d'octubre de 2026

- **WhatsApp com a únic CTA sòlid a Viatges.** "Publicar" de la capçalera passa a botó tonal i el preu a negre (`DECISIONS.md`).
- **Seguretat: reportar i bloquejar** des d'un **perfil públic mínim** (tocant el nom a la targeta). Spec i estat: `docs/specs/2026-10-29_reportar-bloquejar.md`. Els reports arriben per correu a l'adreça `admin_email` del Vault i es revisen a mà a Supabase → Table Editor → `reports`.
- **Resend comprovat** de punta a punta des de la BD. Des del 30 d'agost no hi ha hagut cap avís de coincidència perquè no hi ha hagut coincidències, no per cap error.
- **Telèfons normalitzats a `+34…`.** 68 de 102 perfils no tenien prefix i el botó de WhatsApp els obria com a número inexistent. Corregits amb `2026-10-29c_normalize_phones.sql` (102/102 correctes després); l'app ara valida i normalitza en desar i abans de publicar.
- **RLS de `profiles` revisada:** sense sessió no es llegeix cap perfil ni telèfon. Amb sessió, qualsevol compte pot llegir les columnes de qui té un viatge actiu (inclòs `phone`, necessari per a WhatsApp); limitació acceptada i documentada a l'spec.

## Stack i infraestructura

| Peça | Servei | Notes |
|---|---|---|
| Frontend | `index.html` (vanilla JS + motor de plantilles propi `dc-runtime`, a `support.js`) | Un sol fitxer, sense build step. `str_replace`-only edits. |
| Hosting | GitHub Pages (`chewim/pujobaixo`) | `CNAME` apunta a `pujobaixo.cat` |
| DNS | IONOS | Migrat des de Netlify DNS el 30 ag. 2026 (Netlify ja no s'usa per a res) |
| Backend | Supabase (Postgres + Auth + Storage) | RLS actiu a totes les taules d'usuari |
| Correu transaccional | Resend | Domini `pujobaixo.cat` verificat (DKIM/SPF/MX/DMARC). Vault: `resend_api_key`, `admin_email` (destí dels reports) |
| Auth SMTP | **Pendent** — encara amb el SMTP de prova de Supabase (límit 2/h) | Connectar a Resend és tasca activa al roadmap |

## Documents del repositori

- `DESIGN_SYSTEM.md` — tokens, components, decisions de disseny amb el "per què" de cada descart.
- `ROADMAP.md` — restricció actual i què l'ataca. Llegir abans de proposar cap funcionalitat nova.
- `DECISIONS.md` — registre curt de proves i descarts tècnics/producte (a crear/consolidar; avui una part viu dins `DESIGN_SYSTEM.md`).
- `BACKLOG.md` — idees sense avaluar encara contra la restricció.
- `docs/AVISOS_SOLICITUDS.md` — funcionament i desplegament del sistema d'avisos automàtics.
- `supabase/migrations/` — SQL versionat, un fitxer per migració, ordre cronològic pel nom.
- `supabase/diagnostics/` — scripts de comprovació que no modifiquen res (prova de Resend, prova automàtica de reportar/bloquejar que es desfà sola).
- `docs/specs/` — specs de funcionalitats que toquen dades, seguretat o creuen sistemes (`PLANTILLA.md` + un fitxer per spec).
- `docs/GOTCHAS.md` — bugs i comportaments sorprenents de les eines.

## Com treballem (mètode, no només eines)

1. **Cap canvi sense la restricció identificada primer.** Vegeu `ROADMAP.md`.
2. Canvis acotats: `str_replace`, mai reescriure el fitxer sencer.
3. Validar sempre abans d'entregar: `node --check` sobre el JS inline, balanç de `<sc-if>`/`<sc-for>`, prova visual amb Puppeteer headless a 390px (mòbil primer).
4. SQL sempre abans que el frontend que en depèn, mai a l'inrevés.
5. Cada decisió de disseny important es documenta amb el "per què", no només el "què" — perquè la propera sessió no la torni a proposar ni la reverteixi sense saber que ja es va provar.
6. Prioritzar: la pregunta no és "és útil?", és "ataca la restricció d'avui?".
