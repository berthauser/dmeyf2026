# Bitácora — `T4_gridsearch`  ✅ CORRIDO

**Grid Search único. Corre una sola vez, antes de los 5 brazos.**

| | |
|---|---|
| **notebook** | `611_CA_T4_gridsearch.ipynb` |
| **carpeta** | `/content/buckets/b1/exp/WF6390/` |
| **fecha** | 2026-09-07 |
| **semilla** | 100043 (la primera de las principales) |
| **brazo sobre el que corre** | A1 (`NA`), el baseline de la cátedra |

## Por qué se corre una sola vez

El Grid Search son ~60 minutos. Correrlo por brazo y por semilla serían 35
corridas de una hora. Pero el motivo principal **no** es el costo: si cada brazo
optimizara sus propios hiperparámetros, la diferencia de ganancia entre brazos
mezclaría el efecto del tratamiento con el efecto de haber caído en un punto
distinto de la grilla. Congelar es **más barato y más *ceteris paribus***.

## La grilla

```r
tb_nueva <- CJ(
  num_leaves       = c(64, 128, 256, 512),
  min_data_in_leaf = c(64, 256, 512, 1024, 2048)
)
```

20 combinaciones. Métrica optimizada: **AUC** en `validate = 202105`
— intencionalmente **no** la función de ganancia.

---

## Resultado

```r
PARAM$out$lgbm$mejores_hiperparametros <- list(
  num_leaves       = 256L,
  min_data_in_leaf = 64L,
  num_iterations   = 428L
)
# AUC en validation = 0.9540665
```

Ya pegados en los 5 notebooks de brazo.

### Dos lecturas

✅ **`num_iterations = 428` está lejos del techo de 2048.** El `early_stopping_rounds
= 200` frenó por sí solo, así que el óptimo no quedó cortado por arriba. Si
hubiera dado ~2048, el verdadero óptimo estaría fuera de lo explorado y el número
congelado no serviría.

⚠️ **`min_data_in_leaf = 64` es el valor más chico de la grilla.** Que el óptimo
caiga justo en el borde sugiere que el verdadero podría estar por debajo de 64,
fuera de lo explorado. **No se re-corre el grid**: los hiperparámetros estaban
declarados de antemano y cambiarlos después de ver el resultado rompería el
*ceteris paribus* entre brazos. **Va a Limitaciones.**

## Incidencias

- La celda 8 (`%%shell`) tiró `cp: cannot stat '.../kaggle.json'` y
  `chmod: cannot access ...`. **Sin consecuencias**: los dos datasets bajaron
  completos por `wget` desde GCS, y el Grupo B no usa la API de Kaggle (la
  métrica es local, `ganancia_suavizada_max`, porque con `future = 202107` el
  `clase_ternaria` es conocido). El script no tiene `set -e`, así que siguió.
- También se descargó `dataset_pequeno.csv` (160 MB), que este workflow no usa.
  Sólo ocupa lugar en el Drive.

## Archivos en `WF6390/`

- [x] `tb_grid_search_01.txt` — las 20 combinaciones con su AUC
- [x] `PARAM_gridsearch.yml`

## Celdas que tardan

| celda | qué hace | cuánto |
|---|---|---|
| **59** | **el Grid Search, 20 combinaciones** | **~60 min** |
| 47 | `dtrain`: `data.matrix` + `lgb.Dataset` | ~8 min |
| 35 | FE histórico | varios min |
| 22 | `fread` del dataset | 1–2 min |

Las celdas **47, 48 y 59 son exactamente las que los 5 brazos NO ejecutan**.
Esta hora se paga una sola vez.
