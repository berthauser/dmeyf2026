# Experimento H2 — Catastrophe Analysis — Grupo B

> **H2.** La mejora en la ganancia proviene de señalarle al modelo que el dato
> falta, no de reconstruir su valor.

Ernesto A. Zapata Icart · Grupo B · `future = 202107` · entrega **martes 15-sep-2026 23:59:59**

---

## Orden de ejecución

| # | notebook | cuándo | dura |
|---|---|---|---|
| 1 | `611_CA_T4_gridsearch.ipynb` | **primero, una sola vez** | ~70 min |
| 2 | `611_CA_A0_cero.ipynb` | después de pegar los hiperparámetros | ~1 sesión |
| 3 | `611_CA_A1_na.ipynb` | ídem | ~1 sesión |
| 4 | `611_CA_A2_interp.ipynb` | ídem | ~1 sesión |
| 5 | `611_CA_A3_mice.ipynb` | ídem | ~1 sesión + MICE |
| 6 | `611_CA_A4_mice_flag.ipynb` | ídem | ~1 sesión + MICE |
| 7 | `611_CA_T7_analisis.ipynb` | cuando estén los 5 | minutos |

**Una sesión de Colab por brazo.** El preprocesado pesado (lectura + CA + FE
histórico) corre 5 veces, no 35: dentro de cada notebook las 7 semillas comparten
el mismo `dataset`, `dfinal_train` y `dfuture`.

### Hiperparámetros congelados — YA CARGADOS

T4 corrió el **2026-09-07** (`WF6390`, semilla 100043) y dio:

```r
PARAM$out$lgbm$mejores_hiperparametros <- list(
  num_leaves       = 256L,
  min_data_in_leaf = 64L,
  num_iterations   = 428L
)
# AUC en validation = 0.9540665
```

Ya están pegados en los 5 notebooks de brazo. No hay que tocar nada.

`num_iterations = 428` está lejos del techo de 2048, así que el early stopping
frenó por sí solo: el óptimo no quedó cortado por arriba.

**Nota para Limitaciones:** `min_data_in_leaf = 64` es el valor **más chico de la
grilla** (64, 256, 512, 1024, 2048). Que el óptimo caiga en el borde sugiere que
podría estar por debajo de 64, fuera de lo explorado. No se re-corre el grid: los
hiperparámetros estaban declarados de antemano y cambiarlos ahora rompería el
*ceteris paribus* entre brazos.

---

## Los 5 brazos

Lo único que cambia entre ellos es la celda de Catastrophe Analysis.

| brazo | tratamiento | señala | reconstruye | `WF` |
|---|---|:--:|:--:|---|
| `A0_cero` | ninguno, deja los ceros | ✗ | ✗ | 6300 |
| `A1_na` | asignar `NA` (baseline cátedra) | ✓ | ✗ | 6310 |
| `A2_interp` | interpolación longitudinal | ✗ | ✓ | 6320 |
| `A3_mice` | MICE (transversal) | ✗ | ✓ | 6330 |
| `A4_mice_flag` | MICE + `ca_reparado` | ✓ | ✓ | 6340 |

`A4` es **la celda vacía del 2×2**: la que nadie ocupa y sin la cual una derrota
de MICE contra `NA` confunde «reconstruir no sirve» con «imputar destruyó la
señal de ausencia».

`A3` y `A4` comparten imputación, semilla de datos e hiperparámetros. Lo único
que los separa es la columna `ca_reparado`. Por eso **A4 vs A3 es el contraste
decisivo**.

---

## Semillas

```
principales   100043  200063  300089  500069  700021
reserva (2)   181219  410341
```

Las 7 se usan en los 5 brazos. Quedan sin usar, por si hace falta:
`568723 618347 831781 389437 547271 711649 888769 590323`.

**Por qué 7 y no 5.** El Wilcoxon pareado de signos tiene un piso combinatorio:
el p-value más chico posible es `2 / 2^n` a dos colas.

| n | p mínimo |
|---|---|
| 5 | 0.0625 — **nunca llega a 0.05** |
| 6 | 0.03125 |
| 7 | 0.0156 |

Con 5 semillas, aunque las 5 diferencias fueran en la misma dirección, el test
no puede reportar significancia a dos colas.

---

## Qué deja cada corrida

En `/content/buckets/b1/exp/WF####/`, una copia por semilla:

```
modelo_<semilla>.txt              el modelo LightGBM
impo_<semilla>.txt                importancia de variables
prediccion_<semilla>.txt          probabilidades sobre 202107
ganancias_<semilla>.txt           la curva de ganancia completa
curva_de_ganancia_<semilla>.pdf   el gráfico
PARAM_<semilla>.yml               <<< la ganancia a reportar
resultados_<brazo>.txt            acumulador, una fila por semilla
```

La métrica es `resultado$ganancia_suavizada_max` del `PARAM_<semilla>.yml`.

El acumulador se reescribe **después de cada semilla**, no al final: si Colab se
desconecta en la semilla 5, las 4 anteriores ya están guardadas y se puede
retomar acortando `PARAM$semillas`.

---

## Cambios respecto del workflow original

1. **Se saltean las celdas 46–62** (`dtrain`, `dvalidate`, grid search). Con
   `training_pct = 1.0` y `runif ∈ [0,1)`, la condición `azar < 1.0` es siempre
   verdadera: el undersampling es un no-op. Además `azar` está excluido de
   `campos_buenos`. `dtrain` sólo alimentaba el Grid Search, y el modelo final no
   lo usa. Ahorra 8 min + 60 min por corrida sin cambiar un solo resultado.
2. **Hiperparámetros congelados** del baseline, iguales en los 5 brazos. Es más
   barato y más *ceteris paribus*: si cada brazo optimizara los suyos, la
   diferencia de ganancia mezclaría el tratamiento con el punto de la grilla.
3. **Loop de 7 semillas** sobre final train + scoring. `dataset`, `dfinal_train` y
   `dfuture` se construyen una vez y no se tocan.
4. La celda 25 original repetía `chomebanking_transacciones` dos veces. Acá las
   12 variables están una sola vez (era inocuo).

---

## Limitaciones a declarar

- Hiperparámetros congelados del baseline, no re-optimizados por brazo.
- `A4` tiene **5 columnas más** que los otros brazos (`ca_reparado` y sus
  lag1/lag2/delta1/delta2), así que no es dimensionalmente idéntico.
- La imputación usa una semilla propia y fija (`999983`) y **no varía** entre las
  7 corridas: la varianza medida es sólo la del LightGBM, no la de la imputación.
- **MICE necesita filas donantes de meses vecinos.** En 202006 las 12 variables
  están rotas para el 100% de los registros, así que con sólo ese mes no hay nada
  de donde estimar el modelo de imputación. El input incluye hasta 40.000 filas
  por mes de 202005 y 202007.
- Los predictores de MICE se eligen **en runtime** (las 25 numéricas completas más
  correlacionadas con alguna variable rota, medido en 202005), no por una lista
  fija de nombres.
- `foto_mes` está dentro de `campos_buenos`: el modelo **ya podía** aislar 202006
  con un split. El `NA` no es la única forma de señalar, es la más barata — la
  señal viaja en la misma columna en vez de costar un split aparte. Donde el flag
  **no** es redundante es en los lags y deltas de 202007 y 202008, calculados en
  la celda 35, donde `foto_mes` ya no delata la contaminación.
- Las ganancias del Grupo A (`future = 202109`, Kaggle) y las del Grupo B
  (`future = 202107`, local) **no son comparables entre sí**.

---

## Verificación local hecha antes de entregar

Sobre `entorno-ds:1.0` (R 4.6.1) con un dataset sintético que imita la estructura
del gerencial, extrayendo las celdas **reales** de estos notebooks:

- `A0`, `A1`, `A2` corren de punta a punta, incluido el loop de LightGBM, con
  **0 errores**.
- `A2` deja 202006 sin NAs ni ceros y con media entre 202005 y 202007;
  `internet` sigue siendo 0/1 y los conteos siguen enteros.
- `dfinal_train` se **reusa** en los 7 entrenamientos sin que salte el
  `free_raw_data`; el `tryCatch` de respaldo nunca se disparó.
- El flag de `A4` se propaga: `ca_reparado_lag1` marca 202007 y
  `ca_reparado_lag2` marca 202008, y las 5 columnas entran a `campos_buenos`.
- Los 3 brazos terminan con el **mismo número de columnas**: el espacio de
  features es idéntico salvo por el flag de A4.

Aviso menor: `frollmean(..., hasNA=)` tira un warning de deprecación en
data.table nuevo (`use has.nf instead`). Viene de la celda 81 **original** de la
cátedra; es sólo un warning y no cambia el resultado, por eso se dejó igual.
