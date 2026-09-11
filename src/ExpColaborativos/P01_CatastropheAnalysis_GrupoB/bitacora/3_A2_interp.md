# Bitácora — `A2_interp`

> **H2.** La mejora en la ganancia proviene de señalarle al modelo que el dato
> falta, no de reconstruir su valor.

**Estadística clásica: interpolación longitudinal**

| | |
|---|---|
| **orden de corrida** | 3 de 5 |
| **notebook** | `611_CA_A2_interp.ipynb` |
| **carpeta** | `/content/buckets/b1/exp/WF6320/` |
| **técnica de la cátedra** | Promedio de 202005 y 202007 del mismo cliente |
| **señala la ausencia** | ✗ |
| **reconstruye el valor** | ✓ |

## Por qué está este brazo

Reconstruye usando **la historia de la variable**. Es el brazo que aporta el eje «reconstruye» desde la fuente longitudinal.

## Qué se espera

Después de imputar no queda ninguna marca: el mes reparado es indistinguible de un mes sano. Si H2 es cierta, debería quedar más cerca de A0 que de A1, pese a haber «arreglado» los datos.

---

## Lo único que cambia respecto del workflow original

Esta es la celda de Catastrophe Analysis, textual del notebook:

```r
# =======================================================================
#  BRAZO A2 - ESTADISTICA CLASICA: interpolacion lineal longitudinal
#  senala: NO    reconstruye: SI
# =======================================================================
# Fuente de informacion: la HISTORIA DE LA VARIABLE en el mismo cliente.
# El valor de 202006 se reconstruye como el promedio de 202005 y 202007
# del mismo numero_de_cliente. Despues de imputar NO queda ninguna marca:
# el mes reparado es indistinguible de un mes sano.

# --- paso 1: abrir el hueco --------------------------------------------
for (vcol in PARAM$ca$variables) {
  dataset[foto_mes == 202006, (vcol) := NA]
}

# --- paso 2: medianas de 202005, como ultimo recurso -------------------
# para los clientes que no tienen ni 202005 ni 202007
ca_medianas <- dataset[foto_mes == 202005,
                       lapply(.SD, median, na.rm = TRUE),
                       .SDcols = PARAM$ca$variables]

# --- paso 3: interpolar -------------------------------------------------
setorder(dataset, numero_de_cliente, foto_mes)

# el mes vecino REAL de cada registro. No alcanza con shift(1): si un
# cliente no tiene 202005, shift devuelve 202004 o 202003 sin avisar.
dataset[, ca_mes_prev := shift(foto_mes, 1L, type = "lag"),  by = numero_de_cliente]
dataset[, ca_mes_next := shift(foto_mes, 1L, type = "lead"), by = numero_de_cliente]

for (vcol in PARAM$ca$variables) {

  dataset[, ca_prev := shift(get(vcol), 1L, type = "lag"),  by = numero_de_cliente]
  dataset[, ca_next := shift(get(vcol), 1L, type = "lead"), by = numero_de_cliente]

  # solo valen los vecinos que son EFECTIVAMENTE 202005 y 202007
  dataset[is.na(ca_mes_prev) | ca_mes_prev != 202005, ca_prev := NA]
  dataset[is.na(ca_mes_next) | ca_mes_next != 202007, ca_next := NA]

  mediana <- ca_medianas[[vcol]]

  dataset[foto_mes == 202006,
    (vcol) := fifelse(!is.na(ca_prev) & !is.na(ca_next), (ca_prev + ca_next) / 2,
              fifelse(!is.na(ca_prev), as.numeric(ca_prev),
              fifelse(!is.na(ca_next), as.numeric(ca_next), as.numeric(mediana))))
  ]
}

# --- paso 4: respetar el tipo de la variable ----------------------------
# el promedio de dos enteros puede dar 3.5; en un binario o un conteo
# eso es un valor imposible
for (vcol in c(PARAM$ca$binarias, PARAM$ca$conteos)) {
  dataset[foto_mes == 202006, (vcol) := round(get(vcol))]
}
dataset[foto_mes == 202006 & internet > 1, internet := 1]
dataset[foto_mes == 202006 & internet < 0, internet := 0]

dataset[, c("ca_mes_prev", "ca_mes_next", "ca_prev", "ca_next") := NULL]

cat("Brazo A2 - interpolacion longitudinal completa\n")
dataset[foto_mes == 202006,
        lapply(.SD, function(x) sum(is.na(x))),
        .SDcols = PARAM$ca$variables]
```

## Lo que NO cambia

Idéntico en los 5 brazos, y por eso las diferencias de ganancia son atribuibles
al tratamiento y no a otra cosa:

- FE intra-mes y **FE histórico** (lag1, lag2, delta1, delta2)
- Training strategy: `training = [202005, 202104]`, `validate = 202105`,
  `final_train = [202005, 202105]`, `training_pct = 1.0`
- `campos_buenos`
- **Hiperparámetros congelados**: `num_leaves = 256`, `min_data_in_leaf = 64`,
  `num_iterations = 428` (de `WF6390`, 2026-09-07, AUC val 0.9540665)
- `future = 202107`, métrica `ganancia_suavizada_max`
- Las 7 semillas y su orden

---

## Antes de correr

- [ ] Runtime de Colab en **R** (no Python 3) desde la celda 11 en adelante
- [ ] La celda 6 (`drive.mount`) y la 8 (`%%shell`) corridas en **Python 3**
- [ ] Los errores de `kaggle.json` en la celda 8 son esperables y no importan:
      el Grupo B no sube a Kaggle y el dataset baja por `wget`
- [ ] `PARAM$experimento` dice **6320**

## Mientras corre — qué mirar

| dónde | qué tiene que dar |
|---|---|
| `mrentabilidad` en 202006 | **0 NAs y 0 ceros** |
| Media de 202006 | entre la de 202005 y la de 202007 |
| `internet` en 202006 | sólo valores 0 y 1 — el redondeo del binario funcionó |
| Conteos en 202006 | enteros, sin decimales |
| Columnas auxiliares | `ninguna` — no quedaron `ca_prev`/`ca_next` colgadas |

Y en el loop de semillas, una línea por semilla con la hora, la
`ganancia_suavizada_max` y los `envios`. Son **7**.

---

## Resultados

Copiar de `resultados_A2_interp.txt`, o del `resultado$ganancia_suavizada_max` de
cada `PARAM_<semilla>.yml`.

| semilla | ganancia_suavizada_max | envios | duración | observaciones |
|---|---|---|---|---|
| 100043 | **30.8475** | 672 | 1m50s | peor del brazo |
| 200063 | 31.4450 | 1219 | 1m45s | |
| 300089 | 34.4300 | 840 | 1m46s | |
| 500069 | 32.0425 | **1371** | 1m45s | **máximo de envíos del experimento** |
| 700021 | **36.2950** | 948 | 1m46s | **mejor del experimento hasta acá** |
| 181219 | 33.5375 | 867 | 1m44s | |
| 410341 | 32.9025 | 733 | ~1m45s | |

- **Fecha de la corrida:** 2026-09-07, 23:11 → 23:24
- **Duración del loop:** ~12m15s (≈ 1m45s por semilla)
- **Tipo de runtime de Colab:**

### Estadística de las 7 semillas

| | A2 (interp) | A1 (`NA`) | A0 (ceros) |
|---|---|---|---|
| señala | **no** | **sí** | **no** |
| media | 33.0714 | 33.0939 | 32.7486 |
| desvío | **1.8767** | **0.5297** | **1.6285** |
| rango | 5.4475 | 1.3525 | 5.0850 |
| CV | 5.68 % | 1.60 % | 4.97 % |
| CV de envíos | **26.9 %** | 7.5 % | — |

### El resultado de este brazo, en una línea

**A2 y A1 tienen la misma ganancia media** —33.0714 contra 33.0939, diferencia de
**0.02**, Wilcoxon `p = 0.9375`— **pero A2 tiene 12.5 veces más varianza.**

Reconstruir los valores por interpolación no compró **nada** de ganancia media, y
costó multiplicar por 12 la dispersión entre semillas.

### Confirma la predicción registrada

Razón de varianzas A2/A1 = **12.55**. Pitman–Morgan: `t = 3.6523, df = 5,
p = 0.0147`.

Y a diferencia del caso A0, **este aguanta el leave-one-out**: sacando cualquier
semilla, la razón queda entre 7.06 y 18.83 y el `p` nunca sube de **0.0526**.

Ver [`CONTRASTE_1_A1_vs_A0.md`](CONTRASTE_1_A1_vs_A0.md) para la predicción y el
tablero completo.

## Incidencias

_Cortes de sesión, reintentos, warnings raros, cualquier cosa que se haya
salido del libreto._

-

## Archivos que quedaron en `WF6320/`

- [ ] `resultados_A2_interp.txt` — con **7 filas**
- [ ] `PARAM_<semilla>.yml` × 7
- [ ] `prediccion_<semilla>.txt` × 7
- [ ] `ganancias_<semilla>.txt` × 7
- [ ] `impo_<semilla>.txt` × 7
- [ ] `modelo_<semilla>.txt` × 7
- [ ] `curva_de_ganancia_<semilla>.pdf` × 7

## Conclusión de este brazo

_Una o dos frases, escritas al terminar. Todavía sin comparar con los otros._

-
