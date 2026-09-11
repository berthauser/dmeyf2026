# Bitácora — `A4_mice_flag`

> **H2.** La mejora en la ganancia proviene de señalarle al modelo que el dato
> falta, no de reconstruir su valor.

**MICE + flag  ←  LA CELDA VACÍA**

| | |
|---|---|
| **orden de corrida** | 5 de 5 |
| **notebook** | `611_CA_A4_mice_flag.ipynb` |
| **carpeta** | `/content/buckets/b1/exp/WF6340/` |
| **técnica de la cátedra** | Idéntico a A3, más la columna indicadora `ca_reparado` |
| **señala la ausencia** | ✓ |
| **reconstruye el valor** | ✓ |

## Por qué está este brazo

**Es el brazo que justifica todo el experimento.** Es la celda del 2×2 que nadie ocupa. Sin ella, una derrota de MICE contra `NA` confunde «reconstruir no sirve» con «imputar destruyó la señal de ausencia». Con ella, las dos cosas se separan.

## Qué se espera

Misma imputación que A3, misma semilla de datos, mismos hiperparámetros. Lo único que cambia es una columna. Si A4 le gana a A3, lo que aporta es **señalar**, no el valor.

---

## Lo único que cambia respecto del workflow original

Esta es la celda de Catastrophe Analysis, textual del notebook:

```r
# =======================================================================
#  BRAZO A4 - MICE + FLAG   <<< LA CELDA VACIA DEL 2x2 >>>
#  senala: SI    reconstruye: SI
# =======================================================================
# Identico a A3 en la imputacion. La UNICA diferencia es la columna
# indicadora del final. Por eso el contraste A3 vs A4 aisla exactamente
# el efecto de senalar, con el valor reconstruido constante.

if (!require("mice")) install.packages("mice")
require("mice")

PARAM$ca$mice_donantes_meses <- c(202005, 202007)
PARAM$ca$mice_donantes_n     <- 40000
PARAM$ca$mice_m              <- 1
PARAM$ca$mice_maxit          <- 3
PARAM$ca$mice_method         <- "pmm"

# --- paso 1: abrir el hueco --------------------------------------------
for (vcol in PARAM$ca$variables) {
  dataset[foto_mes == 202006, (vcol) := NA]
}

# --- paso 2: elegir predictores EN RUNTIME ------------------------------
# No hardcodeo nombres de columnas: me quedo con las numericas completas
# y de esas con las 25 mas correlacionadas con alguna variable rota,
# medido en 202005 (un mes sano).
ca_candidatos <- setdiff(colnames(dataset),
                         c("numero_de_cliente", "foto_mes", "clase_ternaria",
                           PARAM$ca$variables))

ca_candidatos <- ca_candidatos[
  vapply(ca_candidatos,
         function(v) is.numeric(dataset[[v]]) && !anyNA(dataset[[v]]),
         logical(1)) ]

sub05 <- dataset[foto_mes == 202005,
                 c(PARAM$ca$variables, ca_candidatos), with = FALSE]

cm <- suppressWarnings(cor(sub05, use = "pairwise.complete.obs"))
fuerza <- apply(abs(cm[ca_candidatos, PARAM$ca$variables, drop = FALSE]),
                1, max, na.rm = TRUE)
fuerza[!is.finite(fuerza)] <- 0

PARAM$ca$mice_predictores <- names(sort(fuerza, decreasing = TRUE))[
    seq_len(min(25, length(fuerza))) ]

cat("Predictores elegidos para MICE:\n")
print(PARAM$ca$mice_predictores)

rm(sub05, cm); gc(full = TRUE, verbose = FALSE)

# --- paso 3: armar el input de mice -------------------------------------
set.seed(PARAM$semilla_datos, kind = "L'Ecuyer-CMRG")

idx_junio <- dataset[, which(foto_mes == 202006)]
idx_don   <- dataset[, which(foto_mes %in% PARAM$ca$mice_donantes_meses)]

n_max <- PARAM$ca$mice_donantes_n * length(PARAM$ca$mice_donantes_meses)
if (length(idx_don) > n_max) idx_don <- sort(sample(idx_don, n_max))

cols_mice <- c(PARAM$ca$variables, PARAM$ca$mice_predictores)
tb_mice <- as.data.frame(dataset[c(idx_don, idx_junio), ..cols_mice])

cat("input de mice:", nrow(tb_mice), "filas x", ncol(tb_mice), "columnas",
    " (", length(idx_don), "donantes +", length(idx_junio), "de 202006 )\n")

# --- paso 4: correr mice ------------------------------------------------
pred <- make.predictorMatrix(tb_mice)
pred[PARAM$ca$mice_predictores, ] <- 0   # los completos no se imputan
diag(pred) <- 0                          # nadie se predice a si mismo

meth <- make.method(tb_mice)
meth[] <- ""
meth[PARAM$ca$variables] <- PARAM$ca$mice_method

imp <- mice(tb_mice,
            m              = PARAM$ca$mice_m,
            maxit          = PARAM$ca$mice_maxit,
            method         = meth,
            predictorMatrix = pred,
            seed           = PARAM$semilla_datos,
            printFlag      = TRUE)

tb_completo <- as.data.table(complete(imp, 1))

# --- paso 5: devolver SOLO las filas de 202006 --------------------------
n_don <- length(idx_don)
filas_junio <- (n_don + 1L):nrow(tb_completo)
stopifnot(length(filas_junio) == length(idx_junio))

for (vcol in PARAM$ca$variables) {
  set(dataset, i = idx_junio, j = vcol, value = tb_completo[[vcol]][filas_junio])
}

rm(tb_mice, tb_completo, imp); gc(full = TRUE, verbose = FALSE)

# --- paso 6: LA COLUMNA QUE SENALA -------------------------------------
# Se crea ACA, antes del Feature Engineering historico (celda 35), y eso
# es deliberado: la 35 le va a generar lag1 / lag2 / delta1 / delta2, y
# por esos lags la senal llega tambien a 202007 y 202008, que es donde
# foto_mes ya NO delata la contaminacion.
dataset[, ca_reparado := as.integer(foto_mes == 202006)]

cat("Brazo A4 - MICE + flag completo\n")
cat("ca_reparado == 1 en", dataset[ca_reparado == 1, .N], "registros\n")

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
- [ ] `PARAM$experimento` dice **6340**

## Mientras corre — qué mirar

| dónde | qué tiene que dar |
|---|---|
| Todo lo de A3 | ídem |
| «FLAG ca_reparado presente» | ==1 en exactamente los registros de 202006 |
| Columnas totales tras el FE histórico | **5 más** que los otros brazos: `ca_reparado` + lag1 + lag2 + delta1 + delta2 |

Y en el loop de semillas, una línea por semilla con la hora, la
`ganancia_suavizada_max` y los `envios`. Son **7**.

---

## Resultados

Copiar de `resultados_A4_mice_flag.txt`, o del `resultado$ganancia_suavizada_max` de
cada `PARAM_<semilla>.yml`.

| semilla | ganancia_suavizada_max | envios | duración | observaciones |
|---|---|---|---|---|
| 100043 | 34.1550 | 869 | 1m01s | |
| 200063 | **34.6575** | 750 | 0m56s | mejor del brazo |
| 300089 | 33.1725 | 763 | 0m55s | |
| 500069 | 33.4175 | 931 | 0m56s | |
| 700021 | **30.4725** | 817 | 0m57s | **peor del experimento** |
| 181219 | 32.0775 | 974 | 0m55s | |
| 410341 | 32.7000 | 847 | ~0m56s | z = −0.18, acá no fue extrema |

- **Fecha de la corrida:** 2026-09-08, 00:28 → 00:35
- **Duración del loop:** ~6m40s (≈ 57s por semilla)
- **Tipo de runtime de Colab:**

### Estadística

| | A4 (MICE+flag) | A3 (MICE) | A1 (`NA`) |
|---|---|---|---|
| señala | **sí** | no | **sí** |
| media | 32.9504 | 33.5139 | 33.0939 |
| desvío | **1.3903** | **1.3019** | **0.5297** |

---

## Contraste 3 — el decisivo — A4 vs A3

**H2 predecía A4 > A3.** A3 y A4 comparten imputación MICE, semilla de datos e
hiperparámetros; sólo los separa `ca_reparado`.

```
Wilcoxon signed rank exact test
V = 16, p-value = 0.8125
```

Diferencia de medias: **−0.5636**. A4 salió **más bajo** que A3, y gana en 4 de 7.
**Nulo, y en dirección opuesta a la predicha.**

## Contraste 4 — A4 vs A1

`p = 1.0000`, diferencia de medias −0.1436. **H2 predecía A4 ≈ A1, y eso sí se
cumple** — pero como los otros tres contrastes también son nulos, no distingue nada.

## La predicción registrada de varianza: FALLA

Se había registrado, antes de correr A2/A3/A4, que los brazos que **señalan**
(A1, A4) tendrían menor varianza que los que no (A0, A2, A3).

| brazo | señala | desvío |
|---|:--:|---|
| `A1_na` | **sí** | **0.5297** |
| `A3_mice` | no | 1.3019 |
| `A4_mice_flag` | **sí** | **1.3903** |
| `A0_cero` | no | 1.6285 |
| `A2_interp` | no | 1.8767 |

**A4 señala y NO es estable.** Razón de varianzas A4/A3 = **1.14**,
Pitman–Morgan `p = 0.887`. El flag no hace absolutamente nada sobre la
dispersión, con todo lo demás idéntico.

La predicción se cae en su prueba más limpia.

## Incidencias

_Cortes de sesión, reintentos, warnings raros, cualquier cosa que se haya
salido del libreto._

-

## Archivos que quedaron en `WF6340/`

- [ ] `resultados_A4_mice_flag.txt` — con **7 filas**
- [ ] `PARAM_<semilla>.yml` × 7
- [ ] `prediccion_<semilla>.txt` × 7
- [ ] `ganancias_<semilla>.txt` × 7
- [ ] `impo_<semilla>.txt` × 7
- [ ] `modelo_<semilla>.txt` × 7
- [ ] `curva_de_ganancia_<semilla>.pdf` × 7

## Conclusión de este brazo

_Una o dos frases, escritas al terminar. Todavía sin comparar con los otros._

-
