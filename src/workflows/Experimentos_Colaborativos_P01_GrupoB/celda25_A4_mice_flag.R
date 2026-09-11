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