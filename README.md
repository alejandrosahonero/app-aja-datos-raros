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
