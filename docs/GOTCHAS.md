# Gotchas — Pujobaixo

Fallos recurrents de la plataforma, del motor de plantilles o de l'entorn que ja s'han descobert un cop. Consultar abans d'implementar res que hi toqui — repetir-los surt car en temps de debug.

Diferència amb `DECISIONS.md`: allà hi ha decisions de producte/disseny ("triem X en lloc de Y, i per què"). Aquí només bugs, comportaments sorprenents i limitacions tècniques de les eines — sense judici de producte, només "compte amb això".

Format: **Símptoma** → **Causa** → **Solució/regla**.

---

## Frontend (`index.html`)

### `<input type="number">` descarta valors amb coma decimal en silenci
**Símptoma:** l'usuari escriu "10,00" al camp de preu; el formulari envia `''` (buit), que es converteix en `0` i viola `trips_price_per_seat_check` a Supabase — amb un error genèric, sense pista de la causa real.
**Causa:** el tipus `number` de HTML rebutja qualsevol caràcter no vàlid per al `Number()` del navegador i buida el camp, sense avisar ni disparar `onChange` amb un valor útil. Amb teclat espanyol/català, la coma és l'operador decimal per defecte.
**Solució:** camps de diner/decimals sempre `type="text" inputmode="decimal"`, mai `type="number"`. Normalitzar coma→punt al codi abans d'enviar (`.replace(',', '.')`), i validar amb `Number.isFinite()` abans de fer servir el valor. Descobert 30 ag. 2026, arreglat al camp de preu; **revisar si `available_seats` o algun altre input numèric té el mateix risc**.

### El motor de plantilles (`dc-runtime`/`support.js`) necessita `hint-placeholder-*` en `sc-if`/`sc-for` dins de llistes
Si un `<sc-if>` o `<sc-for>` viu dins d'un `sc-for` (llista dins de llista), cal l'atribut `hint-placeholder-count` (per `sc-for`) o `hint-placeholder-val` (per `sc-if`) perquè el motor sàpiga renderitzar un esquelet abans de tenir dades reals. Sense això, el primer render pot petar o quedar en blanc silenciosament.
**Regla:** qualsevol `sc-if`/`sc-for` niat dins d'un altre `sc-for` porta sempre el hint corresponent.

### Balanç de `<sc-if>`/`<sc-for>` s'ha de comprovar sempre després d'editar
El motor no llança un error de sintaxi clar si es descompensen les etiquetes obertes/tancades — el símptoma sol ser una part de la UI que desapareix o que no reacciona, sense missatge a consola.
**Regla:** després de qualsevol `str_replace` sobre `index.html`, comprovar:
```bash
echo "sc-if $(grep -o '<sc-if' index.html | wc -l)/$(grep -o '</sc-if>' index.html | wc -l)"
echo "sc-for $(grep -o '<sc-for' index.html | wc -l)/$(grep -o '</sc-for>' index.html | wc -l)"
```
Els dos números de cada parella han de coincidir.

### Els camps de data i hora porten icona nativa (doble icona)
**Símptoma:** al costat de la nostra icona de calendari/rellotge apareix una fletxa o icona del navegador, massa enganxada.
**Causa:** Chrome hi posa `::-webkit-calendar-picker-indicator` i Safari (sobretot iOS) dibuixa el camp amb estil natiu.
**Regla:** a Chrome, l'indicador natiu és invisible i ocupa tot el camp (qualsevol clic obre el selector); a Safari, `appearance:none` + `::-webkit-date-and-time-value { text-align:left }`. Mai afegir una icona pròpia sense comprovar-ho a Safari iOS.

### `toISOString().slice(0, 16)` no és l'hora local
**Símptoma:** en editar un viatge de les 7:30, el formulari mostrava les 6:30 (5:30 a l'estiu); si es desava sense mirar, el viatge s'avançava una o dues hores cada vegada.
**Causa:** `toISOString()` retorna UTC; tallar-lo per omplir un `datetime-local` barreja UTC amb hora local.
**Regla:** per omplir camps de data/hora, formatar amb `getFullYear/getMonth/getDate/getHours/getMinutes` (hora local) o `_todayKey()`. Detectat i arreglat el 29 oct. 2026 (`goToEditTrip` i la data per defecte de `setPostDepartTime`).

### La recuperació de contrasenya no pot dependre del temps que triga `PASSWORD_RECOVERY`
**Símptoma:** en prémer l'enllaç de "recuperar contrasenya", alguns usuaris acabaven a "Compte verificat!" o a la llista de viatges (amb sessió iniciada) en lloc del formulari; al tercer intent funcionava.
**Causa:** confirmar compte i recuperar contrasenya comparteixen `/auth/callback`. L'app esperava 0,6 s fixos que arribés l'esdeveniment `PASSWORD_RECOVERY` de supabase-js; amb connexions lentes arribava tard i s'interpretava com una confirmació de registre.
**Regla:** decidir pel mateix enllaç: el flux *implicit* porta `type=recovery` al hash. Cal llegir-lo **abans** de `createClient`, perquè supabase-js esborra el hash en processar-lo (`this._initialHash`). Esperar la sessió amb reintents (fins a ~6 s), no amb un temps fix. Arreglat el 29 oct. 2026.

### `wa.me` necessita el prefix de país; sense, WhatsApp diu que el número no existeix
**Símptoma:** el botó de WhatsApp obre "No s'ha trobat el número de telèfon" per a un perfil amb `612 34 56 78`.
**Causa:** `wa.me/<número>` interpreta els dígits com a número internacional complet. L'antiga validació només comptava 8–15 dígits.
**Regla:** tot telèfon passa per `_normalizePhone()` (desar i construir l'enllaç). Dades antigues: `supabase/migrations/2026-10-29c_normalize_phones.sql`.

### Un `gap` de flex separa text fix i `{{ variable }}` com si fossin dos elements
**Símptoma:** un botó `display:flex; gap:12px` amb `Reportar {{ ppFirst }}` es veu com "Reportar   Judit", amb un forat al mig, i el nom accessible queda tallat.
**Causa:** el motor genera nodes de text separats per al text fix i per a la interpolació; dins d'un contenidor flex, cada node és un element i el `gap` s'hi aplica.
**Regla:** en contenidors flex amb `gap`, embolicar el text mixt en un `<span>` (`<svg/><span>Reportar {{ nom }}</span>`).

### Les captures del navegador poden arribar abans del repintat
**Símptoma:** després d'un clic, la captura mostra l'estat anterior o una targeta mig transparent.
**Causa:** les animacions d'entrada (`.pj-appear`, `.pj-slide-in`) i el repintat asíncron.
**Regla:** comprovar l'estat amb JS (`getBoundingClientRect`, `aria-pressed`, estat del component) abans de concloure que alguna cosa no funciona; repetir la captura.

---

## Supabase / SQL Editor

### El SQL Editor només mostra el resultat de l'última sentència
**Símptoma:** s'executa un script de diversos passos i només surt la taula de l'última consulta.
**Regla:** quan calgui el resultat d'un pas concret, executar-lo sol o seleccionar només aquelles línies i prémer Run (executa la selecció).

### `pg_net` només guarda les respostes HTTP unes hores
**Símptoma:** `match_notifications.http_request` apunta a un id que ja no existeix a `net._http_response`.
**Causa:** `pg_net` purga les respostes (per defecte, ~6 h). L'historial complet d'enviaments és al panell de Resend → *Emails*.
**Regla:** per comprovar Resend, fer un enviament i mirar la resposta al moment (`supabase/diagnostics/prova_resend.sql`). Un `200` vol dir "acceptat", no "lliurat": si el destinatari és fals, Resend també respon `200`.

### Provar RLS i triggers sense deixar rastre
**Patró:** dins d'un bloc `do`, simular l'usuari amb `set_config('request.jwt.claims', …)` + `set local role authenticated`, fer les comprovacions i acabar amb `raise exception` amb els resultats. Postgres desfà tot (files, crides de `pg_net` encuades, correus) i el missatge d'error és l'informe. Exemple complet: `supabase/diagnostics/prova_reports_blocks.sql`.

### El SQL Editor talla el contingut al enganxar blocs llargs amb `$$...$$`
**Símptoma:** error `unterminated dollar-quoted string at or near "$$"` en executar una migració amb funcions `plpgsql` llargues (500+ línies), encara que el fitxer original estigui bé.
**Causa:** en copiar/enganxar des del navegador (sobretot si el text ve d'un contenidor de xat o un visor amb scroll), el clipboard pot tallar el text abans d'arribar al final — no és un error de sintaxi real, és un enganxat incomplet.
**Solució:** dividir migracions llargues en blocs de ~100-150 línies, executar-los un a un, confirmar "Success" abans de continuar. Fer servir delimitadors únics per funció (`$fn$` en lloc de `$$` repetit) ajuda a detectar quin bloc s'ha tallat perquè l'error assenyala la línia exacta.

### Els missatges d'error de Postgres a la UI no arriben mai al client via Supabase Auth
**Símptoma:** un `insert` que viola una constraint (`profiles_phone_unique`, `trips_price_per_seat_check`, etc.) durant `signUp()` torna un `500` genèric (`Database error saving new user` / `unexpected_failure`) sense el nom de la constraint — Supabase Auth amaga el detall de Postgres per seguretat.
**Solució:** detectar l'error pel format (`status === 500`, `code === 'unexpected_failure'`, o el missatge exacte), mai assumir la causa amb certesa (el mateix 500 pot amagar fallades internes diferents). Mapar els casos coneguts a missatges concrets amb `_friendlyDbError()`; per als desconeguts, missatge genèric + detall tècnic només a `console.error`.

### Triggers que criden serveis externs (`pg_net`) poden avortar l'operació si no es blinden
**Símptoma:** publicar un viatge fallava sencer si l'enviament de correu (Resend) petava per qualsevol motiu (Vault buit, xarxa, servei caigut).
**Causa:** un trigger `after insert` que no captura excepcions propaga qualsevol error del cos cap amunt i fa `ROLLBACK` de tota la transacció — incloent l'`insert` original que no té relació amb l'error.
**Regla:** qualsevol trigger que faci una crida externa (email, webhook, API) ha d'anar embolicat en `begin ... exception when others then raise warning ... end;`. La publicació/acció principal mai pot dependre que un efecte secundari tingui èxit.

---

## Infraestructura

### Un servei antic connectat al repo pot seguir desplegant (i gastant) en silenci
**Símptoma:** correu de Netlify "has reached 75% of your 300 credit allowance" sense que cap projecte local hi estigui enllaçat.
**Causa:** quan la web va passar a GitHub Pages (juliol 2026) es va canviar el DNS però el projecte de Netlify es va quedar connectat a `chewim/pujobaixo`, sense publicar estats als commits. Cada push a `main` era un desplegament de producció (15 crèdits); 16 push en un dia = 240 crèdits.
**Regla:** en migrar d'hosting, esborrar el projecte antic i treure l'accés de l'app al repo (GitHub → Settings → Applications). Per detectar-ho: comparar els desplegaments del panell del servei amb els push (`GET /repos/chewim/pujobaixo/actions/runs`). Esborrat el 29 oct. 2026.

### `404.html` ha de ser una còpia idèntica d'`index.html`
**Símptoma:** qui arriba per una ruta que no és un fitxer (p. ex. `/auth/callback` des del correu de verificació) veu una versió antiga de l'app.
**Causa:** GitHub Pages serveix `404.html` en aquestes rutes (vegeu `COMO_DESPLEGAR.txt`). Si només s'edita `index.html`, `404.html` queda enrere sense que res avisi. Detectat el 29 oct. 2026: ja estava desfasat abans d'aquell dia.
**Regla:** després de cada canvi a `index.html`, `cp index.html 404.html` al mateix commit. Comprovar amb `cmp index.html 404.html` (no ha de dir res).

### Verificar DNS a Resend pot fallar per un domini delegat a un altre proveïdor
**Símptoma:** els registres DNS (DKIM/SPF/MX) es couen a IONOS (el registrador) però Resend els marca "Failed" indefinidament.
**Causa:** el domini tenia els *nameservers* apuntant a un DNS extern (Netlify DNS, en aquest cas) — els registres del panell del registrador no fan res si els nameservers no hi apunten.
**Solució:** abans de tocar cap registre DNS, comprovar a quin proveïdor apunten els *nameservers* del domini (no assumir que és el mateix panell on es va comprar). Un cop identificat el DNS real, els registres s'hi afegeixen allà, i "Verify"/"Restart" a Resend després de la propagació (minuts–hores).

---

## Nota de manteniment

Aquest fitxer és per a bugs i comportaments d'eina, no per a decisions de producte (→ `DECISIONS.md`) ni per a l'estat del roadmap (→ `ROADMAP.md`). Si supera ~150 línies, considerar separar per àrea (`GOTCHAS_FRONTEND.md`, `GOTCHAS_SUPABASE.md`...).
