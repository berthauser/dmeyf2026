# Conclusiones — Experimento H2, Catastrophe Analysis, Grupo B

35 corridas: 5 brazos × 7 semillas. Corridas el 2026-09-07/08.
`future = 202107`, métrica `ganancia_suavizada_max`.

---

## El resultado en una frase

> **Ningún método de Catastrophe Analysis produjo un efecto detectable sobre la
> ganancia — ni en promedio ni en dispersión.**

Los cuatro contrastes declarados de antemano dieron nulos. La predicción
secundaria que registramos a mitad de camino falló en su prueba más limpia.

**El experimento se diseñó para poner a prueba H2 y los datos apoyan H1.**

---

## Los 5 brazos

| brazo | señala | reconstruye | media | desvío | mín – máx |
|---|:--:|:--:|---|---|---|
| `A0_cero` | ✗ | ✗ | 32.7486 | 1.6285 | 30.78 – 35.86 |
| `A1_na` | ✓ | ✗ | 33.0939 | **0.5297** | 32.50 – 33.85 |
| `A2_interp` | ✗ | ✓ | 33.0714 | 1.8767 | 30.85 – 36.30 |
| `A3_mice` | ✗ | ✓ | 33.5139 | 1.3019 | 32.36 – 36.05 |
| `A4_mice_flag` | ✓ | ✓ | 32.9504 | 1.3903 | 30.47 – 34.66 |

Las cinco medias caben en **0.77 puntos**. El desvío entre semillas *dentro* de
un brazo llega a 1.88. **El ruido de la semilla es más grande que cualquier
diferencia entre tratamientos.**

## Los 4 contrastes declarados

Wilcoxon pareado por semilla, dos colas, corrección de Holm.

| # | contraste | H2 predecía | dif. **mediana** | dif. media | gana | p | p Holm |
|---|---|---|---|---|---|---|---|
| 1 | A1 vs A0 | A1 > A0 | +0.9400 | +0.3454 | 5/7 | 0.5781 | 1.00 |
| 2 | A3 vs A1 | A3 < A1 | +0.0275 | +0.4200 | 4/7 | 0.8125 | 1.00 |
| 3 | **A4 vs A3** | A4 > A3 | **+0.0100** | −0.5636 | 4/7 | 0.8125 | 1.00 |
| 4 | A4 vs A1 | A4 ≈ A1 | +0.0275 | −0.1436 | 4/7 | 1.0000 | 1.00 |

**Cuatro de cuatro nulos.**

### Mediana o media: cuál mirar

Las dos columnas cuentan historias distintas y conviene ser explícito. El Wilcoxon
de rangos con signo es un test **basado en rangos**, así que el resumen que le
corresponde es la **mediana** de las diferencias pareadas, no la media.

Por la mediana, los contrastes 2, 3 y 4 son **planos**: +0.03, +0.01 y +0.03.
Prácticamente cero. Las medias (+0.42, −0.57, −0.14) están arrastradas por una o
dos semillas extremas — en el contraste 3, por ejemplo, `410341` sola aporta una
diferencia de −3.35.

**Lectura correcta:** no es que los tratamientos vayan «al revés» de lo predicho.
Es que **no van a ningún lado**. La mediana de la diferencia pareada es
indistinguible de cero en los tres contrastes que involucran reconstrucción.

El único con una mediana apreciable es el contraste 1 (+0.94 a favor de `NA`
contra los ceros), pero A1 gana en apenas 5 de 7 semillas y eso no alcanza:
`p = 0.578`.

## Por qué el nulo es informativo y no un fracaso

Potencia calculada con el ruido observado (desvío de las diferencias pareadas
A1–A0 = 1.9279, diferencia observada 0.3454):

| n | potencia |
|---|---|
| 7 | 0.060 |
| 15 (el techo del profesor) | 0.095 |
| 30 | 0.156 |
| 100 | 0.426 |

**Con el presupuesto permitido de semillas, este efecto no se puede detectar.**
La afirmación correcta no es «no hay efecto» sino:

> Si existe un efecto, es más chico que el ruido de la semilla, y hacen falta más
> de 100 semillas para verlo.

Un nulo con la potencia calculada al lado es un resultado; un `p` suelto no.

---

## La predicción secundaria, y por qué la reportamos aunque falló

A mitad del experimento —con A0 y A1 corridos, y A2/A3/A4 **sin correr**—
registramos:

> Los brazos que **señalan** (A1, A4) tendrán menor varianza entre semillas que
> los que no señalan (A0, A2, A3).

Resultado:

| brazo | señala | desvío |
|---|:--:|---|
| `A1_na` | **sí** | **0.5297** |
| `A3_mice` | no | 1.3019 |
| `A4_mice_flag` | **sí** | **1.3903** |
| `A0_cero` | no | 1.6285 |
| `A2_interp` | no | 1.8767 |

**Falla.** A4 señala y es tan disperso como los que no señalan. El test más limpio
—A4 vs A3, que comparten imputación, semilla de datos e hiperparámetros y sólo
difieren en `ca_reparado`— da razón de varianzas **1.14** y `p = 0.887`.

**El flag no hace nada.**

### Y la observación que quedaba tampoco sobrevive

A1 es el único brazo estable (0.53 contra 1.30–1.88). Las comparaciones de a pares
daban `p` chicos: A2 vs A1 `p = 0.015`, A0 vs A1 `p = 0.018`.

Pero esos `p` están inflados: **la comparación se eligió después de ver los
datos**, buscando el brazo con menor varianza entre cinco. Corrigiendo eso con un
test de permutación que respeta el apareamiento —se permutan las etiquetas de
brazo dentro de cada semilla— la pregunta correcta es «¿qué tan raro es que
*alguno* de los 5 brazos tenga un desvío tan chico como 0.5297?»:

| test | p |
|---|---|
| permutación, desvío mínimo | **0.1731** |
| permutación, razón máx/mín de varianzas | **0.1589** |
| Bartlett (5 grupos) | 0.1061 |
| Fligner–Killeen (5 grupos) | 0.2743 |

**No es estadísticamente notable.** Con 5 brazos y 7 semillas, que uno salga
bastante más estable que el resto pasa por azar cerca del 17 % de las veces.

---

## Una hipótesis para trabajo futuro (post-hoc, NO un resultado)

Vale la pena dejarla anotada, marcada como lo que es: una observación posterior a
los datos, sin respaldo estadístico en este experimento.

| brazo | señala | qué hay en las celdas de 202006 | desvío |
|---|:--:|---|---|
| `A0_cero` | ✗ | ceros | 1.6285 |
| `A1_na` | ✓ | **ausencia real (`NA`)** | **0.5297** |
| `A2_interp` | ✗ | valores imputados | 1.8767 |
| `A3_mice` | ✗ | valores imputados | 1.3019 |
| `A4_mice_flag` | ✓ | valores imputados | 1.3903 |

A1 no es el único que **señala** — A4 también. A1 es el único donde el valor está
**genuinamente ausente**. En todos los demás hay *algún* número en esas celdas, y
el árbol puede partir sobre él.

Mecanismo plausible: con `NA`, LightGBM aprende **una dirección por defecto** por
split y no parte sobre el ruido de ese mes. Con un valor imputado, sí parte, y
esos cortes se mueven con el muestreo de `feature_fraction`, que depende de la
semilla.

Si esto fuera cierto, el eje relevante no sería *señalar vs. reconstruir* sino
**ausencia vs. presencia de un valor**. Es una H5 para otro experimento, con su
propia pre-registración y muchas más semillas.

---

## Por qué A4 valió la pena aunque el resultado sea nulo

Sin `A4`, este experimento no podría distinguir dos explicaciones de la derrota de
MICE:

1. reconstruir el valor no sirve, o
2. imputar destruyó la señal de ausencia.

`A4` ocupa la celda vacía del 2×2 (señala ✓ + reconstruye ✓) y permite decir que
**ninguna de las dos explica nada**, porque agregar la señal sobre la imputación
tampoco cambió el resultado.

**El brazo que agregamos es el que hace interpretable el nulo.** Ese es el aporte
metodológico del trabajo, independientemente de que H2 no se sostenga.

---

## Limitaciones

- **7 semillas.** Es el factor limitante y está cuantificado arriba.
- Hiperparámetros congelados del baseline (`num_leaves = 256`,
  `min_data_in_leaf = 64`, `num_iterations = 428`, de `WF6390`), no
  re-optimizados por brazo. `min_data_in_leaf` cayó en el **borde inferior** de la
  grilla, así que el óptimo podría estar fuera de lo explorado.
- **El apareamiento no ayudó.** El Wilcoxon pareado supone que la semilla es un
  factor común entre brazos. El desvío de las diferencias A1−A0 (1.9279) resultó
  **mayor** que el de los brazos por separado (1.0791): aparear agregó ruido. Con
  n=7 no se puede afirmar que la correlación sea negativa, pero sí que no es
  positiva.
- `A4` tiene **5 columnas más** que los demás (`ca_reparado` y sus lag/delta), así
  que no es dimensionalmente idéntico.
- **MICE necesitó filas donantes** de 202005 y 202007 (hasta 40.000 por mes):
  en 202006 las 12 variables están rotas al 100 % y no hay nada de donde estimar
  el modelo de imputación.
- La imputación usó una semilla fija propia (`999983`) y no varió entre corridas:
  la varianza medida es sólo la del LightGBM.
- `foto_mes` está en `campos_buenos`, así que el modelo **ya podía** aislar 202006
  con un split. El `NA` no es la única forma de señalar, es la más barata.
- Las ganancias del Grupo A (`future = 202109`, Kaggle) no son comparables con
  las del Grupo B.
- La semilla `410341` fue extrema en A0 (z = +1.91) y A3 (z = +1.94) y sostenía
  sola los efectos de varianza en esos dos brazos. Queda documentado.
