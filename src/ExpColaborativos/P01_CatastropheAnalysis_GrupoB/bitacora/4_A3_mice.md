# Bitácora — `A3_mice`

> **H2.** La mejora en la ganancia proviene de señalarle al modelo que el dato
> falta, no de reconstruir su valor.

**MICE**

| | |
|---|---|
| **orden de corrida** | 4 de 5 |
| **notebook** | `611_CA_A3_mice.ipynb` |
| **carpeta** | `/content/buckets/b1/exp/WF6330/` |
| **técnica de la cátedra** | Multivariate Imputation by Chained Equations, `pmm`, m=1, maxit=3 |
| **señala la ausencia** | ✗ |
| **reconstruye el valor** | ✓ |

## Por qué está este brazo

Reconstruye usando **otras variables del mismo mes**. Es la fuente transversal, y es lo que lo distingue de A2.

## Qué se espera

Es la técnica más sofisticada de las cuatro de la cátedra. Si H2 es cierta, va a perder igual contra el `NA` de A1 — y ese es el resultado interesante, no el ranking.

---

## Lo único que cambia respecto del workflow original

Esta es la celda de Catastrophe Analysis, textual del notebook:

```r
# =======================================================================
#  BRAZO A3 - MICE  (Multivariate Imputation by Chained Equations)
#  senala: NO    reconstruye: SI
# =======================================================================
# Fuente de informacion: OTRAS VARIABLES DEL MISMO MES en el mismo
# registro. Es informacion transversal, y eso es lo que lo distingue de
# la interpolacion de A2.
#
# NOTA METODOLOGICA IMPORTANTE
# En 202006 las 12 variables estan rotas para el 100% de los registros.
# MICE necesita filas donde la variable SI se observa para poder estimar
# el modelo de imputacion: con solo 202006 no hay nada de donde aprender.
# Por eso el input incluye filas DONANTES de los meses vecinos sanos.
# Esto hay que declararlo en Limitaciones.

if (!require("mice")) install.packages("mice")
require("mice")

PARAM$ca$mice_donantes_meses <- c(202005, 202007)
PARAM$ca$mice_donantes_n     <- 40000   # filas donantes POR MES
PARAM$ca$mice_m              <- 1       # una sola imputacion completa
PARAM$ca$mice_maxit          <- 3
PARAM$ca$mice_method         <- "pmm"   # pmm devuelve valores observados:
                                        # respeta binarios y conteos solo

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

cat("Brazo A3 - MICE completo\n")
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
- [ ] `PARAM$experimento` dice **6330**

## Mientras corre — qué mirar

| dónde | qué tiene que dar |
|---|---|
| Instalación de `mice` | arrastra `nloptr`/`lme4`, que **compilan**. Minutos. No se colgó |
| «Predictores elegidos para MICE» | una lista de 25 nombres de columnas reales |
| «input de mice: N filas x M columnas» | N ≈ 80.000 donantes + los registros de 202006 |
| `mrentabilidad` en 202006 | **0 NAs y 0 ceros** |
| `internet` en 202006 | sólo 0 y 1 — `pmm` devuelve valores observados |
| Columnas totales tras el FE histórico | el mismo número que A0, A1 y A2 |

Y en el loop de semillas, una línea por semilla con la hora, la
`ganancia_suavizada_max` y los `envios`. Son **7**.

---

## Resultados

Copiar de `resultados_A3_mice.txt`, o del `resultado$ganancia_suavizada_max` de
cada `PARAM_<semilla>.yml`.

| semilla | ganancia_suavizada_max | envios | duración | observaciones |
|---|---|---|---|---|
| 100043 | 32.7750 | 718 | 1m44s | |
| 200063 | **32.3575** | 881 | 1m40s | peor del brazo |
| 300089 | 33.1100 | 842 | 1m39s | |
| 500069 | 33.4075 | 882 | 1m39s | |
| 700021 | 32.5300 | 860 | 1m39s | |
| 181219 | 34.3725 | 853 | 1m41s | |
| 410341 | **36.0450** | 931 | ~1m40s | **z = +1.94 — sostiene sola el efecto de varianza** |

- **Fecha de la corrida:** 2026-09-07, 23:51 → 00:03
- **Duración del loop:** ~11m40s (≈ 1m40s por semilla)
- **Tipo de runtime de Colab:**

### Estadística

| | A3 (MICE) | A1 (`NA`) |
|---|---|---|
| señala | no | **sí** |
| media | 33.5139 | 33.0939 |
| desvío | **1.3019** | **0.5297** |
| razón de varianzas | **6.04** | — |
| CV de envíos | 7.7 % | 7.5 % |

### Contraste 2 (declarado) — A3 vs A1

**H2 predecía A3 < A1.**

```
Wilcoxon signed rank exact test
V = 16, p-value = 0.8125
```

Diferencia de medias: **+0.4200**, es decir **A3 salió más alto que A1**. A3 gana
en 4 de 7. No es significativo, pero el estimador puntual va en **dirección
opuesta** a la que H2 predecía.

**Segundo contraste declarado, segundo nulo.**

### La predicción de varianza: acá se debilita

Razón 6.04, pero Pitman–Morgan `p = 0.0704` — **no llega a 0.05**.

Y el leave-one-out es el problema:

| sin la semilla | razón | p |
|---|---|---|
| (ninguna) | 6.04 | 0.0704 |
| 300089 | 9.90 | 0.0463 |
| 200063 | 6.63 | 0.0886 |
| 700021 | 7.09 | 0.0804 |
| 500069 | 6.31 | 0.1021 |
| 181219 | 6.17 | 0.1049 |
| 100043 | 5.80 | 0.1165 |
| **410341** | **1.83** | **0.4700** |

Sin `410341`, A3 es **casi tan estable como A1** (razón 1.83). El efecto lo
sostiene una sola semilla — igual que pasaba con A0, y a diferencia de A2.

### Corrección respecto de lo dicho tras A2

La inestabilidad de **envíos** no es una propiedad general de los brazos que no
señalan: A3 da **7.7 %**, prácticamente igual que A1 (7.5 %). El 26.9 % de A2 es
**específico de la interpolación**, no del eje «señala».

## Incidencias

_Cortes de sesión, reintentos, warnings raros, cualquier cosa que se haya
salido del libreto._

-

## Archivos que quedaron en `WF6330/`

- [ ] `resultados_A3_mice.txt` — con **7 filas**
- [ ] `PARAM_<semilla>.yml` × 7
- [ ] `prediccion_<semilla>.txt` × 7
- [ ] `ganancias_<semilla>.txt` × 7
- [ ] `impo_<semilla>.txt` × 7
- [ ] `modelo_<semilla>.txt` × 7
- [ ] `curva_de_ganancia_<semilla>.pdf` × 7

## Conclusión de este brazo

_Una o dos frases, escritas al terminar. Todavía sin comparar con los otros._

-
