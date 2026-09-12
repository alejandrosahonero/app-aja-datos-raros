# facts-staging — de la investigación al catálogo

Los ficheros **sueltos en este directorio** son lotes investigados y **sin
fusionar**. `merged/` guarda los que ya entraron en `assets/data/facts.json`.

Los fusionados se conservan con su `_evidence` intacto a propósito: es la
trazabilidad de por qué entró cada dato, y `_evidence` nunca viaja al APK — el
script lo borra al fusionar.

## Cómo se usa

```bash
# Esquema, longitudes, ids, cifras citadas, trampa de escala. No toca la red.
python3 tool/ingest_facts.py --stage tool/facts-staging --check

# Lo mismo, y golpea cada sourceUrl. Lento y vale la pena.
python3 tool/ingest_facts.py --stage tool/facts-staging --check --links

# Fusiona lo que pasa: borra _evidence y teje las entradas en la rotación.
python3 tool/ingest_facts.py --stage tool/facts-staging --apply
```

`--apply` entrelaza por categoría en vez de pegar bloques al final. Vaciando
primero el cubo más grande, así que la racha máxima de una misma categoría se
queda en 2 — la que tiene el catálogo escrito a mano. Un bloque largo de la misma
categoría se lee como si la app se hubiera atascado (§3.2).

## Qué comprueba la máquina y qué no

**Sí:** esquema completo, categoría válida, ids sin colisión, longitudes que
sobreviven a la imagen 1080x1920, `sourceUrl` https y de dominio no vetado, que la
URL responda, **que toda cifra escrita aparezca en la frase de `_evidence`**, y la
trampa del billón/trillón entre español e inglés.

**No:** que la página diga lo que la respuesta afirma más allá de las cifras. Eso
sigue necesitando leer `_evidence` junto a la respuesta. Es exactamente donde el
catálogo original falló doce veces.

Las dos puertas de cifras existen porque en el lote de 448 hubo que cazar a mano
cinco números que la fuente no sostenía y uno que estaba **mil veces mal en español
y bien en inglés** (`trillón` es 10¹⁸ y `trillion` 10¹²). Ambas cosas son ahora
automáticas.

## Un 403 no es un enlace muerto

Britannica, la CDC, Mayo Clinic y etymonline sirven la página a un navegador y la
niegan a un script. Esas entradas se **conservan** y se listan aparte, bajo
`kept, but unverifiable by machine`, para abrirlas a mano una vez. Rechazarlas
tiraría las mejores fuentes del catálogo.

Distinto es el investigador: **si no pudo abrir la página, no puede ponerla como
fuente.** `BRIEF.md` lo exige — `sourceUrl` tiene que ser algo que se leyó.

## Historial

| Lote | Entradas | Estado |
|---|---|---|
| Primero (8 ficheros en `merged/`) | 448 | Fusionado. Catálogo de 85 → 533. |

Del primer lote, una auditoría de afirmación-contra-evidencia marcó 45. La mayoría
eran citas recortadas, no datos falsos. Lo que sí salió: dos contradicciones de
fecha, un superlativo inventado, una atribución a una persona que la fuente no
menciona, y el error de escala numérica. Todo corregido antes de fusionar.
