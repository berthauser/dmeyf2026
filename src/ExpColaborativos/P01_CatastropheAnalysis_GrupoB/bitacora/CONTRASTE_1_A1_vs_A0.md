# Contraste 1 — A1 (`NA`) vs A0 (ceros)

**Qué aísla:** el efecto de **señalar** la ausencia, sin reconstruir ningún valor.
**H2 predecía:** A1 > A0.

Calculado el 2026-09-07, con los 5 brazos todavía sin terminar (faltan A2, A3, A4).

---

## Las 7 diferencias pareadas

| semilla | A1 (`NA`) | A0 (ceros) | dif | gana |
|---|---|---|---|---|
| 100043 | 33.2825 | 30.7775 | **+2.5050** | A1 |
| 200063 | 32.5200 | 33.4850 | −0.9650 | A0 |
| 300089 | 33.8550 | 32.9150 | +0.9400 | A1 |
| 500069 | 33.3450 | 31.6250 | +1.7200 | A1 |
| 700021 | 32.5025 | 32.4775 | +0.0250 | A1 |
| 181219 | 33.4800 | 32.0975 | +1.3825 | A1 |
| 410341 | 32.6725 | 35.8625 | **−3.1900** | A0 |

**A1 gana en 5 de 7.** Pero las dos derrotas son grandes.

## El test

```
Wilcoxon signed rank exact test
V = 18, p-value = 0.5781
```

**No significativo, y no por poco.** Diferencia de medias: +0.3454 a favor de A1.

### ¿Lo sostiene una sola semilla? — Leave-one-out

| sin la semilla | V | p | A1 gana |
|---|---|---|---|
| (ninguna) | 18 | 0.5781 | 5/7 |
| 100043 | 12 | 0.8438 | 4/6 |
| 200063 | 15 | 0.4375 | 5/6 |
| 300089 | 13 | 0.6875 | 4/6 |
| 500069 | 12 | 0.8438 | 4/6 |
| 700021 | 13 | 0.6875 | 4/6 |
| 181219 | 12 | 0.8438 | 4/6 |
| 410341 | 18 | **0.1563** | 5/6 |

**El nulo es sólido.** Sacando cualquier semilla, `p` nunca baja de 0.156.

---

## Hallazgo 1 — el apareamiento NO ayuda acá

| | |
|---|---|
| desvío sin aparear (promedio de los dos brazos) | 1.0791 |
| **desvío de las diferencias pareadas** | **1.9279** |
| correlación entre brazos | −0.4546 |

El Wilcoxon pareado supone que la semilla es un **factor común**: que la semilla
que da un buen modelo en un brazo tiende a darlo también en el otro. Acá eso no
pasa. El desvío de las diferencias (1.93) es **mayor** que el de los brazos por
separado (1.08), así que aparear **agrega** ruido en vez de sacarlo.

Con n=7 la correlación de −0.45 no se distingue de cero, así que no conviene
afirmar que es negativa. Lo que sí queda: **no es positiva, y por lo tanto el
apareamiento no compra nada.**

## Hallazgo 2 — el techo de lo que se puede detectar

Potencia para detectar la diferencia observada (0.3454) con el desvío pareado
observado (1.9279):

| n | potencia |
|---|---|
| 7 | 0.060 |
| 15 | 0.095 |
| 30 | 0.156 |
| 100 | 0.426 |

**La comparación de ganancias medias no se va a resolver con ningún `n`
permitido.** El profesor pone el techo en 15 semillas; harían falta más de 100.

Esto **no es un fracaso del diseño**: es una propiedad del problema, y es un
resultado reportable. El efecto del tratamiento, si existe, es más chico que el
ruido de la semilla.

---

## Hallazgo 3 — el que sí puede sostener el trabajo

**A0 es tres veces más disperso que A1.**

| | A1 (`NA`) | A0 (ceros) |
|---|---|---|
| desvío | **0.5297** | **1.6285** |
| rango | 1.3525 | 5.0850 |

Razón de varianzas: **9.45**.

Test de Pitman–Morgan (el correcto para varianzas de muestras pareadas):
`t = -3.4506, df = 5, p = 0.0182`.

### Pero ojo — esto sí depende de una semilla

| sin la semilla | sd(A1) | sd(A0) | razón | p Pitman |
|---|---|---|---|---|
| (ninguna) | 0.5297 | 1.6285 | 9.45 | 0.0182 |
| 100043 | 0.5731 | 1.5086 | 6.93 | 0.0658 |
| 200063 | 0.5098 | 1.7481 | 11.76 | 0.0260 |
| 300089 | 0.4490 | 1.7821 | 15.75 | 0.0089 |
| 500069 | 0.5675 | 1.6993 | 8.97 | 0.0428 |
| 700021 | 0.5051 | 1.7791 | 12.41 | 0.0172 |
| 181219 | 0.5495 | 1.7560 | 10.21 | 0.0333 |
| **410341** | 0.5434 | **0.9590** | **3.11** | **0.2753** |

Sacando `410341` —la semilla donde A0 dio 35.8625, el valor más alto de todo el
experimento— la razón cae de 9.45 a 3.11 y el `p` se va a 0.275.

**Lectura honesta:** la **dirección** es estable (A0 es más disperso que A1 en las
7 submuestras, con razones de 3.1 a 15.8), pero la **significancia** se apoya en
una sola semilla. Es **sugerente, no establecido**. Y además es **exploratorio**:
no estaba declarado de antemano.

---

## Qué hacer — decisión tomada el 2026-09-07

### 1. Seguir con A2, A3 y A4 tal como están

El contraste 1 salió nulo, pero **eso no condena al contraste 3** (A4 vs A3), que
es el decisivo. A1 y A0 se diferencian en cómo se representan 12 variables
enteras; A3 y A4 comparten imputación idéntica, semilla de datos idéntica e
hiperparámetros idénticos, y difieren **en una sola columna**. Es razonable
esperar que esa diferencia sea mucho más consistente entre semillas.

**No se cambian las 7 semillas ni el diseño.**

### 2. Declarar ESTO antes de correr A2, A3 y A4

> **Predicción secundaria, registrada el 2026-09-07, con A2/A3/A4 sin correr:**
> los brazos que **señalan** la ausencia (A1, A4) van a tener **menor varianza
> entre semillas** que los brazos que no señalan (A0, A2, A3).

Se declara ahora, con los datos de esos tres brazos todavía inexistentes. Si se
cumple, es un hallazgo **confirmatorio** y no exploratorio. Si no se cumple, se
reporta igual.

Esto reformula H2 de una manera más interesante que la original:

> Señalar la ausencia no hace al modelo **mejor** en promedio: lo hace **más
> estable**.

### 3. Reportar el nulo del contraste 1 sin maquillarlo

Con la potencia calculada al lado. «No detectamos diferencia» acompañado de
«y con este ruido harían falta más de 100 semillas para detectarla» es una
conclusión mucho más fuerte que un `p` suelto.


---

# Tablero de la predicción registrada

Actualizado 2026-09-07 tras A2. **La predicción se declaró con A2, A3 y A4 sin
correr.**

| brazo | señala | desvío | razón vs A1 | Pitman–Morgan vs A1 | LOO robusto |
|---|:--:|---|---|---|---|
| `A1_na` | **sí** | **0.5297** | — | — | — |
| `A0_cero` | no | 1.6285 | 9.45 | p = 0.0182 | ✗ cae a 0.275 sin `410341` |
| `A2_interp` | no | **1.8767** | **12.55** | **p = 0.0147** | ✓ p ≤ 0.0526 en las 7 |
| `A3_mice` | no | _pendiente_ | | | |
| `A4_mice_flag` | **sí** | _pendiente_ | | | |

**2 de 2 brazos «no señala» salieron dispersos.** El de A2 además resiste el
leave-one-out, que es donde el de A0 se caía.

## El test que queda es el decisivo

`A4` vs `A3` comparten imputación MICE, semilla de datos e hiperparámetros. Sólo
los separa la columna `ca_reparado`. Si la predicción es cierta:

- `A3` (no señala) → desvío alto, del orden de 1.6–1.9
- `A4` (señala) → desvío bajo, del orden de 0.5

Y eso **está registrado antes de correrlos**.

## Lo que ya se puede escribir, pase lo que pase

Con 3 de 5 brazos, dos afirmaciones se sostienen:

1. **Ningún tratamiento cambia la ganancia media de forma detectable.** A1 vs A0:
   `p = 0.578`. A2 vs A1: `p = 0.938`, diferencia de 0.02. Y la potencia dice que
   con este ruido harían falta más de 100 semillas.
2. **Pero los tratamientos no son equivalentes.** El que señala tiene entre 9 y 12
   veces menos varianza entre semillas que los que reconstruyen o no hacen nada.

> Señalar la ausencia no hace al modelo **mejor**. Lo hace **más estable**.


---

# Tablero actualizado tras A3 — 2026-09-08

| brazo | señala | desvío | razón vs A1 | Pitman–Morgan | ¿aguanta LOO? |
|---|:--:|---|---|---|---|
| `A1_na` | **sí** | **0.5297** | — | — | — |
| `A0_cero` | no | 1.6285 | 9.45 | p = 0.018 | ✗ → 3.11 sin `410341` |
| `A2_interp` | no | 1.8767 | **12.55** | **p = 0.015** | **✓ p ≤ 0.053 en las 7** |
| `A3_mice` | no | 1.3019 | 6.04 | p = 0.070 | ✗ → 1.83 sin `410341` |
| `A4_mice_flag` | **sí** | _pendiente_ | | | |

**La dirección es 3 de 3**: los tres brazos que no señalan son más dispersos que
A1. **La estadística es 1 de 3**: sólo A2 resiste el leave-one-out.

## El problema: la semilla 410341

| brazo | valor en 410341 | z |
|---|---|---|
| `A1_na` | 32.6725 | −0.80 |
| `A0_cero` | **35.8625** | **+1.91** |
| `A2_interp` | 32.9025 | −0.09 |
| `A3_mice` | **36.0450** | **+1.94** |

En A0 y en A3 esa semilla es el máximo del brazo y por sí sola infla la varianza.
Sacarla derrumba las dos comparaciones (9.45 → 3.11 y 6.04 → 1.83). En A2 no pasa,
y por eso A2 es la única sólida.

**Hay que reportar esto, no esconderlo.** Con 7 semillas, una observación extrema
puede sostener un efecto de varianza entero.

## Estado de los contrastes declarados

| # | contraste | H2 predecía | resultado | |
|---|---|---|---|---|
| 1 | A1 vs A0 | A1 > A0 | p = 0.578, dif +0.35 | nulo |
| 2 | A3 vs A1 | A3 < A1 | p = 0.813, dif **+0.42** | nulo, y dirección **opuesta** |
| 3 | **A4 vs A3** | A4 > A3 | _pendiente_ | |
| 4 | A4 vs A1 | A4 ≈ A1 | _pendiente_ | |

**Dos contrastes declarados, dos nulos.** En ganancia media, H2 no se sostiene.

## A4 es ahora decisivo de verdad

`A3` y `A4` comparten imputación MICE, semilla de datos e hiperparámetros. Sólo
los separa `ca_reparado`. Dos escenarios:

- **A4 con desvío ≈ 0.5** (como A1) → el flag reduce la varianza con todo lo demás
  idéntico. Es la evidencia más limpia posible, y está pre-registrada.
- **A4 con desvío ≈ 1.3** (como A3) → la historia de la varianza se cae, y el
  trabajo concluye que **ningún tratamiento de Catastrophe Analysis mueve nada**,
  ni en media ni en dispersión. También es un resultado, y honesto.
