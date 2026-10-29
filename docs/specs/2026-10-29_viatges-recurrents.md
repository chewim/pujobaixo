# Spec — Viatges recurrents

**Estat:** construït a la branca `feat/viatges-recurrents`, pendent de migració i publicació · 29 oct. 2026

**Provat amb client simulat (29 oct.):** dl+dc des d'un dilluns → 8 viatges amb el mateix `series_id` a les 7:30 (també després del canvi d'hora); sense dies → "Tria almenys un dia"; llista amb una targeta "Cada dl, dc" i comptador correcte; calendari amb els 8 dies; Els meus amb una targeta, sense Editar, i eliminar cancel·la tota la sèrie. Pendent: criteri 4 (correus) contra la BD real.
**Toca:** BD (2 columnes a `trips`, trigger d'avisos), `index.html`.

## Problema

Només 11 persones han ofert mai un viatge i n'hi ha 3 al mes (vegeu `ROADMAP.md`). Qui baixa per feina o estudis fa el trajecte cada setmana, però ha de publicar-lo cada vegada. L'oferta visible depèn que se'n recordi.

## Objectiu

Publicar un trajecte habitual un sol cop ("cada dl, dt i dc a les 7:30") i que quedi visible i encreuable les properes 4 setmanes.

## Comportament

- **Al formulari de publicar** (ofertes i sol·licituds, només en crear, no en editar): interruptor "És un viatge recurrent?". Si s'activa, apareixen els dies `dl dt dc dj dv ds dg` (multiselecció) i la data passa a ser "A partir del".
- **En publicar:** es creen viatges concrets per a cada dia marcat des de la data inicial (inclosa) fins a 4 setmanes (28 dies), tots amb el mateix `series_id`. Cal com a mínim un dia marcat i almenys un viatge futur.
- **Llista de Viatges i perfil públic:** una sola targeta per sèrie, la de la propera sortida, amb "Cada dl, dt, dc" en lloc de la data. El **calendari** mostra cada dia (és on té sentit).
- **Els meus:** una targeta per sèrie amb "Cada dl, dt, dc". *Eliminar* cancel·la tots els viatges actius de la sèrie. *Editar* no es mostra per a sèries (v1: per canviar-la, eliminar-la i tornar-la a publicar).
- **Avisos de coincidència:** un sol correu per persona i per parella de sèries (o sèrie + viatge solt). Sense això, una sèrie de 12 viatges que encaixa amb una altra podria enviar 12 correus de cop.
- **Enllaços d'avisos** (`?trip=<id>` d'un dia concret): obren la targeta agrupada de la sèrie.

## Dades (SQL abans que frontend)

Migració `2026-10-29d_viatges_recurrents.sql`, additiva:

- `trips.series_id uuid` (null = viatge solt) i `trips.series_days smallint[]` (1 = dl … 7 = dg, per a l'etiqueta), amb índex parcial.
- `match_already_notified(request, offer, role)`: cert si la persona ja ha rebut un avís per la mateixa parella de sèries/viatges.
- `notify_matches_after_insert()`: igual que abans, però salta l'enviament si `match_already_notified`.

## Què NO tocar

- `v_matches`, `send_match_email`, RLS de `trips`.
- Edició de sèries, renovació automàtica i avís abans que acabi la sèrie: v2.

## Criteris d'acceptació

1. Amb "recurrent" i dl+dc des d'un dilluns, es creen 8 viatges (4 setmanes) amb el mateix `series_id`.
2. La llista mostra una sola targeta "Cada dl, dc" (la propera); el calendari mostra els 8 dies.
3. Els meus mostra una targeta per sèrie; eliminar-la cancel·la els 8.
4. Una sèrie que encaixa amb una altra sèrie genera com a màxim un correu per persona.
5. Sense marcar cap dia, no es publica i es demana triar-ne un.
6. Validació habitual: balanç `sc-if`/`sc-for`, 390 px, AA, `404.html` sincronitzat.
