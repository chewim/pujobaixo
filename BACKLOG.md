# Backlog — Pujobaixo

Idees sense avaluar encara contra la restricció actual (vegeu `ROADMAP.md`). Res d'aquí està decidit ni descartat — és matèria primera per a la propera revisió de prioritats.

No barrejar amb `ROADMAP.md` (decidit i actiu) ni amb la secció "Aparcat" del roadmap (avaluat i ajornat amb condició de reactivació).

## Producte

- Notificar també al conductor quan apareix una sol·licitud compatible amb la seva oferta *(ja fet — vegeu `docs/AVISOS_SOLICITUDS.md`, avisos v2, ambdós rols)*.
- Senyals de confiança lleugeres a la targeta: "Membre des de setembre 2026", "3 viatges publicats" (baix cost, sense verificació forta).
- Historial de viatges completats per usuari, visible al perfil.
- Recordatori automàtic (correu) el dia abans d'un viatge propi, amb un enllaç ràpid per cancel·lar si cal.
- Valoracions post-viatge (ja existeix `rating` a `profiles` segons `_loadTrips`; no s'utilitza enlloc de la UI).

## Distribució / creixement

- Repetir publicació a grups de WhatsApp locals addicionals (Berga, Gironella, Puig-reig...).
- Explorar WhatsApp Business API per a avisos, en lloc de correu, si Resend mostra baixa obertura.
- Pàgina o post explicant el "per què" del projecte per compartir a xarxes locals (Instagram Konvent, etc.).

## Tècnic / qualitat

- `after update of depart_at` al trigger d'avisos: avui només es crua en publicar (`insert`), no en editar l'hora d'una oferta existent.
- Reintents per als enviaments de Resend fallits (avui: sense reintent automàtic, cal esborrar la fila de `match_notifications` a mà).
- Consolidar aquest `DECISIONS.md` amb el que ja existeix per al projecte de Konvent/habitacions si mai comparteixen convencions.
- Auditoria completa d'`index.html` contra `DESIGN_SYSTEM.md` amb un model de raonament llarg (Opus), per detectar desviacions acumulades entre iteracions ràpides.

## Disseny

- Adaptar el toggle/segmentat i el calendari a desktop (avui optimitzat mòbil-primer; desktop no auditat).
- Plantilles de correu de Supabase Auth (verificació, recuperació) en català i amb l'estil visual del correu d'avisos.
