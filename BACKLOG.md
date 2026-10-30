# Backlog — Pujobaixo

Idees sense avaluar encara contra la restricció actual (vegeu `ROADMAP.md`). Res d'aquí està decidit ni descartat — és matèria primera per a la propera revisió de prioritats.

No barrejar amb `ROADMAP.md` (decidit i actiu) ni amb la secció "Aparcat" del roadmap (avaluat i ajornat amb condició de reactivació).

## Producte

- Notificar també al conductor quan apareix una sol·licitud compatible amb la seva oferta *(ja fet — vegeu `docs/AVISOS_SOLICITUDS.md`, avisos v2, ambdós rols)*.
- Senyals de confiança lleugeres a la targeta: "Membre des de setembre 2026", "3 viatges publicats" (baix cost, sense verificació forta). *(Parcialment fet el 29 oct.: el perfil públic mostra viatges oferts i sol·licituds. La data d'alta es va deixar fora a propòsit; afegir-la seria un camp més a `public_profile()`.)*
- Historial de viatges completats per usuari, visible al perfil.
- Recordatori automàtic (correu) el dia abans d'un viatge propi, amb un enllaç ràpid per cancel·lar si cal.
- Preguntar "Vau fer el viatge?" després de la data d'un viatge contactat, per saber quants contactes acaben en viatge real (avui és invisible: la conversa passa a WhatsApp). Base per a valoracions.
- Valoracions post-viatge (ja existeix `rating` a `profiles` segons `_loadTrips`; no s'utilitza enlloc de la UI).
- **"Autostop digital" (idea en el radar, 30 oct. 2026).** Qui condueix prem "Surto ara" i qui espera en aquell sentit rep l'avís al moment i queden en un punt del camí; com aixecar el polze, però des del mòbil. Cobreix el viatge improvisat, que avui l'app no resol.
  → **Condició clau: densitat.** Cal un conductor i un passatger al mateix moment i sentit; amb ~8 actius al mes el radar sortiria buit, i un radar buit diu "aquí no hi ha ningú". No abans de tenir més usuaris actius.
  → **Riscos:** confiança (pujar amb algú en 10 minuts sense conversa prèvia), privacitat (ubicació en directe: aproximada, que caduqui sola i sense historial), límits de la web (sense ubicació en segon pla i push limitat a iPhone; un radar real demana app nativa), i el conductor no pot gestionar sol·licituds mentre condueix.
  → **Per fases:** 1) "Surto ara" sense mapa: un viatge normal amb sortida en menys de 30 minuts, destacat a dalt i amb avís immediat a qui tingui alerta en aquell sentit (reaprofita viatges, avisos i WhatsApp; serveix per mesurar si hi ha demanda real). 2) "Busco ara" per a passatgers ("soc a Gironella i baixo ara"). 3) Radar amb mapa en directe, només si les dades de 1 i 2 ho justifiquen.

## Distribució / creixement

- Repetir publicació a grups de WhatsApp locals addicionals (Berga, Gironella, Puig-reig...).
- Explorar WhatsApp Business API per a avisos, en lloc de correu, si Resend mostra baixa obertura.
- Pàgina o post explicant el "per què" del projecte per compartir a xarxes locals (Instagram Konvent, etc.).

## Procés

- **Adoptar spec-como-guía para funcionalitats noves** que toquin dades, seguretat o creuin sistemes (email, DNS, triggers): mitja pàgina abans de construir amb problema, objectiu, què NO tocar, i criteris d'acceptació — el mateix format que ja vam fer servir de facto per l'arreglada del signup, i que va sortir a la primera sense anades i vingudes. No aplicar-ho a iteració visual/UI (la targeta d'avís necessitava veure's sis vegades per saber què volíem; un spec previ hauria fixat la primera idea, que era la pitjor).
  → Quan: al començar la propera funcionalitat que toqui BD o creui sistemes. Plantilla a `docs/specs/PLANTILLA.md`; primer spec: `docs/specs/2026-10-29_reportar-bloquejar.md`.
  → No crucial ara: no hi ha res trencat per no tenir-ho. Millora de procés, no urgència de producte.

## Tècnic / qualitat

- `after update of depart_at` al trigger d'avisos: avui només es crua en publicar (`insert`), no en editar l'hora d'una oferta existent.
- Reintents per als enviaments de Resend fallits (avui: sense reintent automàtic, cal esborrar la fila de `match_notifications` a mà).
- Consolidar aquest `DECISIONS.md` amb el que ja existeix per al projecte de Konvent/habitacions si mai comparteixen convencions.
- Auditoria completa d'`index.html` contra `DESIGN_SYSTEM.md` amb un model de raonament llarg (Opus), per detectar desviacions acumulades entre iteracions ràpides.

## Disseny

- Adaptar el toggle/segmentat i el calendari a desktop (avui optimitzat mòbil-primer; desktop no auditat).
- ~~Plantilles de correu de Supabase Auth en català i amb l'estil visual del correu d'avisos.~~ Fet el 29 oct. 2026: `supabase/templates/` (cal enganxar-les a Supabase, vegeu el README).
