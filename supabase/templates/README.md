# Plantilles de correu d'Auth (Supabase)

Còpia versionada de les plantilles que hi ha a Supabase → **Authentication → Emails → Templates**. Supabase no les llegeix d'aquí: si en canvies una, canvia-la als dos llocs.

Requereixen l'SMTP propi (Resend) configurat; amb l'SMTP de Supabase no es poden editar en el pla gratuït.

| Plantilla a Supabase | Fitxer | Assumpte | S'usa avui? |
|---|---|---|---|
| Confirm signup | `confirm_signup.html` | `Confirma el teu compte de Pujobaixo` | Sí, en registrar-se |
| Reset password | `reset_password.html` | `Canvia la contrasenya de Pujobaixo` | Sí, "Has oblidat la contrasenya?" |
| Magic link | `magic_link.html` | `El teu enllaç per entrar a Pujobaixo` | No (preparada) |
| Change email address | `change_email.html` | `Confirma el nou correu de Pujobaixo` | No (preparada) |
| Invite user | `invite_user.html` | `T'han convidat a Pujobaixo` | No (preparada) |
| Reauthentication | `reauthentication.html` | `El teu codi de verificació de Pujobaixo` | No (preparada) |

## Com aplicar-les

1. A Supabase, obre cada plantilla de la taula.
2. **Subject:** copia l'assumpte de la taula.
3. **Body (Source):** enganxa el fitxer sencer.
4. Desa i passa a la següent.

## Variables que fan servir

- `{{ .ConfirmationURL }}` — enllaç d'acció (obligatori a totes menys Reauthentication).
- `{{ .Data.first_name }}` — nom que la persona va escriure en registrar-se; si no n'hi ha, posa només "Hola,".
- `{{ .Email }}` / `{{ .NewEmail }}` — només a Change email.
- `{{ .Token }}` — codi de 6 xifres, només a Reauthentication.

## Estil

El mateix que els avisos de coincidència (`send_match_email`): fons `#F3F4F8`, targeta blanca radi 24, botó `#5B4CFB` radi 14, text secundari `#6B6F7B`. Totes porten a la capçalera el logo provisional de la web (`assets/email-logo.png`, icona de la ruta en PNG 96×96 transparent mostrada a 24 px, perquè Gmail i Outlook no mostren SVG) i "Pujobaixo" en text; si les imatges estan bloquejades, el nom es llegeix igual. A més, només `confirm_signup.html` porta imatge de peu: `assets/email-viatge.jpg` (retall 800×320 de `hero-viatge.jpg`, 50 KB), servida des de `pujobaixo.cat`, sota el botó i amb `alt`; el correu s'entén sense ella. Els correus de seguretat (contrasenya, codis) van sense imatges a propòsit. Enllaç en text sota el botó i un peu que explica per què es rep el correu.
