# Pujobaixo — Guía de sistema de diseño

Extraída directamente del código (`index.html`). No es un sistema inventado desde cero: documenta lo que el producto ya hace, para poder repetirlo con criterio en pantallas nuevas.

**Qué va aquí:** el estado actual de tokens y componentes — cómo es algo hoy.
**Qué NO va aquí:** por qué se descartó una alternativa (→ `DECISIONS.md`), bugs de plataforma (→ `docs/GOTCHAS.md`), qué construir después (→ `ROADMAP.md`).

---

## 1. Fundamentos visuales

### Paleta principal

| Color | Hex | Uso |
|---|---|---|
| Morado marca | `#5B4CFB` | Acción primaria: botones, links, iconos activos, estado seleccionado |
| Negro texto | `#14151A` | Texto principal, títulos, precios en negrita (color base del body) |
| Gris texto secundario | `#6B6F7B` | Labels de formulario, subtítulos, texto secundario |
| Gris icono/meta | `#727681` | Iconos inactivos, metadatos (plazas, fecha/hora en cards) |
| Borde por defecto | `#ECEDF2` | Bordes de inputs, cards, separadores |
| Fondo de la app | `#F3F4F8` | Fondo general de página (fuera de las cards) |
| Blanco superficie | `#fff` / `#FFFFFF` | Fondo de cards, inputs, navs |

### Paleta secundaria (estado / semántica)

| Color | Hex | Uso |
|---|---|---|
| Morado tenue | `#EEEBFF` | Fondo de pill/badge activo (ligero tinte de marca) |
| Rojo error | `#C22A24` | Texto de error, botón "Eliminar" |
| Fondo error | `#FDEBEA` | Fondo de banner/botón de error |
| Borde error | `#FBD8D6` | Borde del botón "Eliminar" |
| Verde éxito | `#1D874A` | Texto de éxito (los precios de las cards van en `#14151A`: el verde queda reservado al CTA de WhatsApp) |
| Fondo éxito | `#EAF7EF` | Fondo de banner de éxito |
| Verde WhatsApp | `#25D366` (hover `#20BD5A`, active `#1DA851`, focus outline `#128C7E`) — texto/icono en `#14151A`, no blanco | CTA de contacto por WhatsApp |
| Gris placeholder | `#8F93A1` | Placeholder de inputs |

### Fondos, bordes, sombras y estados

- **Fondo de página**: siempre `#F3F4F8`, nunca blanco puro fuera de una card.
- **Cards**: fondo `#fff` con esquinas muy redondeadas (ver radios abajo) — es el único contenedor "elevado" del sistema.
- **Bordes**: 1.5px solid `#ECEDF2` en inputs y botones secundarios. No hay bordes de otro grosor.
- **Sombras** (solo 3 recetas en todo el producto):
  - Card/hero: `0 20px 60px -30px rgba(20,21,26,0.25)` — difuminada, oscura, sin color de marca.
  - Toast: `0 12px 30px -10px rgba(20,21,26,0.4)` — más contraste, para que flote sobre el contenido.
- **Estado "activo/seleccionado"** (segmentados, nav): fondo `#EEEBFF` + texto `#5B4CFB` + peso 700. Sin sombra: las sombras se reservan a cards.

### Jerarquía visual general

De más a menos peso visual, en cualquier pantalla:
1. **Dato principal** (ruta origen→destino, título de pantalla) — texto grande, negro, extra-bold.
2. **Dato secundario relevante** (precio, nombre) — un escalón por debajo en tamaño/peso, color de marca o negro.
3. **Metadatos** (fecha, hora, plazas, notas) — gris (`#6B6F7B`/`#727681`), nunca negro ni bold.
4. **Labels de formulario** — gris, 15px, 700, siempre encima del campo (nunca al lado ni como placeholder-only).

---

## 2. Tipografía

- **Fuente única**: `'Plus Jakarta Sans', sans-serif` para absolutamente todo (cargada desde Google Fonts). No hay una segunda familia ni monoespaciada.
- **Pesos usados**: solo tres — `600` (semibold, texto secundario/tabs inactivos), `700` (bold, botones y labels), `800` (extra-bold, títulos, precios, nombres, CTAs principales). Nunca 400/500/900.
- **`letter-spacing:-0.02em`** solo en títulos grandes (24px+) — le da el aire "tight" a los headings.

### Escala tipográfica observada

| Tamaño | Peso | Uso |
|---|---|---|
| 26px / 800 | Título hero (pantalla de login) |
| 24px / 800 | Título de pantalla (h1: "Propers viatges", "El meu perfil"...) |
| 22px / 800 | Título de confirmación ("Compte verificat!") |
| 19px / 800 | Ruta origen→destino en las cards (el dato más importante de una card) |
| 17px / 800 | Precio en las cards |
| 15px / 700 | Labels de formulario (Ruta, Tipus de publicació...) |
| 15px / 600–700 | Texto de input, nombre de conductor |
| 14–14.5px / 600–700 | Botones secundarios, tabs |
| 13–13.5px / 600–700 | Metadatos, texto secundario |
| 11–12.5px / 600 | Labels de icono en nav (bottom nav), contadores pequeños |

**Jerarquía título/subtítulo/body/caption/label/botón**, en la práctica del código:
- **Título (h1)**: 24px/800, `margin:0 0 24px`.
- **Subtítulo**: no existe un h2 tipográfico separado — se resuelve con el mismo tamaño que el label (15px/700) o con el color mudado a `#6B6F7B`.
- **Body**: 15px/600, es el tamaño de los inputs y del texto de conductor/nombre.
- **Caption**: 12.5–13.5px, color `#6B6F7B` u `#727681`.
- **Label**: 15px/700, color `#6B6F7B`, `display:block; margin-bottom:8px` — patrón fijo, siempre igual.
- **Botón**: 14–15px/700–800, nunca 600.

---

## 3. Espaciado y layout

**Regla del 8**: todo el espaciado (padding, margin, gap) sigue una escala de múltiplos de 8, con 4 como único medio-paso para los huecos más pequeños (icono+texto, por ejemplo). Nunca introduzcas un valor que no esté en esta escala:

`4, 8, 16, 24, 32, 40, 48, 56, 64...`

(No existen 6, 10, 12, 14, 18, 20, 22, 28, 36, etc. — si necesitas "más que 8 pero menos que 16", la respuesta es 8 o 16, nunca un valor intermedio.)

**Gaps habituales**: `4, 8, 16px` (8 es el más común, úsalo por defecto).

**Paddings habituales**:
- Card grande (hero/auth): `40px 32px`
- Card de contenido: `32px` (desktop) / `16px` (móvil, ver más abajo)
- Card de item de lista (trip card): `16px`
- Botón pill grande: `0` con `height:50px`
- Banner de error/info: `8px 16px`
- Input: `0 16px` con `height:48px`

**Margin entre elementos de una lista**: `margin-bottom:16px` (constante en toda card repetida — trips, bookings, etc.)

**Espacio dentro de un apartado vs. entre apartados distintos** (formularios largos, ej. Publicar): dentro de un mismo apartado (label→input, campos de una misma fila) se mantiene 8-16px; entre el final de un apartado y el inicio del siguiente se usa la clase `.pj-post-section` (`margin-bottom:16px` en móvil, `32px` en desktop ≥900px) — así los bloques del formulario se perciben como secciones distintas en vez de un único bloque continuo, sobre todo en pantallas anchas donde 16px se queda corto.

### Grid / estructura responsive

- **Un único breakpoint**: `@media (min-width: 900px)`. No hay tablet intermedio — por debajo de 900px todo es "móvil" (con bottom nav), por encima es "desktop" (con sidebar).
- **Contenedor principal** (`.pj-main`): `max-width:920px; margin:0 auto`, con padding responsive:
  - Móvil (por defecto): `24px 16px 104px` — **16px es el margen lateral estándar en móvil**, más un padding-bottom de 104px para dejar sitio a la bottom nav fija.
  - Desktop (≥900px): `32px 24px 104px`.
- **Sidebar** (`.pj-sidebar`, 248px de ancho fijo — ya es múltiplo de 8, no cambia): oculta por defecto, `display:flex` solo ≥900px. Cuando está visible, `.pj-main-shifted` añade `margin-left:248px` al contenido.
- **Bottom nav** (`.pj-bottomnav`): visible por defecto, `display:none` ≥900px.

### Diferencias mobile / desktop

| | Móvil (<900px) | Desktop (≥900px) |
|---|---|---|
| Navegación | Bottom nav fija (iconos + label) | Sidebar fija izquierda (248px) |
| Barra superior | Visible (con logo), fondo blanco excepto en auth | Oculta (`.pj-topnav-hide-desktop`) cuando hay sidebar |
| Padding lateral página | 16px | 24px |
| Card de "Publicar"/formularios | Sin fondo propio, se apoya solo en el padding de página (16px) | Fondo blanco + `padding:32px` + `border-radius:24px` |

---

## 4. Componentes

### Botones

| Variante | Fondo | Texto | Borde | Radio | Altura | Uso |
|---|---|---|---|---|---|---|
| Primario | `#5B4CFB` | `#fff` / 800 | ninguno | `14px` | `50px` | Acción principal de un formulario (Iniciar sessió, Publicar, Desar...) |
| Primario compacto | `#5B4CFB` | `#fff` / 700 | ninguno | `14px` | `min-height:44px` (`padding:0 24px`) | CTAs de estado vacío (Publicar en «Els meus») |
| Tonal (`.pj-btn-tonal`) | `#EEEBFF` (hover `#E2DDFF`, active `#D7D0FF`) | `#5B4CFB` / 700 (hover `#4A3DE8`, active `#4338D6`) | ninguno | `14px` | `min-height:44px` | Acción disponible pero no protagonista: «Publicar» en la cabecera de Viatges, donde el CTA es WhatsApp |
| Secundario/outline | `#fff` | `#14151A` / 700 | `1.5px solid #ECEDF2` | `14px` | `44px` | Acción neutra ("Editar", "Cancel·lar") |
| Peligro | `#FDEBEA` | `#C22A24` / 700 | `1.5px solid #FBD8D6` | `14px` | `44px` | Acción destructiva ("Eliminar", "Sí, eliminar") |
| Texto/link | transparente | `#5B4CFB` / 700 | ninguno | — | auto | Enlace de acción secundaria ("Registra't", "Has oblidat la contrasenya?") |
| WhatsApp CTA | `#25D366` | `#14151A` / 700 | ninguno | `14px` | `44px` | Único botón con estados hover/active/focus explícitos; texto negro (no blanco) sobre el verde original |
| Tab/segmento | tinte morado si activo / transparente si no | `#5B4CFB` si activo / `#727681` si no | ninguno | `14px` | `44px` | Selectores tipo "Ofereixo/Necessito" |
| Nav (bottom nav) | tinte morado si activo / transparente si no | `#5B4CFB` si activo / `#727681` si no | ninguno | `14px` | `44px` | Viatges / Els meus / Perfil |
| Icono circular | `#fff` | `#14151A` | ninguno | `14px` | `40px` | Cerrar (X) en Publicar |

**Todos los botones usan el mismo radio (`14px`), sin excepción** — es la regla de consistencia más importante de este sistema: ningún botón es "píldora" (999px), independientemente de su tamaño o importancia. Solo elementos no interactivos (badges, toast) pueden usar `999px`.

Todos los botones: `min-height:44px` (objetivo táctil accesible), `cursor:pointer`, `font-family:inherit`.

### Cards

- **Card de contenido en lista** (trip, booking): `background:#fff; border-radius:24px; padding:16px; margin-bottom:16px`.
- **Card hero/auth**: `border-radius:28px; padding:40px 32px`, con la sombra grande.
- **Card de formulario**: `border-radius:24px; padding:32px` (desktop) / sin fondo propio en móvil.
- **Card de estado vacío**: `border-radius:24px; padding:40px 24px; text-align:center`, texto gris, opcionalmente con un botón CTA debajo.

### Inputs

Receta única para todos los inputs de texto/número/fecha/hora/email/password:
```
height:48px; border-radius:14px; border:1.5px solid #ECEDF2;
padding:0 16px; font-size:15px; font-family:inherit;
```
Sin excepciones — **si un input nuevo no sigue exactamente esto, rompe la consistencia** (ver el bug de fecha/hora que corregimos, que tenía iconos y padding distintos).

### Botón primario con icono (`.pj-btn-primary`)

Para acciones principales dentro de la app (Publicar y sus variantes en estados vacíos). `inline-flex`, `gap:8px`, `min-height:44px`, `padding:0 24px 0 16px` (8px menos a la izquierda para compensar el peso visual del icono), radio 14, fondo `#5B4CFB`, texto blanco 14px/700; hover `#4A3DE8`, active `#4338D6` + `scale(0.98)`, focus `#B9B0FF`. El icono es un SVG de 18px trazado con `currentColor` y `aria-hidden`, nunca un carácter de texto ("+ Publicar" queda retirado): así el espacio icono-texto es un gap de 8pt real y no depende de la fuente.

### Botón tonal (`.pj-btn-tonal`)

Misma geometría que `.pj-btn-primary` (icono 18px, `gap:8px`, `padding:0 24px 0 16px`), pero sobre el contenedor tonal de la navegación activa. Regla: **una sola superficie sólida y saturada por pantalla**, la de la acción que se mide. En Viatges es WhatsApp, así que Publicar baja a tonal. El texto se oscurece en hover/active para mantener AA (4.64 / 5.13 / 5.17:1); solo cambiando el fondo bajaba a 4.14 y 3.71.

### Perfil público (`view: 'publicProfile'`)

Se llega tocando el nombre o la foto de una tarjeta ajena (`.pj-poster-btn`: el bloque avatar+nombre como botón, con chevron gris 14px tras el nombre como pista, hover `#F3F4F8`, radio 14). Con sesión y solo en tarjetas ajenas; el propio nombre lleva a Perfil. En la nav, el perfil público cuenta como Viatges.

Estructura, de arriba abajo: botón volver (44×44, blanco, radio 14) → avatar 88px + nombre (h1 24/800) con `gap:16px` → dos tiles blancos de cifras (radio 16, `gap:8px`; número 24/800, etiqueta 13/600 gris) → "Com li agrada viatjar" (h2 15/700 + chips `.pj-trip-int` en card blanca) → "Viatges actius" (`.pj-pp-trip`: filas blancas radio 16 con ruta 15/800, fecha 13/600 gris y chevron; abren la tarjeta resaltada en Viatges) → acciones de pie (abajo). Los formularios de reportar/bloquear sustituyen las acciones dentro del mismo pie, como card blanca radio 24 (sin modal, igual que las confirmaciones de borrar).

Datos: solo lo que devuelve `public_profile()` (nombre, inicial, foto, preferencias, viajes ofrecidos y solicitudes). Nunca teléfono, correo, apellido completo ni fecha de alta.

### Orden del formulario de publicar

Dos capas para dosificar la información:

1. **Bloque base, sin tarjeta** (lo necesario para un viaje normal): Tipus de publicació → Ruta → Data i hora → Places i preu → Notes *(opcional)*.
2. **Extras, cada uno en su tarjeta `.pj-benefit`** (blanca, borde `#ECEDF2`, radio 16, icono de 40px en círculo `#EEEBFF`, título 15/700, subtítulo 13/600 que describe la consecuencia y `.pj-switch` a la derecha). Plegadas por defecto; al activar el interruptor, su contenido se despliega dentro de la misma tarjeta bajo `.pj-benefit-options` (separador `#ECEDF2`):
   - **Tornes el mateix dia?** (icono de flechas en dos sentidos) → hora de vuelta.
   - **És un viatge recurrent?** (icono de repetir) → días y resumen de la serie.
   - **Avisos** (icono de campana, activo por defecto).
3. **Publicar.**

Quien publica un viaje sencillo no abre ninguna tarjeta. Al editar, las dos primeras tarjetas no aparecen. Las etiquetas de campos anteriores no cambian al activar un extra: la confirmación va dentro de su tarjeta.

### Viajes recurrentes (formulario y tarjetas)

En el formulario de publicar (solo al crear): fila "És un viatge recurrent?" (título 15/700 negro + subtítulo 13/600 gris que describe la consecuencia) con el mismo `.pj-switch` del aviso. Al activarlo aparece "Quins dies?" con 7 botones `dl dt dc dj dv ds dg` en una rejilla de 7 columnas (`gap:4px`, 44px de alto, radio 14, `aria-pressed`, `aria-label` con el nombre completo del día; activo `#EEEBFF`/`#5B4CFB` con borde `#5B4CFB`, inactivo blanco con borde `#ECEDF2`), y debajo una línea de confirmación (13/600 gris, `aria-live`) con la primera y la última salida y el total de viajes. La etiqueta de la fecha no cambia. En las tarjetas, la fecha se sustituye por "Cada dl, dc" (o "De dilluns a divendres", "Cada dia") en el mismo hueco, sin badge nuevo.

### Acciones de pie de pantalla (`.pj-pp-foot` / `.pj-pp-action`)

Para acciones que deben existir pero no competir con el contenido (hoy: *Reportar* y *Bloquejar* en el perfil público). Son el tipo **Texto/link** de la tabla de botones: transparentes, `#5B4CFB` 13px/700, icono 16px `currentColor`, `gap:8px`, `min-height:44px`, `padding:0 16px`, radio 14; hover `#EEEBFF`, focus `#B9B0FF`. Centradas en una fila con `gap:8px`, sin separador ni card.

**Posición:** la pantalla es una columna flex (`.pj-pp`, `min-height:calc(100dvh - 244px)`) y el pie lleva `margin-top:auto`, así que con poco contenido las acciones bajan al pie, y con mucho quedan después del último bloque (`padding-top:40px`). En ambos casos el borde inferior queda a 120px del borde de la pantalla (104px de `.pj-main` + 16px propios). La etiqueta visible es corta ("Reportar"); el nombre de la persona va en `aria-label`.

**Descartado:** filas a ancho completo en gris `#6B6F7B` con separador `#E3E4EA`. El gris no es color de acción del sistema, el separador no era un token y dos filas apiladas pesaban como una lista de opciones.

### Línea informativa de aviso (`.pj-notice`)

En las tarjetas propias de "Els meus", bajo la fila de fecha y hora: campana 14px en `#5B4CFB` + texto 12.5px/600 `#727681`, centrada, sin fondo ni borde. Es información, no un control: no tiene hover ni cursor. Texto: "Avís actiu · ±2 h · només aquest dia · N avisos enviats" o "Avís desactivat". Si en el futuro se hace interactiva, solo puede llevar a editar el aviso de ese viaje; nunca a otra cosa.

### Tarjeta de beneficio con interruptor (`.pj-benefit` + `.pj-switch`)

Para ofrecer un servicio opcional dentro de un formulario (hoy: avisos por correo, tanto en sol·licitud como en oferta; el título cambia según el rol). Se presenta como beneficio, no como casilla de consentimiento: título afirmativo ("T'avisem quan aparegui un viatge que encaixi"), no una pregunta.

- Contenedor: fondo blanco, `border:1.5px solid #ECEDF2`, radio 16, `padding:16px`. Iteración cerrada: se probaron tres degradados (sutil, morado pleno, lavanda), pill "Nou" e ilustración, y se descartó todo en favor de la versión mínima — el degradado pleno empataba con el CTA, el lavanda perdía contraste, y la carga visual no añadía comprensión. La distinción la aporta el copy.
- Regla de copy del componente: el título promete con una palabra definible ("un viatge **compatible**") y el subtítulo la define con números ("Compatible vol dir fins a ±2 h de la teva hora, el mateix dia."), seguida de "Ajusta-ho a la teva flexibilitat". Desactivado: "No t'enviarem cap avís per aquest viatge." Nunca prometer sin definir: evita que un aviso a ±2 h se perciba como error de match.
- Cabecera `flex`, `gap:12px`: icono de campana en círculo de 40px `#EEEBFF` con trazo `#5B4CFB` (mismo recurso que los pasos de la landing; es icono funcional, no ilustración), cuerpo con título 15px/700 `#14151A` y subtítulo 13px/600 `#6B6F7B` (`margin-top:4px`), e interruptor a la derecha.
- Interruptor `.pj-switch`: `<button role="switch" aria-checked>`, 44×26, pista `#D9DBE3` / activa `#5B4CFB`, botón blanco de 20px con desplazamiento de 18px y transición de 160ms. Un switch comunica "servicio activo/inactivo"; un checkbox comunica "acepto". Aquí es lo primero.
- Revelado progresivo: activo → el subtítulo describe la **consecuencia**, no la configuración ("Buscarem viatges fins a ±2 h de la teva hora, aquest mateix dia.") y el `.pj-viewlink` invita a declarar flexibilidad ("Tens més flexibilitat? Ajusta-ho"). Regla de copy: los ajustes de un aviso se explican por lo que harán llegar al usuario, nunca como parámetros sueltos — evita avisos que parezcan errores de match. Etiquetas abiertas en pregunta: "Quanta flexibilitat d'hora tens?" / "I de dia?"; al pulsarlo, `.pj-benefit-options` (separador superior `#ECEDF2`, `padding-top:16px`, grupos a 16px) muestra los segmentados `.pj-seg-tabs` con etiquetas 13px/700. Desactivado → subtítulo "Avís desactivat" y nada más.
- Todo el contenido interior comparte el borde izquierdo de 16px de la tarjeta; solo el subtítulo se alinea con el título (columna del cuerpo).
- Regla: los campos que solo importan a quien acepta una opción no se muestran hasta que la acepta y pide cambiarlos; el valor por defecto se enseña como texto, no como control. Descartado: checkbox con etiqueta larga (se leía como configuración), preguntar antes o después de publicar (pantalla extra y campos duplicados en edición).

### Movimiento: entrada de contenido y carga

Dos animaciones, una por propósito. Ambas se anulan con `prefers-reduced-motion`.

- **`.pj-appear`** (320ms, `cubic-bezier(0.22,1,0.36,1)`, fade + 12px hacia arriba): bloques generales, secciones y estados vacíos. Escalonado de 40ms por posición.
- **`.pj-slide-in`** (600ms, `cubic-bezier(0.16,1,0.3,1)`, fade + 28px desde la derecha): **solo las tarjetas de viaje**. La curva arranca rápido y desacelera mucho al final — entra deslizando y frena. Escalonado de 70ms, tope a partir de la sexta tarjeta. Se eligieron 600ms y no más: por encima de ~800ms la última tarjeta sigue moviéndose cuando el usuario ya quiere pulsar.
- **Esqueleto de carga (`.pj-skel`)**: mientras `tripsLoading`, se muestran dos tarjetas fantasma con la **forma real** de la tarjeta (avatar 44px, dos barras de texto, ruta centrada, fila precio + botón), en `#EDEEF3` con shimmer de 1400ms. La segunda al 60% de opacidad para sugerir continuidad. Regla: el estado de carga imita la silueta del contenido que va a llegar, nunca un texto "Cargando…" — así no hay salto de layout ni cambio de lenguaje visual entre carga y contenido.

### Segmentado (`.pj-seg`)

Un solo componente para toda decisión "elige una opción entre pocas" fuera de la navegación. Contenedor blanco, `border:1.5px solid #ECEDF2`, `border-radius:14px`, `padding:4px`, `gap:4px`. Cada opción: `min-height:40px`, `border-radius:10px`, 14px/600 gris `#727681`; activa (`aria-selected` o `aria-pressed`) = fondo `#EEEBFF` + `#5B4CFB` + 700. Hover inactivo `#F3F4F8`. Focus `outline:2px solid #B9B0FF`. **Sin sombra** (el antiguo tab con sombra morada queda retirado).

Variantes por clase adicional:
- `.pj-seg-tabs`: opciones con `flex:1` a ancho completo. Usado en Ofereixo/Necessito, Com a conductor/Com a passatger y en los selectores de margen horario (±1/±2/±3 h) y de día del formulario de sol·licitud (ahí con `aria-pressed` y `role="group"`, no `tablist`), con `role="tablist"`/`role="tab"`. El contador va en `<span class="pj-seg-count">` (13px/600, opacidad 0.65). Las etiquetas no repiten la palabra del título de la vista: bajo "Propers viatges" son "Ofereixo" / "Necessito", las mismas que el `roleLabel` de las tarjetas.

### Enlace de cambio de vista (`.pj-viewlink`)

Botón de texto para alternar lista/calendario en Viatges: `inline-flex`, `gap:8px`, `min-height:32px`, `padding:0 8px`, radio 10, sin borde ni fondo, `#5B4CFB` 13px/700, icono 16px `currentColor`; hover `#EEEBFF`, focus `#B9B0FF`, `aria-pressed`. Alineado a la derecha, 8px bajo las pestañas y 16px sobre el contenido; cuando no se muestra, las pestañas recuperan los 24px. Etiqueta "Veure per dies" (icono calendario) en lista y "Veure llista" (icono lista) en calendario.

**Regla de aparición:** solo existe si la pestaña activa tiene viajes en más de un día; con todo en un mismo día no hay nada que navegar y la lista es la vista. La vista no se persiste: la lista es siempre el estado por defecto (al cargar y al volver de publicar), y el calendario es exploración puntual dentro de la sesión. Se descartó guardar la preferencia en localStorage: volver de publicar y aterrizar en un día vacío del calendario desorientaba.

**Decisiones descartadas:** un segmentado de dos iconos (`.pj-seg`) en su propia fila, por peso visual excesivo; el mismo en la fila de las pestañas, por acumular dos decisiones en una línea; y calendario por defecto, porque con poca oferta enseña el vacío antes que el contenido.

### Nav (bottom nav / sidebar)

Mismo lenguaje de activo/inactivo que el segmentado, pero con icono SVG que cambia de color junto al texto y sin contenedor común.

### Calendari (vista de viatges)

Card blanca `border-radius:24px; padding:16px`. Cabecera: rango o mes (15px/800, primera letra en mayúscula desde JS, nunca `text-transform`) + dos botones de 36px `#F3F4F8` radio 12. Fila de días `dl…dg` 11px/700 mayúsculas `#8F93A1`. Grid 7 columnas, gap 4, celda `.pj-cal-day` 52px alto, radio 12, 14px/600; hoy = `#5B4CFB`/800; seleccionado = fondo `#5B4CFB` + blanco, sin sombra; pasado o mes vecino = `#C4C7D0` (pasado además `disabled`). Contador por día en pill 16px `#EEEBFF`/`#5B4CFB` (`.pj-cal-count`). Chevron centrado bajo el grid que expande de semana a mes (`aria-expanded`, icono rota 180°, `max-height` animado 260ms). Debajo, `.pj-cal-dayhead`: día seleccionado a la izquierda y "N viatges" a la derecha, y las tarjetas de ese día sin cambios.

### Navbar mobile (bottom nav)

Fija abajo, `min-height:68px`, fondo blanco, `border-top:1px solid #ECEDF2`, respeta `env(safe-area-inset-bottom)`. Tres botones (Viatges/Els meus/Perfil), icono + label 11px, estado activo con fondo morado tenue en pill redondeado (`border-radius:16px`).

### Sidebar desktop

Fija a la izquierda, ancho `248px`, fondo blanco, `border-right:1px solid #ECEDF2`. Logo arriba, lista de botones de navegación a ancho completo. Estado activo tonal, patrón Material: fondo `#EEEBFF`, texto e icono `#5B4CFB`, peso 700; inactivo transparente, `#6B6F7B`/600. Se descartó el activo en morado sólido: competía en peso con el CTA Publicar — la superficie sólida de marca queda reservada a la acción primaria, la navegación indica lugar con contenedor tonal.

### Badges/tags

Patrón pill: `border-radius:999px`, fondo `#EEEBFF`, texto `#5B4CFB`/800, `padding:8px 16px`. Usado para la etiqueta de ruta en "Els meus reserves".

### Landing (redisseny 11 nov. 2026)

Pantalla de acceso sin sesión (`view: 'auth'` y `'reset'`). Tiene **su propio sistema** (tokens `--lp-*`, clases `lp-*`) para no tocar la app: la app sigue con `#5B4CFB` y Plus Jakarta Sans (salto visual aceptado de momento, ver `DECISIONS.md`). El porqué de cada elección está en `DECISIONS.md`; aquí, cómo es hoy.

**Tokens** (`:root`, al final del `<style>` de `index.html`)

| Token | Valor | Uso |
|---|---|---|
| `--lp-primary` / `-hover` | `#5A45E3` / `#422DCD` | CTA sólido, títulos de acento, enlaces. Lila eléctrico con un leve giro al azul. Blanco encima: 6,2:1 |
| `--lp-primary-accent` | `#785FF7` | Foco y detalles decorativos (no texto) |
| `--lp-primary-light` | `#EEEBFE` | Halo del foco en campos |
| `--lp-bg-page` / `--lp-bg-alt` | `#FFFEFC` / `#F4F3FF` | Blanco con un punto cálido y lavanda, alternados por sección |
| `--lp-secondary-sand` / `-blue` | `#FFF1E2` / `#E6F0FF` | Fondos de las ilustraciones de los pasos 2 y 3 |
| `--lp-text-primary` / `-secondary` | `#1B1A22` / `#62606E` | Texto (secundario sobre el fondo: 6,1:1) |
| `--lp-border` | `#E5E2E9` | Bordes decorativos de tarjetas (no de campos) |
| `--lp-radius-card` / `-control` / `-pill` | 20 / 14 / 999 px | Tarjetas / campos y asientos / botones |
| `--lp-motion-fast` / `-normal` | 180 / 420 ms | Hover / apariciones |

**Tipografía**: Source Serif 4 (`--lp-font-display`, 400–700) para titulares y cifras; Inter (`--lp-font-ui`) para interfaz, botones y texto; Plus Jakarta Sans solo en el logotipo y en las tarjetas que imitan la app. Escritorio (≥1200 px): titular del hero hasta 76 px (2 líneas: «Comparteix trajectes.» bold / «Recupera part del cost.» 400), títulos de sección hasta 56 px, texto 17–20 px, botones 56 px de alto con texto de 17 px. Móvil: 40 px / 30 px / 15–17 px / 52 px.

**Layout**: contenedor `.lp-wrap` de 1320 px con márgenes de 20 px (móvil) y 32 px (≥960 px). Puntos de corte: 720 (calculadora y pasos en columnas), 960 (hero y confianza a dos columnas, enlaces de la barra) y 1200 (escala de escritorio). Secciones con 72 / 96 / 120 px de aire.

**Orden**: barra → hero → ahorro (`#pj-estalvi`) → cómo funciona (`#pj-comfunciona`, banda lavanda) → confianza → cierre con acceso (`#pj-acces`, `#pj-auth-card`) → pie.

- **Barra** (`.pj-topnav` + `lp-nav`): transparente; al hacer scroll aparece un velo crema difuminado que se desvanece 32 px hacia abajo (`.lp-scrolled`, estado `navScrolled`), sin línea de corte. Enlaces «Com funciona» y «Avantatges» (≥960 px) y «Entrar» con borde → acceso en modo login. **Ojo:** en esta app el que hace scroll es el `body`, no la ventana; el velo escucha `scroll` en captura.
- **Hero**: foto del Berguedà (`assets/bergueda.webp`) recortada con un `clipPath` orgánico (`#lp-blob`) que sobresale de largo por el borde derecho (un 32 % más allá), para que se lea como un corte intencionado y no como una forma que casi llega. La forma es una **onda diagonal** que sube de izquierda a derecha (lóbulo redondeado abajo a la izquierda, cresta detrás del móvil y una segunda ondulación antes de salir por la derecha; el borde inferior es casi recto, así la foto se abre por abajo a la derecha): da dinamismo, como un camino que asciende; encima, la captura real de la app recortada sin fondo (`assets/movil.webp`); detrás, una mancha lila muy difuminada (`.lp-hero-glass`, `#785FF7` con `blur(36px)`) que deja intuir el color sin dibujar ninguna forma y dos etiquetas flotantes con textos de la landing anterior. La cifra «fins a 30 €» cuenta de 0 a 30 solo con CSS (`@property --lp-n`).
- **Ahorro**: tarjeta doble «≈ 48,50 €» → «fins a X € recuperats». La columna de la derecha no lleva fondo de color: la destaca un halo lila difuminado (`#785FF7` translúcido) que respira cada 3,2 s (`lp-glow`, quieto con `prefers-reduced-motion`). Cuatro asientos (`aria-pressed`) que llenan 1–4 plazas; avanza sola cada 2,4 s y se para para siempre al tocar un asiento; la cifra cuenta con easing cúbico en 550 ms (`_setCalcSeats`, estado `calcSeats` '1'–'4' y `calcDisplay` en euros recuperados). Cálculo plegado en «Com ho calculem».
- **Cómo funciona**: franja lavanda (`--lp-bg-alt`) en diagonal a 45° para dar dinamismo, más alta que el resto de secciones (104 / 136 / 168 px de aire). Vive en un `::before` con máscara vertical, así entra y sale sin línea de corte; encima, dos manchas lila difuminadas (8–10 %). Así se nota el cambio de apartado sin ninguna vora. Tres tarjetas con escenas isométricas animadas en SVG inline (`lp-s1-*`, `lp-s2-*`, `lp-s3-*`): coche que publica sus plazas; casa y oficina separadas con el mensaje viajando entre móviles; tres personas que juntan monedas. Colores solo del DS de la landing.
- **Confianza**: tarjeta de viaje que imita la de la app (Plus Jakarta, ligeramente girada) sobre una mancha lila difuminada (`blur(36px)`, sin forma visible) + tres puntos con icono.
- **Cierre y acceso** (`.lp-final`): titular y etiqueta a la izquierda; tarjeta de acceso a la derecha sobre la foto. En recuperar contraseña y nueva contraseña (`.lp-final-solo`) solo se ve la tarjeta, centrada. **La lógica del acceso no cambia**: mismos `onClick`, `value`/`onChange` y modos que antes.
- **Campos** (`.lp-field`): 50/56 px, radio 14, borde `#8E8A99` (3,4:1, WCAG 1.4.11) y texto de ejemplo `#6E6C7A` (5,1:1: es la única etiqueta visible); foco con borde morado y halo `--lp-primary-light`.
- **Asientos vacíos**: borde punteado y figura `#7F72C8` (≥3:1).
- **Pie** (`.lp-foot`): `#1F1943`, el morado del CTA (mismo tono, 248°) muy oscuro y poco saturado para mantener la lógica de color sin que parezca eléctrico; texto blanco al 68 % (8,1:1), columnas Navegació / Compte / Legal (los avisos legales siguen siendo los `.pj-legal-overlay` de siempre).

**Iconos y etiquetas con brillo** (ventajas del hero, confianza, etiqueta del hero, etiqueta del cierre y flecha de la calculadora): fondo lila muy ligero (`rgba(120,95,247,0.07)`), línea fina lila (`0.32`) y un brillo suave alrededor (`0 0 0 3px` al 5 % + sombra difusa lila). Sin fondos lila opacos: la propuesta gana luz.

**Movimiento**: fade + 12 px en 420 ms. El hero aparece al cargar (`.lp-in`, retardos `.lp-d1–d3`); el resto, al entrar en pantalla con `animation-timeline: view()` (`.lp-reveal`, sin JS: el motor de plantillas puede repintar el DOM y perder clases puestas a mano). `prefers-reduced-motion` lo desactiva todo y deja las escenas en su estado final.

### Modales / estados vacíos

- **No existe un modal real (overlay + backdrop)** en todo el producto. Las confirmaciones (ej. "¿Seguro que quieres eliminar?") se resuelven **inline dentro de la misma card**, sustituyendo su contenido por un mensaje + dos botones. Si en el futuro necesitas un modal de verdad, sería un patrón nuevo — decide conscientemente si quieres introducirlo o mantener la consistencia con este enfoque inline.
- **Estados vacíos**: card centrada, texto gris, opcionalmente con CTA (patrón ya documentado arriba).
- **Toast**: pill fija en `bottom:88px` (para no tapar la bottom nav), centrada horizontalmente, fondo según tipo (`info` negro / `error` rojo / `success` verde), autodesaparece a los 3.2s.

---

## 5. Patrones de interacción

- **Hover**: solo definido explícitamente en el botón de WhatsApp (`style-hover`). El resto de botones no tienen estado hover propio — es una inconsistencia real del sistema actual, no algo a copiar sin pensar.
- **Active/focus**: mismo caso — solo el CTA de WhatsApp define `style-active`/`style-focus` (con outline visible, buena práctica de accesibilidad que no se repite en el resto).
- **Disabled**: no hay un estilo visual de "deshabilitado" (el botón no se atenúa). En su lugar, el patrón es **cambiar el texto del botón** mientras carga (`disabled="{{ xBusy }}"` + `<sc-if value="{{ xBusy }}">Un moment…</sc-if>`). Es el patrón a seguir: comunica el estado por texto, no por opacidad.
- **Loading de pantalla completa**: spinner circular vía clase `.pj-spin` (borde con `border-top-color` de marca, animación de rotación) + texto "Comprovant l'enllaç…" — usado en pantallas de callback/reset.
- **Loading de listas**: texto simple centrado "Carregant…", sin spinner.
- **Feedback al usuario**: dos canales, sin mezclarlos:
  - **Toast** (`_showToast`): para confirmaciones puntuales de una acción (guardar, eliminar, publicar) — no bloquea la pantalla.
  - **Banner inline** (fondo `#FDEBEA`, arriba del formulario): para errores de validación/envío de un formulario concreto.
- **Errores y validaciones**: todo el texto de error que ve el usuario debe ser lenguaje llano, nunca el mensaje técnico crudo de Supabase/Postgres (hay un helper `_friendlyDbError` pensado exactamente para esto — reutilízalo en cualquier función nueva que hable con la base de datos).
- **Accesibilidad básica ya aplicada**: `min-height:44px` en todo elemento pulsable, `role="tab"`/`aria-selected` en segmentos, `aria-current="page"` en nav, `aria-label` en botones/enlaces solo-icono, `alt=""` en imágenes decorativas, `for`/`id` en todos los pares label-input de un solo campo, `role="group"` + `aria-labelledby` en grupos de varios campos (Ruta, Data i hora, Tipus de publicació).
- **Contraste de color (WCAG AA) auditado y corregido**: todos los colores de texto/icono de la paleta cumplen ≥4.5:1 sobre su fondo habitual (texto normal) o ≥3:1 (texto grande). Verificado con la fórmula de luminancia relativa de WCAG. Si añades un color de texto nuevo, comprueba el contraste antes de darlo por bueno — no asumas que "se ve bien" es suficiente.

---

## 6. Reglas de consistencia

**Mantener siempre:**
- Una única familia tipográfica (Plus Jakarta Sans) y solo 3 pesos (600/700/800).
- Radios: `14px` (inputs/**todos los botones, sin excepción**/cards pequeñas), `24px` (cards de contenido), `28px` (cards hero), `999px` (solo badges/toast, nunca botones), `50%` (avatares/círculos). No inventar un radio nuevo.
- Los 3 colores de sombra documentados — no crear sombras grises genéricas nuevas.
- El patrón label-encima-del-input (15px/700/gris, `margin-bottom:8px`) en cualquier formulario nuevo.
- `min-height:44px` en todo elemento interactivo (accesibilidad táctil).
- Mensajes de error siempre en lenguaje llano vía `_friendlyDbError`/`_authErrorMessage`, nunca el error crudo de la base de datos.
- 16px de margen lateral en móvil, 20-28px en desktop — no mezclar anchos de página distintos entre pantallas.

**Errores a evitar al crear pantallas nuevas:**
- No añadir iconos superpuestos dentro de un input si los inputs vecinos no los llevan (ya pasó con fecha/hora — rómpelo con cuidado si es intencional, pero no por descuido).
- No apilar dos paddings de contenedor (página + card) sin revisar el resultado en móvil — es la causa más probable de que algo "se vea distinto" o "se coma ancho" en pantallas estrechas.
- No mostrar `e.message` (el error crudo) directamente al usuario bajo ninguna circunstancia.
- No introducir un cuarto peso tipográfico o una segunda fuente.
- No crear un nuevo breakpoint intermedio — el sistema solo entiende "menos de 900px" y "900px o más".

**Cómo construir una pantalla nueva siguiendo este sistema:**
1. Envuélvela en `<sc-if value="{{ isXView }}">` dentro de `.pj-main`, igual que el resto.
2. Título de pantalla: `<h1>` 24px/800 con `margin:0 0 24px`.
3. Contenido en una o varias cards blancas (`border-radius:24px`), separadas por `margin-bottom:16px` si son una lista.
4. Cualquier formulario: inputs con la receta única de la sección 4, labels 15px/700 gris encima de cada campo.
5. Acción principal: botón pill morado 50px de alto, ancho completo si es la única acción del formulario.
6. Estados de carga/error: reutiliza `_showToast`, el banner inline de error, y `_friendlyDbError`/`_authErrorMessage` — no inventes un mensaje nuevo desde cero.
7. Compruébala en dos anchos: <900px (bottom nav, 16px de margen) y ≥900px (sidebar, card con más padding).

---

---

> **Tabla resumen de tokens:** retirada. Duplicaba los valores de §1 Fundamentos y §4 Componentes, que son la fuente única. Si necesitas los valores en bruto, están ahí.
