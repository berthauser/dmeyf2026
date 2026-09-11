# Bitácora — `A0_cero`

> **H2.** La mejora en la ganancia proviene de señalarle al modelo que el dato
> falta, no de reconstruir su valor.

**Ningún tratamiento**

| | |
|---|---|
| **orden de corrida** | 2 de 5 |
| **notebook** | `611_CA_A0_cero.ipynb` |
| **carpeta** | `/content/buckets/b1/exp/WF6300/` |
| **técnica de la cátedra** | Ninguna — se dejan los ceros como vienen |
| **señala la ausencia** | ✗ |
| **reconstruye el valor** | ✗ |

## Por qué está este brazo

Es el piso. Sin él no hay forma de decir cuánto vale *cualquier* tratamiento: es el único brazo donde el daño queda intacto.

## Qué se espera

El cero es un valor real, plausible y falso. El modelo no puede distinguirlo de un cero legítimo, así que aprende de datos envenenados sin saberlo. Debería ser el peor o cerca.

---

## Lo único que cambia respecto del workflow original

Esta es la celda de Catastrophe Analysis, textual del notebook:

```r
# =======================================================================
#  BRAZO A0 - NINGUN TRATAMIENTO
#  senala: NO    reconstruye: NO
# =======================================================================
# Las 12 variables de 202006 quedan tal como vienen del origen: en CERO.
# El cero es un valor real, plausible y falso: el modelo no tiene forma
# de distinguirlo de un cero legitimo. Esta celda NO modifica el dataset.

cat("Brazo A0 - sin tratamiento.\n")
cat("Variables afectadas que quedan en cero:", length(PARAM$ca$variables), "\n")

# verificacion: confirmo que efectivamente estan en cero en 202006
dataset[foto_mes == 202006,
        lapply(.SD, function(x) sum(x != 0, na.rm = TRUE)),
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
- [ ] `PARAM$experimento` dice **6300**

## Mientras corre — qué mirar

| dónde | qué tiene que dar |
|---|---|
| La celda del brazo imprime una tabla de conteos | **todos 0** — confirma que las 12 variables están efectivamente en cero en 202006 |
| Columnas totales tras el FE histórico | el mismo número que A1, A2 y A3 |

Y en el loop de semillas, una línea por semilla con la hora, la
`ganancia_suavizada_max` y los `envios`. Son **7**.

---

## Resultados

Copiar de `resultados_A0_cero.txt`, o del `resultado$ganancia_suavizada_max` de
cada `PARAM_<semilla>.yml`.

| semilla | ganancia_suavizada_max | envios | duración | observaciones |
|---|---|---|---|---|
| 100043 | **30.7775** | 923 | 1m06s | **peor del experimento** |
| 200063 | 33.4850 | 1010 | 1m06s | |
| 300089 | 32.9150 | 1092 | 1m07s | |
| 500069 | 31.6250 | 978 | 1m02s | |
| 700021 | 32.4775 | 1013 | 1m03s | |
| 181219 | 32.0975 | 792 | 1m12s | |
| 410341 | **35.8625** | 951 | ~1m06s | **mejor del experimento — ver abajo** |

- **Fecha de la corrida:** 2026-09-07, 22:00 → 22:08
- **Duración del loop:** ~7m40s (≈ 1m06s por semilla — la mitad que A1)
- **Tipo de runtime de Colab:**

### Estadística de las 7 semillas

| | A0 (ceros) | A1 (`NA`) |
|---|---|---|
| media | 32.7486 | 33.0939 |
| desvío | **1.6285** | **0.5297** |
| mín – máx | 30.7775 – 35.8625 | 32.5025 – 33.8550 |
| rango | 5.0850 | 1.3525 |
| CV | 4.97 % | 1.60 % |

**A0 es tres veces más disperso que A1.** Razón de varianzas: **9.45**.

Ver [`CONTRASTE_1_A1_vs_A0.md`](CONTRASTE_1_A1_vs_A0.md) para el análisis completo.

## Incidencias

_Cortes de sesión, reintentos, warnings raros, cualquier cosa que se haya
salido del libreto._

-

## Archivos que quedaron en `WF6300/`

- [ ] `resultados_A0_cero.txt` — con **7 filas**
- [ ] `PARAM_<semilla>.yml` × 7
- [ ] `prediccion_<semilla>.txt` × 7
- [ ] `ganancias_<semilla>.txt` × 7
- [ ] `impo_<semilla>.txt` × 7
- [ ] `modelo_<semilla>.txt` × 7
- [ ] `curva_de_ganancia_<semilla>.pdf` × 7

## Conclusión de este brazo

_Una o dos frases, escritas al terminar. Todavía sin comparar con los otros._

-
