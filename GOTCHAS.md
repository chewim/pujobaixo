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

---

## Supabase / SQL Editor

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

### Verificar DNS a Resend pot fallar per un domini delegat a un altre proveïdor
**Símptoma:** els registres DNS (DKIM/SPF/MX) es couen a IONOS (el registrador) però Resend els marca "Failed" indefinidament.
**Causa:** el domini tenia els *nameservers* apuntant a un DNS extern (Netlify DNS, en aquest cas) — els registres del panell del registrador no fan res si els nameservers no hi apunten.
**Solució:** abans de tocar cap registre DNS, comprovar a quin proveïdor apunten els *nameservers* del domini (no assumir que és el mateix panell on es va comprar). Un cop identificat el DNS real, els registres s'hi afegeixen allà, i "Verify"/"Restart" a Resend després de la propagació (minuts–hores).

---

## Nota de manteniment

Aquest fitxer és per a bugs i comportaments d'eina, no per a decisions de producte (→ `DECISIONS.md`) ni per a l'estat del roadmap (→ `ROADMAP.md`). Si supera ~150 línies, considerar separar per àrea (`GOTCHAS_FRONTEND.md`, `GOTCHAS_SUPABASE.md`...).
