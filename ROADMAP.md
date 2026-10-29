# Roadmap — Pujobaixo

Aquest document no és una llista de funcionalitats. És la restricció actual del producte, i què fem (o no fem) per atacar-la.

> **La pregunta que decideix què entra aquí no és "és una bona idea?", és "ataca la restricció d'avui?".**
> Gairebé tot és una bona idea en abstracte. El que filtra és preguntar què és l'única cosa que avui impedeix que la resta importi.
> La restricció canvia amb el temps — cal refer la pregunta, no respondre-la una vegada i arxivar-la.

---

## Restricció actual

**30 d'agost 2026:** volum d'oferta. Hi ha 1 viatge actiu i 0 clics de WhatsApp registrats sobre viatges actius. Amb aquest volum, cap millora de descobriment, confiança o matching té res sobre què treballar — el problema no és que la gent no trobi el viatge que li convé, és que gairebé no hi ha viatges.

Senyal de canvi de restricció: si en repetir el canal que ja va convertir (grup de WhatsApp) es publiquen prou viatges perquè `v_matches` generi encreuaments reals cada setmana, la restricció passa a ser **confiança** (massa desconeguts per a la mida de la comunitat) o **conversió del contacte** (es contacta però no es tanca el viatge).

---

## Actiu (ataca la restricció d'avui)

- [x] **Sistema d'avisos automàtics** (30–31 ag. 2026) — elimina la necessitat de "estar present" per beneficiar-se d'una coincidència. Publiques i t'oblides; el sistema avisa quan apareix l'altra part. És l'atac directe a "mercat de baixa freqüència on ningú està connectat quan apareix la contrapart".
- [ ] **Repetir el canal de WhatsApp amb missatge dirigit a conductors.** El grup de WhatsApp va convertir 6 registres amb cost zero (24 ag. 2026); l'esdeveniment puntual en va donar 10 amb més esforç. És la següent inversió, i no és producte — és distribució. Sense oferta, el sistema d'avisos multiplica per zero.
- [x] **Jerarquia del CTA a Viatges** (29 oct. 2026) — WhatsApp és l'única superfície sòlida; mesura directa de la restricció (clics de WhatsApp). Comparar clics abans/després quan hi hagi volum.
- [x] **Reportar i bloquejar + perfil públic mínim** (29 oct. 2026) — no ataca el volum d'oferta: és el mínim de seguretat (i canal de notificació que demana la DSA) abans de créixer. Spec: `docs/specs/2026-10-29_reportar-bloquejar.md`.
- [ ] **Viatges recurrents** ("cada dilluns, dimarts i dimecres baixo a les 7:30"). Ataca directament la restricció: només 11 persones han ofert mai un viatge i n'hi ha 3 al mes, però qui fa el trajecte per feina o estudis el fa cada setmana. Publicar-lo un cop com a recurrent multiplica l'oferta visible sense demanar més esforç a qui condueix, i dona als avisos (`v_matches`) alguna cosa amb què creuar.
  Preguntes per a l'spec (toca BD → spec abans de construir, `docs/specs/PLANTILLA.md`):
  - **Model:** una regla (dies de la setmana + hora + data de fi) que genera viatges concrets per a les properes 1–2 setmanes, o una sola fila amb la regla? Generar viatges concrets manté intactes la llista, el calendari, `v_matches` i els avisos.
  - **Cancel·lar un dia** sense cancel·lar la sèrie, i **data de fi** obligatòria o per defecte (p. ex. 4 setmanes, renovable) perquè no quedin viatges fantasma de qui ja no baixa.
  - **Targeta:** mostrar "Cada dl, dt, dc · 7:30" sense omplir la llista de còpies del mateix trajecte.
  - **També per a sol·licituds** ("cada dilluns necessito baixar"): probablement sí, mateix mecanisme.
  → Mesura d'èxit: ofertes actives per setmana i contactes únics `(user_id, trip_id)` abans/després.
- [ ] **SMTP d'Auth amb Resend.** Ja tenim el domini verificat i la clau a Vault; connectar-lo als correus de verificació/recuperació treu el límit de 2/hora del SMTP de prova de Supabase. Cost baix, sense risc, fet quan hi hagi un moment.

## Aparcat (bona idea, no és el moment)

Cada entrada porta la condició numèrica que la reactivaria — no "quan sembli el moment", un llindar concret.

- **Vista calendari** (30 ag. 2026) — construïda i desplegada, oculta per regla d'aparició (`showCalLink`: només es mostra si la pestanya activa té viatges en més d'un dia). Amb 1 viatge actiu, mostrar un calendari és mostrar sis caselles buides abans que cap contingut. Es reactiva sola quan hi hagi prou densitat; no cal cap acció manual.
  → Llindar: ja actiu automàticament (condicional al codi, no a la memòria de ningú).
- **Flexibilitat horària als viatges oferts** (`flex_time`/`flex_time_window` del disseny d'agost) — dissenyat i descartat en favor del sistema d'avisos, que ataca el mateix problema (viatges que no coincideixen exactament) sense requerir que el conductor mogui res.
  → Llindar: si després de 3 setmanes amb avisos actius seguim veient contactes fallits per marge horari petit, revisar.
- **Verificació d'identitat forta** (SMS, DNI) — cara i fricció al registre; avui no hi ha cap incident reportat que ho justifiqui.
  → Llindar: primer incident real reportat (ara arriben per correu via `reports`), o >150 usuaris actius.
- **Avisos per WhatsApp / Web Push** — el correu cobreix el cas d'ús actual (avisos d'1–2 per setmana, sense urgència d'immediatesa). Push té sentit quan calgui "surt en 40 min"; WhatsApp té sentit perquè és on ja viu la comunitat.
  → Llindar: si la taxa d'obertura del correu és baixa (comprovar a Resend → Emails) o apareix demanda de matching "a última hora".
- **Notificació al conductor per interacció, no per correu** (icona de campana amb comptador a la nav) — sense app ni push, un badge dins la webapp només es veu si l'usuari torna a obrir-la, que és exactament el comportament que el correu evita. Té sentit si algun dia hi ha PWA amb push real.

## Backlog (idees sense decidir)

Vegeu `BACKLOG.md`. No barrejar amb aquesta llista — aquí només hi ha coses ja avaluades contra la restricció.

---

## Pròximes restriccions candidates

Quan el volum d'oferta deixi de ser la restricció, cap a on es mourà. **No actuar sobre cap d'aquestes ara** — anticipar-se a una restricció que encara no tens és el mateix error que voler resoldre'n una de futura amb el calendari. Serveixen per saber què mirar, no què construir. La pròxima restricció real serà el primer graó de l'embut que segueixi trencat quan s'alliberi l'actual:

> publicacions → encreuaments (`v_matches`) → correus → contactes (WhatsApp) → viatges fets

Avui es trenca al **primer graó**. Per ordre de probabilitat un cop hi hagi oferta:

1. **Retenció de conductors (la més probable).** No sabem si el problema serà que no arriben conductors o que arriben, publiquen un cop i no tornen — són dues restriccions oposades: la primera es distribució (més grups de WhatsApp), la segona és producte (recordatoris, republicar un trajecte habitual amb un toc).
   → Dada que ho confirma: les dues consultes pendents — viatges publicats per setmana i clics de WhatsApp per setmana. Fins que no es mirin, és endevinar.

2. **Densitat de rutes, no d'usuaris.** Berguedà–Barcelona no és una ruta, són moltes (Berga, Gironella, Puig-reig… a hores diferents). Amb 90 usuaris repartits en desenes de combinacions origen-hora pots tenir "prou usuaris" i gairebé cap encreuament. Si en créixer el volum els avisos segueixen sense disparar-se, la culpable és aquesta, i la resposta no és més gent: és concentrar la comunitat en menys franges (un "tots sortim a les 8:00" fa més match que cent horaris dispersos).
   → Dada que ho confirma: ràtio d'encreuaments a `v_matches` respecte a viatges actius. Molts viatges i pocs encreuaments = problema de densitat, no de volum.

3. **Confiança / conversió del contacte (més endavant).** Quan hi hagi encreuaments i contactes, la pregunta passarà a ser quants d'aquests contactes es converteixen en un viatge real. Si es contacta per WhatsApp i no es tanca, pujar al cotxe d'un desconegut en una comunitat petita necessita més senyal de la que es dóna avui.
   → Dada que ho confirma: clics de WhatsApp alts però pocs viatges marcats com a fets / poca recurrència.

Regla: no triar quina serà — deixar pujar el volum i **llegir on es trenca l'embut**. La resposta és a les dades quan arribin, no aquí.

## Historial de restriccions

| Data | Restricció identificada | Com es va saber |
|---|---|---|
| 30 ag. 2026 | Volum d'oferta (no descobriment) | `v_pending_matches`/`trips` actius: 1 viatge, 0 clics sobre actius |
| 29 oct. 2026 | Segueix sent volum d'oferta | Últims 30 dies (nets): 3 ofertes, 1 sol·licitud, 3 contactes únics per WhatsApp, 0 coincidències a `v_matches`. Només 11 persones han ofert mai un viatge, de 103 comptes. Hi ha demanda que contacta; falta oferta. (Fins al 29 oct., 2 de cada 3 perfils tenien el telèfon sense prefix: part dels clics anteriors podien acabar en error de WhatsApp.) |

Actualitzar aquesta taula cada vegada que es replantegi la pregunta de restricció, encara que la resposta no canviï.
