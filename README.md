# Ajá: Datos Curiosos Raros

App Android de feed vertical swipeable con preguntas y respuestas curiosas sobre ciencia, historia, lenguaje y cuerpo humano. Freemium con monetización (AdMob + compra "quitar anuncios"), consentimiento GDPR, reseñas in-app, tema Material 3 claro/oscuro, navegación declarativa y localización es/en.

> **Para agentes de IA y para cualquiera que toque el código: leer [`CLAUDE.md`](CLAUDE.md) primero.** Explica la arquitectura, las reglas y el porqué de cada decisión.

---

## Qué incluye

| Área | Implementación |
|---|---|
| Estado | Riverpod 3 (`Provider` / `NotifierProvider` / `AsyncNotifierProvider`) |
| Navegación | `go_router` con rutas tipadas y deep links (`aja://`) |
| Anuncios | `AdsService`: banner adaptativo, interstitial con pacing |
| Consentimiento | UMP SDK (incluido en `google_mobile_ads`) + "Opciones de privacidad" en Ajustes |
| Compras | `in_app_purchase`: producto no consumible `premium_remove_ads` + restaurar compras |
| Contenido | Catálogo empaquetado en `assets/data/facts.json`, sin backend en el MVP |
| Favoritos | Guardado local en `shared_preferences`, detrás del gate premium |
| Permisos | Ninguno en runtime. `POST_NOTIFICATIONS` volverá con la pregunta del día |
| Reseñas | `in_app_review` con guardas (5 acciones, 3 días de antigüedad, 120 días entre solicitudes) |
| Tema | Material 3 desde un único seed color, claro/oscuro/sistema persistido |
| Almacenamiento | `shared_preferences` (flags) + `flutter_secure_storage` (entitlement) |
| Localización | `gen-l10n` con `app_es.arb` / `app_en.arb` |

---

## Feedback de los gestos del mazo

Sobre el mazo hay una fila de **chips de categoría** ("Todas" más una por categoría) y, debajo de ellos, el **banner de anuncios**. El banner va ahí y no abajo a propósito: la tarjeta se arrastra en cuatro direcciones y un banner pegado al borde inferior, bajo el dedo, es el ejemplo de manual del clic accidental. Si el usuario es premium o no entra creativo, el hueco no existe — no queda una franja gris.

La interacción principal es *swipear* las tarjetas en cuatro direcciones. Cada gesto dispara una acción diferente, y el botón circular bajo el mazo crece mientras arrastras para confirmar visualmente qué acción se va a ejecutar:

- **Izquierda** (skip): descarta la tarjeta y muestra la siguiente. El botón "Siguiente" crece hasta 1.4x y aparece un badge (`✕`) en la esquina superior derecha de la tarjeta.
- **Derecha** (flip): voltea la tarjeta para ver la respuesta sin descartarla. El botón "Ver respuesta" crece y el badge (`↻`) aparece en la esquina superior izquierda.
- **Arriba** (favorito): guarda la tarjeta en el apartado de Guardadas. Solo disponible para usuarios premium. El botón "Guardar esta tarjeta" crece y el badge (`🔖`) flota en el centro inferior.
- **Abajo** (compartir): genera una imagen 1080x1920 con la pregunta y abre la hoja de compartir del sistema, lista para publicar en Instagram o TikTok sin recortes. Gratis para todo el mundo. El botón "Compartir la pregunta" crece y el badge (`⇪`) aparece en el centro superior. Pide el arrastre más largo de los cuatro (0,26 del alto frente al 0,16 de guardar): comparte el mismo eje que el gesto de guardar y abre una hoja modal encima de la app, así que un movimiento impreciso no puede alcanzarla por accidente.

El badge siempre se posiciona en el lado **opuesto** al que arrastras, porque la tarjeta se desliza hacia fuera y ocultaría un badge en el lado del gesto. Solo una dirección reacciona a la vez: el eje dominante gana, así dos botones nunca crecen simultáneamente.

La imagen compartida lleva solo la **pregunta**, nunca la respuesta: es el motivo para instalar la app. Se pinta directamente sobre un `Canvas` (`FactStoryImage`) en lugar de rasterizar un widget, porque tiene que medir 1080x1920 exactos independientemente del tamaño, la densidad y el tema del móvil. El texto se autoajusta para caber en la tarjeta, y todo el contenido legible queda dentro del área segura que Instagram y TikTok no tapan con su propia interfaz. Los colores salen de `AppColors.seed`, así que rebrandear la app rebrandea también lo que se comparte.

---

## Empezar

```bash
flutter pub get
flutter run
```

Antes de cerrar cualquier cambio:

```bash
dart format lib test && flutter analyze && flutter test
```

---

## Configuración de Ajá

La identidad de la app (nombre, IDs, colores) está completamente fijada. Antes de publicar en Play Console, completar los siguientes items en el checklist de [`CLAUDE.md` §11](CLAUDE.md):

- `lib/core/config/ad_config.dart` → IDs de producción de AdMob.
- `android/app/src/main/AndroidManifest.xml` → App ID de AdMob de producción.
- `lib/l10n/*.arb` → localización (UI textos reales).
- Iconos y splash (assets).
- Crash reporting (Crashlytics o Sentry).
- Políticas legales (privacidad, Data Safety, content rating).

**Los anuncios usan exclusivamente los IDs oficiales de prueba de Google.** Los IDs de producción solo se activan en un build `--release`, para que nunca se genere tráfico inválido desde desarrollo.

---

## Publicar

```bash
flutter clean && flutter pub get
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols/1.0.0
```

Antes hay que crear `android/key.properties` a partir de `android/key.properties.example`
(ese archivo y el `.jks` están en `.gitignore`; **nunca** se commitean).

Guardar `build/symbols/<versión>` fuera del repositorio: sin esos símbolos los crashes son ilegibles.
