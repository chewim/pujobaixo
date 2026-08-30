# Decisions — Pujobaixo

Registre curt de coses provades i descartades, amb el motiu. Objectiu: que ningú (Claude o humà) torni a proposar-les sense saber que ja es van avaluar. Els detalls visuals/tokens viuen a `DESIGN_SYSTEM.md`; aquí només la decisió i el perquè.

Format: **Data — Decisió.** Descartat: alternativa(es) i motiu.

---

## Producte / abast

- **30 ag. — Vista calendari a Viatges: setmana per defecte, expandible a mes, amb enllaç condicional.**
  Descartat: calendari sempre visible amb toggle permanent → massa pes visual amb poca oferta i decisió duplicada (pestanyes + vista alhora). Calendari com a vista per defecte → amb 1 viatge actiu mostra el buit abans que el contingut; la llista és sempre l'estat inicial i després de publicar. Toggle de dos icones → substituït per enllaç de text condicionat a `showCalLink` (només amb viatges en >1 dia).

- **30 ag. — Sistema d'avisos automàtics (matching sol·licitud↔oferta) en lloc de flexibilitat horària manual.**
  Context: el pla d'agost (previ a aquesta sessió) preveia checkboxes de flexibilitat al formulari + matching manual abans d'automatitzar. Es va descartar en refer l'anàlisi: amb el producte actual (sense cercador, sol·licituds ja explícites a `trips`), l'automatització completa amb `pg_net` + trigger + Resend és tan barata com la versió manual i ataca directament la restricció (mercat de baixa freqüència, ningú "present" quan apareix la contrapart). Vegeu `docs/AVISOS_SOLICITUDS.md`.

- **30 ag. — Camps de marge horari/dia dins d'un anex de revelat progressiu, no camps sempre visibles.**
  Descartat: dos selectors sempre visibles al formulari → afegien soroll a tothom encara que el 100% accepti el valor per defecte. Preguntar abans o després de publicar en pantalla apart → pas extra que costa publicacions i duplica camps en edició.

## Còpia (copy)

- **30 ag. — El resum de l'avís explica la conseqüència ("Compatible vol dir fins a ±2 h..."), no el paràmetre ("±2 h · només aquest dia").**
  Motiu: un usuari que rep un avís a 2h de la seva hora no ho ha de percebre com un error de match. Regla general: els ajustos d'un avís s'expliquen per allò que faran arribar a l'usuari, mai com a paràmetres solts.

- **30 ag. — Etiquetes del formulari de sol·licitud no repeteixen la paraula del títol de la vista** ("Ofereixo"/"Necessito", no "Ofereixo viatge"/"Necessito viatge" a les pestanyes de Viatges, ja titulades "Propers viatges").

## Components visuals

- **30 ag. — Segmentat unificat (`.pj-seg`) sense ombra de color, substitueix els tabs amb tint+ombra morada.**
  Descartat: ombra de color a l'element actiu (patró antic) → xocava amb el toggle de vista, que no la duia; es va retirar de tot el sistema per coherència.

- **30 ag. — Tarjeta d'avís: versió final blanca + campana + copy, sense degradat, sense pill "Nou", sense il·lustració.**
  Iteració completa (ordre cronològic del mateix dia): (1) blanca amb icona → (2) blanca amb pill "Nou" i degradat subtil → (3) degradat ple estil "hero" (Revolut) → descartat: mateix pes que el botó Publicar contigu, el CTA ha de guanyar sempre → (4) degradat lavanda intermedi → descartat: contrast text/fons ~3:1, per sota d'AA → (5) blanca amb il·lustració SVG (ruta + campana) → (6) **versió final**: blanca, sense degradat ni il·lustració, campana simple, copy que defineix "compatible" amb xifres. Regla resultant: cap component ha de competir en pes visual amb el CTA principal de la pantalla.

- **31 ag. — Sidebar desktop: estat actiu tonal (`#EEEBFF` + `#5B4CFB`), no morat sòlid.**
  Descartat: morat sòlid ple (patró previ, heretat abans d'aquesta sessió) → mateix pes que Publicar. Regla: la superfície sòlida de marca queda reservada a l'acció primària; la navegació indica lloc amb contenidor tonal (patró Material). Ja consistent amb la bottom nav mòbil, que sempre havia estat tonal.

- **30 ag. — Botó "+ Publicar": "+" com a SVG amb `gap` real, no com a caràcter de text.**
  Motiu: espaiat en múltiples de 8pt real (`gap:8px`), no depenent del kerning de la font.

## Tècnic

- **30 ag. — Camp de preu: `type="text" inputmode="decimal"`, no `type="number"`.**
  Motiu (bug real trobat en producció): `type="number"` descarta silenciosament valors amb coma decimal ("10,00" → camp buit), que es convertia en `0` i violava `trips_price_per_seat_check`, amb un error genèric al formulari. Ara s'accepta coma o punt i es normalitza abans d'enviar.

- **30 ag. — Trigger d'avisos blindat amb `exception when others`.**
  Motiu: en la primera versió, un error en l'enviament de correu (Resend caigut, Vault buit) avortava tot l'`insert` a `trips` — publicar mai pot dependre que arribi un correu.

- **30 ag. — DNS centralitzat a IONOS, Netlify DNS retirat.**
  Netlify només feia de DNS (la web ja es servia des de GitHub Pages); mantenir-lo era un servei de més sense cap funció. Migrat sense downtime perceptible.

## Infraestructura descartada

- **Verificació de telèfon en temps real al registre (consulta pública de duplicats).**
  Descartat de forma permanent, no aparcat: permetria esbrinar quins números estan registrats. Vegeu gestió de l'error `profiles_phone_unique` a `index.html` (`_isOpaqueSignupError`).
