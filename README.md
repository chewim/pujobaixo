# Pujobaixo

Plataforma de compartició de trajectes Berguedà ⇄ Barcelona. Web estàtica (`index.html`, vanilla JS) sobre GitHub Pages, amb Supabase per a dades i auth i Resend per a correu.

**Producció:** [pujobaixo.cat](https://pujobaixo.cat)

## On és cada cosa

| Fitxer | Conté |
|---|---|
| `index.html` | Tota l'app: markup, estils i lògica. Un sol fitxer, sense build step. |
| `support.js` | Motor de plantilles (`sc-if`, `sc-for`) i utilitats. No tocar sense llegir-lo. |
| `CONTEXT.md` | Què és el producte, qui l'usa, els números d'avui, l'stack i el mètode de treball. **Comença aquí.** |
| `ROADMAP.md` | La restricció actual i què l'ataca. Llegir abans de proposar cap funcionalitat nova. |
| `DECISIONS.md` | Què s'ha provat i descartat, amb el motiu. Evita repetir debats tancats. |
| `DESIGN_SYSTEM.md` | Tokens i components: com és el producte avui. |
| `BACKLOG.md` | Idees crues, encara sense avaluar. |
| `docs/GOTCHAS.md` | Bugs i comportaments sorprenents de les eines. Consultar abans d'implementar. |
| `docs/AVISOS_SOLICITUDS.md` | Com funciona i com es desplega el sistema d'avisos automàtics. |
| `supabase/migrations/` | SQL versionat, ordre cronològic pel nom del fitxer. |

## Regla d'or

Abans de construir res: **la pregunta no és "puc fer això?", és "ataca la restricció d'avui?"** (→ `ROADMAP.md`).

## Desplegament

Push a `main` → GitHub Pages publica automàticament. Les migracions SQL s'executen **abans** de pujar el frontend que en depèn, mai a l'inrevés. Detall a `COMO_DESPLEGAR.txt`.
