# Pujobaixo — Guía de sistema de diseño

Extraída directamente del código (`index.html`) auditando todos los valores de color, tipografía, espaciado y componentes ya en uso. No es un sistema inventado desde cero: documenta lo que el producto ya hace, para poder repetirlo con criterio en pantallas nuevas.

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
| Verde éxito | `#1D874A` | Precio, texto de éxito |
| Fondo éxito | `#EAF7EF` | Fondo de banner de éxito |
| Verde WhatsApp | `#075E54` (hover `#06534A`, active `#05463F`, focus outline `#128C7E`) | CTA de contacto por WhatsApp |
| Gris placeholder | `#8F93A1` | Placeholder de inputs |

### Fondos, bordes, sombras y estados

- **Fondo de página**: siempre `#F3F4F8`, nunca blanco puro fuera de una card.
- **Cards**: fondo `#fff` con esquinas muy redondeadas (ver radios abajo) — es el único contenedor "elevado" del sistema.
- **Bordes**: 1.5px solid `#ECEDF2` en inputs y botones secundarios. No hay bordes de otro grosor.
- **Sombras** (solo 3 recetas en todo el producto):
  - Card/hero: `0 20px 60px -30px rgba(20,21,26,0.25)` — difuminada, oscura, sin color de marca.
  - Toast: `0 12px 30px -10px rgba(20,21,26,0.4)` — más contraste, para que flote sobre el contenido.
  - Tab activo: `0 8px 20px -10px rgba(91,76,251,0.45)` — sombra de color (morado marca), reservada para el elemento seleccionado en un selector de pestañas.
- **Estado "activo/seleccionado"** (tabs, nav): fondo `rgba(91,76,251,0.1)` o `#EEEBFF` + texto `#5B4CFB` + peso 700 + (opcional) la sombra de tab activo.

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
| Primario compacto | `#5B4CFB` | `#fff` / 700 | ninguno | `14px` | `min-height:44px` (`padding:0 24px`) | CTA secundario en contexto ("+ Publicar", CTAs de estado vacío) |
| Secundario/outline | `#fff` | `#14151A` / 700 | `1.5px solid #ECEDF2` | `14px` | `44px` | Acción neutra ("Editar", "Cancel·lar") |
| Peligro | `#FDEBEA` | `#C22A24` / 700 | `1.5px solid #FBD8D6` | `14px` | `44px` | Acción destructiva ("Eliminar", "Sí, eliminar") |
| Texto/link | transparente | `#5B4CFB` / 700 | ninguno | — | auto | Enlace de acción secundaria ("Registra't", "Has oblidat la contrasenya?") |
| WhatsApp CTA | `#075E54` | `#fff` / 700 | ninguno | `14px` | `44px` | Único botón con estados hover/active/focus explícitos |
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

### Tabs

Dos "familias" de tabs con el mismo lenguaje visual:
1. **Segmentos de contenido** (Ofereixo/Necessito, Conductor/Passatger): fila `flex`, cada botón `flex:1`, activo = tinte morado + sombra suave + texto morado/700; inactivo = transparente + texto gris/600.
2. **Nav (bottom nav / sidebar)**: mismo lenguaje de activo/inactivo, pero con icono SVG que cambia de color junto al texto.

### Navbar mobile (bottom nav)

Fija abajo, `min-height:68px`, fondo blanco, `border-top:1px solid #ECEDF2`, respeta `env(safe-area-inset-bottom)`. Tres botones (Viatges/Els meus/Perfil), icono + label 11px, estado activo con fondo morado tenue en pill redondeado (`border-radius:16px`).

### Sidebar desktop

Fija a la izquierda, ancho `248px`, fondo blanco, `border-right:1px solid #ECEDF2`. Logo arriba, lista de botones de navegación a ancho completo (no pills), mismo esquema de color activo/inactivo que el bottom nav.

### Badges/tags

Patrón pill: `border-radius:999px`, fondo `#EEEBFF`, texto `#5B4CFB`/800, `padding:8px 16px`. Usado para la etiqueta de ruta en "Els meus reserves".

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

## Tabla resumen de tokens

### Colores
| Token | Valor |
|---|---|
| `color-brand` | `#5B4CFB` |
| `color-brand-tint` | `rgba(91,76,251,0.1)` / `#EEEBFF` |
| `color-text-primary` | `#14151A` |
| `color-text-secondary` | `#6B6F7B` |
| `color-text-muted` | `#727681` |
| `color-border` | `#ECEDF2` |
| `color-bg-page` | `#F3F4F8` |
| `color-bg-surface` | `#fff` |
| `color-danger` | `#C22A24` |
| `color-danger-bg` | `#FDEBEA` |
| `color-danger-border` | `#FBD8D6` |
| `color-success` | `#1D874A` |
| `color-success-bg` | `#EAF7EF` |
| `color-whatsapp` | `#075E54` (hover `#06534A`, active `#05463F`, focus `#128C7E`) |
| `color-placeholder` | `#8F93A1` |

### Tipografía
| Token | Valor |
|---|---|
| `font-family` | `'Plus Jakarta Sans', sans-serif` |
| `weight-regular-app` | 600 |
| `weight-medium-app` | 700 |
| `weight-bold-app` | 800 |
| `size-hero` | 26px |
| `size-h1` | 24px |
| `size-route` | 19px |
| `size-price` | 17px |
| `size-body` | 15px |
| `size-button` | 14–15px |
| `size-label` | 15px |
| `size-caption` | 11–12.5px |
| `letter-spacing-heading` | -0.02em |

### Radios
| Token | Valor |
|---|---|
| `radius-sm` (inputs/**todos los botones**/tabs) | 14px |
| `radius-card` | 24px |
| `radius-card-hero` | 28px |
| `radius-pill` (solo badges/toast, no botones) | 999px |
| `radius-circle` | 50% |

### Sombras
| Token | Valor |
|---|---|
| `shadow-card` | `0 20px 60px -30px rgba(20,21,26,0.25)` |
| `shadow-toast` | `0 12px 30px -10px rgba(20,21,26,0.4)` |
| `shadow-tab-active` | `0 8px 20px -10px rgba(91,76,251,0.45)` |

### Spacing
| Token | Valor |
|---|---|
| `gap-xs` | 4–8px |
| `gap-sm` | 8px |
| `gap-md` | 16px |
| `gap-lg` | 24px |
| `padding-page-mobile` | 16px |
| `padding-page-desktop` | 24px |
| `padding-card` | 32px (desktop) / 16px (móvil) |
| `margin-list-item` | 16px |
| `touch-target-min` | 44px |

### Componentes reutilizables
| Componente | Receta base |
|---|---|
| Botón primario | `#5B4CFB` bg, `#fff` texto 800, `14px` radio, `50px` alto |
| Botón secundario | `#fff` bg, borde `#ECEDF2`, `14px` radio, `44px` alto |
| Botón peligro | `#FDEBEA` bg, texto `#C22A24`, borde `#FBD8D6` |
| Input estándar | `48px` alto, `14px` radio, borde `#ECEDF2`, `padding:0 16px` |
| Card de contenido | `#fff` bg, `24px` radio, `16px` padding, `14px` margin-bottom |
| Card hero | `#fff` bg, `28px` radio, `36px 32px` padding, `shadow-card` |
| Tab/segmento | `flex:1`, `14px` radio, activo = tinte marca + sombra + texto marca |
| Toast | pill fija bottom, `999px` radio, `shadow-toast` |
