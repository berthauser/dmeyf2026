# Bitácora — `A1_na`

> **H2.** La mejora en la ganancia proviene de señalarle al modelo que el dato
> falta, no de reconstruir su valor.

**Machine Learning: asignación de NA**

| | |
|---|---|
| **orden de corrida** | 1 de 5 |
| **notebook** | `611_CA_A1_na.ipynb` |
| **carpeta** | `/content/buckets/b1/exp/WF6310/` |
| **técnica de la cátedra** | «Anti imputación» — se asigna `NA`, no se reconstruye nada |
| **señala la ausencia** | ✓ |
| **reconstruye el valor** | ✗ |

## Por qué está este brazo

Es el baseline que trae el notebook de la cátedra. Todo se mide contra esto. Además es la corrida de calibración: de acá sale cuánto tarda una sesión de brazo con las 7 semillas.

## Qué se espera

LightGBM aprende una dirección por defecto para el `NA` en cada split. Si H2 es cierta, esto solo —sin reconstruir un solo valor— ya debería ganarle a A0.

---

## Lo único que cambia respecto del workflow original

Esta es la celda de Catastrophe Analysis, textual del notebook:

```r
# =======================================================================
#  BRAZO A1 - MACHINE LEARNING: asignacion de NA  (baseline de la catedra)
#  senala: SI    reconstruye: NO
# =======================================================================
# La "anti imputacion". No se reconstruye ningun valor: se le dice al
# modelo que el dato no esta. LightGBM aprende una direccion por defecto
# para el NA en cada split.
#
# Es identico a la celda 25 original del workflow, escrito como loop.
# (el original repetia chomebanking_transacciones dos veces; era inocuo)

for (vcol in PARAM$ca$variables) {
  dataset[foto_mes == 202006, (vcol) := NA]
}

cat("Brazo A1 - NA asignado a", length(PARAM$ca$variables), "variables en 202006\n")

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
- [ ] `PARAM$experimento` dice **6310**

## Mientras corre — qué mirar

| dónde | qué tiene que dar |
|---|---|
| La celda del brazo imprime una tabla de conteos de NA | **todos iguales** entre sí y al número de registros de 202006 |
| Columnas totales tras el FE histórico | el mismo número que A0, A2 y A3 |

Y en el loop de semillas, una línea por semilla con la hora, la
`ganancia_suavizada_max` y los `envios`. Son **7**.

---

## Resultados

Copiar de `resultados_A1_na.txt`, o del `resultado$ganancia_suavizada_max` de
cada `PARAM_<semilla>.yml`.

| semilla | ganancia_suavizada_max | envios | duración | observaciones |
|---|---|---|---|---|
| 100043 | 33.2825 | 936 | 2m04s | |
| 200063 | 32.5200 | 885 | 1m58s | mínimo de envíos entre los altos |
| 300089 | **33.8550** | **738** | 1m57s | **mejor ganancia con la menor cantidad de envíos** |
| 500069 | 33.3450 | 862 | 1m55s | |
| 700021 | **32.5025** | 890 | 1m58s | peor ganancia |
| 181219 | 33.4800 | 921 | 1m57s | |
| 410341 | 32.6725 | 904 | ~1m57s | |

- **Fecha de la corrida:** 2026-09-07, 21:32 → 21:46
- **Duración del loop de semillas:** ~13m50s (≈ 1m58s por semilla)
- **Tipo de runtime de Colab:**

### Estadística de las 7 semillas

| | ganancia | envíos |
|---|---|---|
| media | 33.0939 | 876.6 |
| mediana | 33.2825 | 890 |
| desvío | **0.5297** | 65.7 |
| mín – máx | 32.5025 – 33.8550 | 738 – 936 |
| rango | 1.3525 | 198 |
| **CV** | **1.60 %** | **7.50 %** |

### Tres lecturas

**1. La semilla mueve el resultado, y no hay bug.** Las 7 ganancias son
distintas. Si hubieran salido idénticas, `param_final$seed` no estaría llegando
al LightGBM.

**2. El desvío de 0.53 NO es la vara para el experimento.** Es el ruido
*sin aparear*. El Wilcoxon es **pareado por semilla**: compara A1 vs A0 usando la
misma semilla en los dos brazos, y sólo mira el **signo** de las 7 diferencias.
Si un brazo le gana al otro en las 7 semillas, `p = 0.0156` sea la diferencia de
2 puntos o de 0.05. Lo que importa no es cuán grande sea la diferencia, sino cuán
**consistente**. La vara real es el desvío de las *diferencias pareadas*, y ese
número recién se puede calcular cuando esté A0.

**3. Los envíos son 5 veces más ruidosos que la ganancia** (CV 7.50 % contra
1.60 %). El caso extremo es la semilla 300089: da la **mejor** ganancia con
**738** envíos, casi 200 menos que la 100043, que gana 0.57 menos. Es la
**meseta**: cerca del óptimo la curva de ganancia es tan plana que el punto de
corte se mueve muchísimo mientras el valor casi no cambia. Buen material para las
diapositivas, y conecta con lo que ya venías viendo sobre el corte y la semilla.

## Incidencias

_Cortes de sesión, reintentos, warnings raros, cualquier cosa que se haya
salido del libreto._

-

## Archivos que quedaron en `WF6310/`

- [ ] `resultados_A1_na.txt` — con **7 filas**
- [ ] `PARAM_<semilla>.yml` × 7
- [ ] `prediccion_<semilla>.txt` × 7
- [ ] `ganancias_<semilla>.txt` × 7
- [ ] `impo_<semilla>.txt` × 7
- [ ] `modelo_<semilla>.txt` × 7
- [ ] `curva_de_ganancia_<semilla>.pdf` × 7

## Conclusión de este brazo

_Una o dos frases, escritas al terminar. Todavía sin comparar con los otros._

-
