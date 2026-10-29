# Spec — Reportar i bloquejar

**Estat:** fet i desplegat · 29 oct. 2026 (vegeu "Estat de l'acceptació" al final)
**Toca:** BD (2 taules noves, 1 funció, 1 vista existent), correu (Resend), `index.html`.

## Problema

Avui, si algú té un problema amb una altra persona usuària (comportament inadequat, perfil fals, spam), no té cap via dins de Pujobaixo per dir-ho ni per deixar de veure-la. L'única sortida és buscar el contacte a l'avís legal. Això té dos costos:

- **Confiança:** contactar per WhatsApp amb algú desconegut és el pas que mesura la restricció actual (0 clics). Saber que hi ha una sortida si alguna cosa va malament abaixa la barrera per fer-ho.
- **Responsabilitat:** com a servei que allotja contingut de tercers, cal un canal clar per notificar contingut o conducta problemàtica (DSA, mecanisme de notificació). Pendent de confirmar l'abast exacte per a una microempresa; aquest spec cobreix el mínim raonable igualment.

## Objectiu

1. Qualsevol persona amb sessió pot **reportar** un viatge o la persona que l'ha publicat, en menys de 30 segons, i l'administrador ho rep per correu.
2. Qualsevol persona amb sessió pot **bloquejar** una altra: deixen de veure's els viatges mútuament i no es generen avisos de coincidència entre elles.

## Comportament

### Perfil públic (punt d'entrada)

*Canvi respecte a l'esborrany (29 oct.):* la targeta no té espai per a un menú més, i reportar actua sobre una persona, no sobre un viatge. Per això s'hi arriba des d'un perfil públic molt senzill, que a més és la base de les senyals de confiança del `BACKLOG.md`.

- **Com s'hi arriba:** tocant el nom o la foto d'una targeta aliena. El propi nom porta a la pestanya Perfil. La pista visual que el nom és tocable s'itera sobre la pantalla.
- **Què mostra (i res més):** nom + inicial del cognom, foto (si n'hi ha), preferències de viatge (si n'hi ha), nombre de viatges oferts i de sol·licituds publicades, i els seus viatges actius.
- **Què no mostra mai:** cognom complet, telèfon, correu, data d'alta, valoració (`rating` no té sistema al darrere).
- **Privacitat per disseny:** les dades arriben d'una funció `public_profile(id)` que només retorna aquests camps. El client no rep res més, així que no depèn que el frontend "no ho pinti". Només amb sessió iniciada, i no retorna res si hi ha un bloqueig entre totes dues persones.
- **Política de privacitat:** afegir al punt 3 (Finalitat) "mostrar un perfil bàsic (nom, inicial del cognom, foto, preferències i nombre de viatges publicats) a altres persones usuàries amb sessió iniciada", i actualitzar la data.

### Reportar

- **On:** al perfil públic de la persona (vegeu més avall), al final de la pantalla i amb poc pes visual. S'hi arriba tocant el nom o la foto de qualsevol targeta que no és pròpia (ofertes i sol·licituds), només amb sessió iniciada.
- **Formulari inline dins el perfil** (no hi ha modals al sistema, vegeu `DESIGN_SYSTEM.md`):
  - Motiu (obligatori, un de): *Comportament inadequat o insegur* · *Perfil o viatge fals* · *Spam o publicitat* · *Altres*.
  - Detalls (opcional, màx. 1000 caràcters).
  - Línia fixa: **"Si estàs en perill, truca al 112."** — el report no és un canal d'emergència i no ho ha de semblar.
  - Botons: *Enviar report* (primari) · *Cancel·lar* (outline).
- **Després d'enviar:** missatge inline "Gràcies. Ho revisarem al més aviat possible i, si cal, prendrem mesures. La persona reportada no sabrà qui ha fet el report." + opció directa *Bloquejar també [Nom]*.
- La persona reportada **no rep cap notificació**.
- Duplicats: un mateix usuari només pot reportar un mateix viatge una vegada (si ho torna a intentar, es mostra el missatge de "ja l'has reportat").
- Abús: màxim 5 reports per usuari cada 24 h (missatge pla si se supera).

### Bloquejar

- **On:** al perfil públic, al costat de reportar, i després d'enviar un report.
- **Confirmació inline:** "Deixareu de veure els viatges de l'altra persona i no rebreu avisos entre vosaltres. No li direm que l'has bloquejat." → *Bloquejar* (perill) · *Cancel·lar*.
- **Efecte:** bidireccional — ni qui bloqueja veu els viatges de l'altre, ni a l'inrevés. Sense avisos de coincidència entre tots dos, en cap dels dos rols.
- **Desbloquejar:** llista "Persones bloquejades" a Perfil, amb *Desbloquejar* a cada fila.
- Nota visible un sol cop després de bloquejar: "Si ja teniu conversa a WhatsApp, bloqueja-la també allà." — Pujobaixo no controla WhatsApp.

### Administració

- Cada report nou envia un correu (assumpte "[Report] ...") a l'adreça d'administració (`admin_email` al Vault) amb: motiu, detalls, viatge (ruta + data + enllaç), nom de qui reporta i de qui és reportat, i comptador de reports previs contra la mateixa persona.
- La revisió i les accions (cancel·lar viatges, suspendre el compte) es fan **a mà des del panell de Supabase**. No hi ha panell d'administració a la UI.

## Prerequisit: comprovar que Resend funciona

El correu a administració fa servir el mateix camí que els avisos de coincidència (`net.http_post` → Resend, clau al Vault). Si avui aquest camí falla en silenci, els reports es desarien però ningú se n'assabentaria. Abans de construir:

1. **Respostes recents de Resend** (SQL Editor). `pg_net` només guarda les respostes unes hores (per defecte 6 h), així que això només val just després d'un enviament:
   ```sql
   select mn.sent_at, mn.recipient_role, r.status_code, left(r.content::text, 200) as resposta
   from public.match_notifications mn
   left join net._http_response r on r.id = mn.http_request
   order by mn.sent_at desc limit 10;
   ```
   `200` = acceptat per Resend. `403`/`422` = remitent no verificat o clau incorrecta. `null` = resposta ja purgada (o la crida no va sortir).
2. **Historial complet:** panell de Resend → *Emails*. Cada avís hi ha de sortir com a *Delivered*. Si n'hi ha *Bounced* o cap enviament des de fa setmanes amb viatges publicats, investigar.
3. **Prova en viu:** amb dos comptes de prova, publicar una sol·licitud i una oferta compatibles (mateix sentit, mateix dia, ±2 h) amb l'avís activat, i comprovar que tots dos correus arriben (també a la carpeta de correu brossa) i que la consulta 1 dona `200`.
4. **Fora d'abast però relacionat:** el correu d'Auth (verificació, recuperar contrasenya) encara surt pel SMTP de prova de Supabase (límit 2/h, vegeu `CONTEXT.md`). És un altre camí; si la prova 3 passa, no vol dir que Auth funcioni bé.

Criteri: no començar la migració fins que la prova 3 passi.

**Resultat (29 oct.):** amb `supabase/diagnostics/prova_resend.sql` (sense comptes ni viatges de prova): clau al Vault, Resend respon `200` i el correu arriba a l'instant a la safata d'entrada de Gmail. El camí Vault → pg_net → Resend funciona. L'historial mostra 3 avisos, tots del 30 d'agost: no n'hi ha hagut més perquè no hi ha hagut coincidències, no per una fallada d'enviament. El trigger d'avisos no s'ha provat en viu; el de reports es provarà com a part dels criteris d'acceptació 2 i 3. Prerequisit complert.

## Dades (SQL abans que frontend)

Migració `supabase/migrations/2026-xx-xx_reports_blocks.sql`, additiva:

- `reports` — `id`, `reporter_id`, `reported_user_id`, `trip_id` (nullable), `reason` (check dels 4 valors), `details` (≤1000), `status` (`open`/`reviewed`/`actioned`, per defecte `open`), `created_at`. Únic `(reporter_id, trip_id)`.
  - RLS: `insert` només si `reporter_id = auth.uid()` i `reported_user_id <> auth.uid()`. Cap `select`/`update`/`delete` per a usuaris.
  - Trigger `before insert`: límit de 5 per `reporter_id` en 24 h.
  - Trigger `after insert`: correu a administració via Resend, **embolicat en `exception when others`** (vegeu `docs/GOTCHAS.md`): el report es desa encara que el correu falli.
- `blocks` — `blocker_id`, `blocked_id`, `created_at`; PK `(blocker_id, blocked_id)`; check `blocker_id <> blocked_id`.
  - RLS: cadascú llegeix, crea i esborra només les files on és `blocker_id`.
- Funció `hidden_user_ids()` (`security definer`) — retorna els ids bloquejats en qualsevol direcció per a `auth.uid()`. Així qui ha estat bloquejat també els amaga, sense poder llegir la taula `blocks`.
- `v_matches` — afegir condició `not exists` sobre `blocks` en les dues direccions.

## Què NO tocar

- **Polítiques RLS de `trips` i `profiles`.** El filtre de bloquejos es fa al client amb `hidden_user_ids()`. Limitació assumida: el bloqueig és de UX, no una barrera de seguretat — l'API encara retorna els viatges. Si mai cal que ho sigui, és un altre spec.
- El flux de publicar, editar i eliminar viatges.
- Els avisos existents, més enllà del filtre a `v_matches`.
- Res de valoracions, verificació d'identitat ni panell d'administració.

## Criteris d'acceptació

1. Sense sessió no es veu cap opció de reportar ni bloquejar. A les targetes pròpies tampoc.
2. Un report vàlid crea una fila a `reports` amb `status = 'open'` i arriba un correu a administració en menys d'1 minut.
3. Si Resend falla (p. ex. Vault buit), el report es desa igualment i l'usuari veu el missatge d'èxit.
4. Reportar dues vegades el mateix viatge mostra "ja l'has reportat", sense error tècnic (`_friendlyDbError`).
5. El 6è report en 24 h es rebutja amb missatge pla.
6. Després que A bloquegi B: A no veu viatges de B; B no veu viatges d'A (comprovat amb dos comptes); no es genera cap fila nova a `match_notifications` entre ells.
7. A pot desbloquejar B des de Perfil i els viatges tornen a aparèixer sense recarregar la sessió.
8. Validació habitual: balanç `sc-if`/`sc-for`, prova a 390 px, contrast AA de tots els textos nous.
9. L'avís legal menciona el canal de report.
10. Tocar el nom d'una targeta aliena obre el perfil públic; el propi porta a Perfil. La resposta de `public_profile` (pestanya Network) no conté cap camp fora de la llista.
11. La política de privacitat inclou el perfil públic i té la data actualitzada.

## Estat de l'acceptació (29 oct. 2026)

Desplegat a producció: migracions `2026-10-29_reports_blocks.sql` i `2026-10-29b_public_profile.sql` aplicades, secret `admin_email` al Vault, frontend a `main` (`6f55c88`).

| Criteri | Estat | Com s'ha comprovat |
|---|---|---|
| 1 | ✅ | Frontend amb client simulat: sense sessió o en targeta pròpia el nom no és tocable |
| 2 | ⏳ | Pendent: un report real des de producció i comprovar que arriba el correu "[Report] …". El camí Resend sí que està provat (`supabase/diagnostics/prova_resend.sql`) |
| 3 | ✅ | El trigger de correu està dins `begin … exception`; prova automàtica: el report es desa |
| 4–7 | ✅ | `supabase/diagnostics/prova_reports_blocks.sql`: 12/12 OK (duplicat, límit de 5, bloqueig en les dues direccions, desbloquejar) |
| 8 | ✅ | Balanç `sc-if` 119/119, `sc-for` 11/11; 390 px; contrast AA (s'ha corregit un gris a 3.06:1) |
| 9, 11 | ✅ | Avís legal i política de privacitat actualitzats (29 oct.) |
| 10 | ✅ | `public_profile` només retorna els 7 camps permesos (prova automàtica, punt 2) |

Canvis respecte a l'esborrany: el punt d'entrada és el perfil públic i no la targeta; les accions són enllaços de text al peu (vegeu `DESIGN_SYSTEM.md`, "Acciones de pie de pantalla").

## Preguntes obertes (decidir abans de construir)

1. ~~Adreça d'administració~~ **Decidit (29 oct.):** el correu personal del responsable, guardat al Vault com a `admin_email` (mai hardcodejat a l'SQL ni al repo). Canviar-la quan el producte creixi és actualitzar un secret, sense migració. Afegir un filtre a Gmail per l'assumpte "[Report]" perquè no acabin a correu brossa ni barrejats.
2. ~~Qui revisa i en quant de temps?~~ **Decidit (29 oct.):** el responsable del projecte, al més aviat possible des que rep el correu. Sense termini concret a la UI ("al més aviat possible"); si el volum creix fins a no poder-ho sostenir, revisar aquest punt al `ROADMAP.md`.
3. ~~Exposició del telèfon~~ **Comprovat (29 oct.):** `profiles` no té cap política de `select` per a `anon`, així que sense sessió no es llegeix cap telèfon. Amb sessió (`profiles_select_scoped`) es llegeix el perfil propi, el de qui té viatges actius i el de les reserves compartides: és el que necessita el botó de WhatsApp. Limitació assumida: qualsevol compte registrat pot llegir via API totes les columnes (inclòs `phone`) de qui té un viatge actiu, i un bloqueig no ho impedeix. Si cal tancar-ho, és un altre spec (vista o RPC que només retorni el telèfon a qui contacta).
4. ~~Reportar també una sol·licitud?~~ **Decidit (29 oct.):** sí, ofertes i sol·licituds (`trip_type = 'request'`) amb el mateix flux.
