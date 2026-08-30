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

## Stack i infraestructura

| Peça | Servei | Notes |
|---|---|---|
| Frontend | `index.html` (vanilla JS + motor de plantilles propi `dc-runtime`, a `support.js`) | Un sol fitxer, sense build step. `str_replace`-only edits. |
| Hosting | GitHub Pages (`chewim/pujobaixo`) | `CNAME` apunta a `pujobaixo.cat` |
| DNS | IONOS | Migrat des de Netlify DNS el 30 ag. 2026 (Netlify ja no s'usa per a res) |
| Backend | Supabase (Postgres + Auth + Storage) | RLS actiu a totes les taules d'usuari |
| Correu transaccional | Resend | Domini `pujobaixo.cat` verificat (DKIM/SPF/MX/DMARC). Vault: `resend_api_key` |
| Auth SMTP | **Pendent** — encara amb el SMTP de prova de Supabase (límit 2/h) | Connectar a Resend és tasca activa al roadmap |

## Documents del repositori

- `DESIGN_SYSTEM.md` — tokens, components, decisions de disseny amb el "per què" de cada descart.
- `ROADMAP.md` — restricció actual i què l'ataca. Llegir abans de proposar cap funcionalitat nova.
- `DECISIONS.md` — registre curt de proves i descarts tècnics/producte (a crear/consolidar; avui una part viu dins `DESIGN_SYSTEM.md`).
- `BACKLOG.md` — idees sense avaluar encara contra la restricció.
- `docs/AVISOS_SOLICITUDS.md` — funcionament i desplegament del sistema d'avisos automàtics.
- `supabase/migrations/` — SQL versionat, un fitxer per migració, ordre cronològic pel nom.

## Com treballem (mètode, no només eines)

1. **Cap canvi sense la restricció identificada primer.** Vegeu `ROADMAP.md`.
2. Canvis acotats: `str_replace`, mai reescriure el fitxer sencer.
3. Validar sempre abans d'entregar: `node --check` sobre el JS inline, balanç de `<sc-if>`/`<sc-for>`, prova visual amb Puppeteer headless a 390px (mòbil primer).
4. SQL sempre abans que el frontend que en depèn, mai a l'inrevés.
5. Cada decisió de disseny important es documenta amb el "per què", no només el "què" — perquè la propera sessió no la torni a proposar ni la reverteixi sense saber que ja es va provar.
6. Prioritzar: la pregunta no és "és útil?", és "ataca la restricció d'avui?".
