# Predicción Final — Competencia Kaggle

**Ernesto A. Zapata Icart** · Modalidad Gerencial · `utn-2026-virtual-mgr`
`future = 202109` · corrido el 2026-09-17

---

## El submit que compite

| | |
|---|---|
| archivo | **`KA7390_950.csv`** |
| envíos | **950** |
| ganancia Public | 20.570 |
| lo genera | `719_final_gerencial.ipynb`, `PARAM$experimento <- 7390` |

Elegido **manualmente** en Kaggle. La competencia permite un solo submit final.

> El Public Leaderboard muestra 27.066, que es el máximo histórico de la cuenta y
> corresponde a `KA7191_1200`, de una corrida anterior. Eso es el comportamiento
> que describe el PDF §5.5: Kaggle siempre muestra el máximo del usuario, sin
> importar qué esté seleccionado. **El submit elegido es el 950 de la 7390.**

---

## Cómo regenerarlo

Correr `719_final_gerencial.ipynb` completo, en Google Colab. Deja en
`/content/buckets/b1/exp/WF7390/kaggle/` los once archivos `KA7390_800.csv` a
`KA7390_1300.csv`; el elegido es el de 950.

El notebook trae las salidas de la corrida real, así que se puede verificar sin
ejecutarlo.

**Es reproducible, y está verificado.** El 2026-09-18 se re-corrió el notebook
desde cero en una sesión nueva hasta el Grid Search, y dio los mismos números:

```
dtrain: 15876 filas de 179449 posibles
num_leaves 128 · min_data_in_leaf 64 · num_iterations 716
```

Que eso se cumpla no era gratis: ver *El hallazgo* más abajo.

### Configuración

| etapa | qué se hizo |
|---|---|
| Catastrophe Analysis | **sin cambios** — `NA` en las 12 variables rotas de 202006 |
| Data Drifting | `rank_cero_fijo` con `ties.method = "first"`, corriendo **después** del FE intra-mes |
| FE intra-mes | baseline + 4 flags de tenencia, 7 Z-Score y 8 ratios |
| FE histórico | **sin cambios** — lag1, lag2, delta1, delta2 |
| Training Strategy | **sin cambios** — los 15 meses de `[202005, 202107]` |
| Undersampling | `training_pct <- 0.08` (sólo afecta al Grid Search) |
| Hyperparameter Tuning | grilla 4×5; ganador `128 / 64 / 716`, AUC en validation **0.9462077** |
| Reproducibilidad | `num_threads = 2`, `deterministic = TRUE` |
| Final Training | **semillerío de 10 semillas**, promediando probabilidades |

Cifras del pipeline: 53 columnas tras el FE intra-mes, **253** tras el FE
histórico, `dtrain` de **15.876** filas, `dfinal_train` de **192.651**, y 13.242
clientes en 202109.

Las diez semillas, tomadas en el orden en que estaban registradas de antemano y no
elegidas por resultado:

```
100043  200063  300089  500069  700021  181219  410341  568723  618347  831781
```

---

## Qué hay en esta carpeta

| archivo | qué es |
|---|---|
| `719_final_gerencial.ipynb` | **la entrega.** Genera el submit elegido |
| `719_final_gerencial_1semilla.ipynb` | brazo de control del experimento propio |
| `BITACORA.md` | el registro completo: cada decisión con su evidencia, las cinco corridas y las reservas declaradas |

---

## Las decisiones de los Experimentos Colaborativos

De los 12 problemas, **siete** aplican al notebook Gerencial. Se leyó la
Recomendación Concreta de cada grupo y se comparó A contra B.

| # | problema | decisión | fuente |
|---|---|---|---|
| 01 | Catastrophe Analysis | sin cambios | **propio** (Grupo B) |
| 02 | Data Drifting | `rank_cero_fijo` | Grupo B |
| 03 | FE intra-mes | Experimento 2: Z-Score antes de los ratios | Grupo B |
| 04 | Training Strategy | sin cambios | Grupo A |
| 05 | FE histórico | sin cambios | Grupo A |
| 11 | HT, desbalanceo | sin cambios | Grupo A |
| 12 | Undersampling | `training_pct = 0.08` | Grupo B, adaptado |

**Cuatro de siete confirmaron el baseline de la cátedra.** Los tres que lo cambian
tienen su justificación en `BITACORA.md`; resumidas:

- **#02.** Los grupos se contradicen. Se siguió a B porque midió `rank_cero_fijo`
  ganándole a `estandarizar` —lo que recomienda A— en **10 de 10 semillas**, y
  porque la implementación de `estandarizar` de la cátedra tiene un bug fatal:
  `mean(campo)` en vez de `mean(get(campo))` deja **todas** las variables
  monetarias en `NA`.
- **#03.** A y B no midieron lo mismo, así que el nulo de A no refuta a B. El
  Experimento 2 de B midió `p = 0.0039` sobre 10 semillas, con la mediana pasando
  de 33.351 a 34.544.
- **#04 y #12** se adaptaron: las recomendaciones estaban calibradas para el
  dataset Junior, que tiene 29 meses de training contra los 14 del Gerencial.
  Aplicar el #04 literalmente habría dejado el final train en **7 meses**, por
  debajo del piso de la cátedra. Aplicar el `0.01` del #12 habría dejado el
  `dtrain` en **3.475** filas, por debajo de las 14.373 que B validó.

**La importancia de variables confirma las dos decisiones que cambian código.**
`z_ctrx_quarter` —del Experimento 2— es la variable más importante del modelo,
con **2,8 veces** el Gain de `ctrx_quarter`, la misma variable sin estandarizar y
compitiendo dentro del mismo modelo. Entre las 30 primeras hay 8 variables del #03
y cinco `_rank` del #02.

---

## El experimento propio

El PDF §6.15 prohíbe que juntar las conclusiones ajenas *sea* la entrega. Se
hicieron dos experimentos, y el segundo apareció sin buscarlo.

### 1. El semillerío — resultado **nulo**

**Hipótesis.** El experimento del Problema 01 y la conclusión del Problema 11
midieron lo mismo por caminos distintos: el ruido de la semilla explica lo que
parecía efecto del método. Si la semilla domina, promediar sobre semillas debería
rendir más que cualquier elección de método.

**Diseño.** Un 2×2 de semillas × desempate, cuatro corridas, midiendo la media de
los once cortes en el Public:

| | `ties = random` | `ties = average` |
|---|---|---|
| **1 semilla** | 20.631 | 18.072 |
| **10 semillas** | 21.161 | 17.693 |

| efecto | magnitud |
|---|---|
| desempate | **+3.01** |
| semillerío | **+0.08** |

**El semillerío no mueve la ganancia media.** Y lo que lo confirma no es el valor
sino la réplica: el efecto del desempate se midió dos veces, +2.56 y +3.47, mismo
signo; el del semillerío dio +0.53 y −0.38, **signos opuestos**.

**Pero sí replica un efecto en dispersión.** En los dos pares, el semillerío deja
la curva de cortes a la mitad de desvío:

| | desvío entre los 11 cortes |
|---|---|
| 10 semillas | 1.881 · 1.259 |
| 1 semilla | 5.529 · 2.082 |

No da más ganancia: da una ganancia que **depende menos de dónde se corte**. Con
el Private invisible y un solo corte para elegir, eso tiene valor práctico. Se
conservó por eso, no porque suba la media.

*Advertencia honesta:* los once cortes son subconjuntos anidados del mismo
ranking, no observaciones independientes. Ese desvío no es una varianza en sentido
estadístico, y no hay un error estándar confiable para las medias.

### 2. El hallazgo — el notebook de la cátedra no era reproducible

Buscando por qué el Grid Search daba resultados distintos entre corridas, se
encontró que `drift_rank_cero_fijo` —el código del Grupo B para el #02— usa

```r
frank(get(campo), ties.method = "random")
```

que consume azar del RNG de R, **sin ningún `set.seed` antes**. Era la única
fuente de azar sin fijar del workflow.

**Medido, no supuesto.** Dos corridas del mismo notebook en sesiones distintas:

| desempate | par | resultado |
|---|---|---|
| `"random"` | 7190 vs 7191 | **los 20 AUC distintos**; el ganador se dio vuelta de `(256, 64, 1228)` a `(128, 64, 350)` |
| `"average"` | 7290 vs 7291 | idénticos: `(256, 64, 246)` |
| `"first"` | 7390 vs verificación | idénticos: `(128, 64, 716)` |

**Lo que se aprendió de paso, y es lo más interesante.** En la corrida entregada,
los tres mejores AUC del nivel ganador son `0.946208`, `0.946173` y `0.946171`: el
Grid Search eligió `num_leaves = 128` sobre 256 por una diferencia de
**0.000035**. El ruido de desempate movía la misma combinación **0.0025**, setenta
veces más.

> **El ruido de reproducibilidad era mayor que la señal que el Grid Search busca
> discriminar.** Estaba eligiendo ruido.

Es la misma conclusión del Problema 01 —el ruido se come al efecto— reaparecida en
otra etapa del workflow.

**La corrección.** Se adoptó `ties.method = "first"`, que es determinista y reparte
rangos distintos. No se usó `"random"` con `set.seed` porque `frank` corre dentro
de `by = list(foto_mes)` y data.table puede procesar los grupos en paralelo: el
orden de consumo del RNG dependería de la cantidad de hilos. Probado en seco sobre
`entorno-ds:1.0`, con una columna de mucha masa repetida:

```
first     valores distintos: 2383     identico en dos sesiones
average   valores distintos:   13     identico en dos sesiones
random    valores distintos: 2383     NO identico
```

`"average"` colapsa la columna a trece niveles y el árbol casi no puede partir
sobre ella. Es un desvío declarado respecto del código del Grupo B.

**Costó ganancia, y se aceptó.** Las corridas con `"random"` promedian 21.16 en el
Public y la entregada 18.64. Se eligió entregar la reproducible: la métrica que se
sacrifica sale del **30 %** del test y se mueve ±5 puntos por azar —cortes que
comparten el 95 % de sus predicciones dieron scores separados por 5.2—, mientras
que la reproducibilidad es, en palabras del PDF, *"parte de la filosofía de la
materia"*.

---

## Por qué 950 envíos

La consigna (§5.6) advierte que el submit elegido no debería ser el de mayor
ganancia Public. Se eligió por robustez, no por pico:

```
suavizado con media movil de 3 puntos
 850  19.405
 900  19.460   <- maximo suavizado
 950  19.349
1000  19.210
1050  17.878
1100  16.573   <- el peor
1200  18.266
```

La zona robusta es **850–950**. Dentro de ella, 950 tiene el score crudo más alto
(20.570) y su valor suavizado es prácticamente igual al de 900.

Converge con una medición independiente: el óptimo de envíos del experimento del
Problema 01, sobre 202107 y con la clase conocida, cayó en **936**.

Se descartó `KA7390_1200`, que tiene un score alto (20.404) pero cuyo vecino de
1150 es el peor de la curva (15.240). Un pico sin sostén.

---

## Limitaciones declaradas

- **`min_data_in_leaf = 64` cayó en el borde inferior de la grilla en las cinco
  corridas**, con tres desempates distintos. El óptimo está probablemente por
  debajo de lo que la grilla explora. No se amplió la grilla: es la de la cátedra.
- **El Grid Search optimiza sobre un `dtrain` 12,1 veces más chico que el
  `dfinal_train`** (15.876 contra 192.651). `num_iterations` es el hiperparámetro
  que más depende de ese tamaño y sí pasa al modelo final. El Grupo B del #12 midió
  que aun así la ganancia no cae, pero a su escala, no a ésta.
- **`numero_de_cliente` quedó en el puesto 8 de importancia.** Está en
  `campos_buenos` por diseño de la cátedra —el `setdiff` sólo saca
  `clase_ternaria`, `clase01` y `azar`—, igual que `foto_mes`. Que un
  identificador aporte Gain significa que el modelo lee antigüedad codificada en
  el número.
- **El set de variables del Experimento 2 no está publicado.** La tabla del Grupo B
  es de importancia, no de definición. Se reconstruyeron los ratios que nombra,
  leyendo la convención del sufijo `_z`.
- **Se apilan dos correcciones de drift** —el `rank_cero_fijo` del #02 y los
  Z-Score del #03— y esa combinación no fue medida por nadie.
- **El mensaje de los submits dice `semilla=100043`** y es engañoso: sale de
  `PARAM$semilla_primigenia` en el código de la cátedra, pero el modelo es el
  promedio de diez semillas.
- **`"first"` asigna los rangos empatados en orden de `numero_de_cliente`**, que
  es lo que fija el `setorder`. Eso introduce una correlación sistemática con esa
  variable que `"random"` no introduce. Es una conjetura no medida sobre por qué
  `"first"` recupera sólo un tercio de la diferencia con `"random"`.

---

## Herramientas

R y LightGBM sobre Google Colab. Docker con R local (`entorno-ds:1.0`) para las
pruebas en seco. Git y GitHub para el versionado.

El trabajo se hizo **con asistencia de un LLM** (Claude), usado para generar y
depurar código, correr los análisis y redactar esta documentación. Las decisiones
—qué recomendación adoptar en cada problema, qué adaptar por el tamaño del
dataset, qué experimento propio hacer, y entregar la corrida reproducible en lugar
de la de mayor Public— se tomaron y se discutieron caso por caso, y están
registradas con su evidencia en `BITACORA.md`.
