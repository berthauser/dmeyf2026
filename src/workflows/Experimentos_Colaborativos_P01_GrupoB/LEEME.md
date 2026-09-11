# Problema #01 — Catastrophe Analysis — Grupo B

**Experimentos Colaborativos 2026 · Modalidad Gerencial**
Ernesto A. Zapata Icart · `future = 202107` · corrido el 7 y 8 de septiembre de 2026

> **Hipótesis H2.** La mejora en la ganancia proviene de señalarle al modelo que el
> dato falta, no de reconstruir su valor.

**Resultado: H2 no se sostiene.** Los cuatro contrastes declarados de antemano
dieron nulos (`p Holm = 1` en los cuatro). Los datos apoyan H1, la hipótesis de
irrelevancia. El detalle está en `H2_wilcoxon.txt` y en la bitácora del repositorio.

---

> **Nota.** Este archivo describe la carpeta `exp/` del Google Drive, donde quedaron
> las 35 corridas y todas sus salidas. Los notebooks que las generan estan aca, en
> el repositorio, junto a este archivo.

## Qué hay en la carpeta `exp/` del Drive

Estás en la raíz de `exp/`. Acá viven los **resultados consolidados** de las 35
corridas; cada brazo tiene además su propia subcarpeta `WF####`.

### Consolidado (esta carpeta) — lo que dejó el notebook T7

| archivo | qué es |
|---|---|
| `H2_todas_las_corridas.txt` | las 35 corridas, una fila por (brazo, semilla) |
| `H2_matriz_brazo_semilla.txt` | la misma tabla en formato 5 brazos × 7 semillas |
| `H2_resumen_por_brazo.txt` | media, mediana, desvío, mín, máx por brazo |
| `H2_wilcoxon.txt` | **los 4 contrastes declarados**, con `p` y `p` de Holm |
| `H2_varianzas.txt` | la predicción secundaria de varianza y el test de Pitman–Morgan |
| `H2_permutacion.txt` | corrección por multiplicidad (permutación, Bartlett, Fligner) |
| `H2_potencia.txt` | potencia del diseño según la cantidad de semillas |
| `H2_resultados.pdf` | boxplot por brazo con una línea por semilla |

### Las seis subcarpetas

| carpeta | qué corrió | señala | reconstruye |
|---|---|:--:|:--:|
| `WF6390` | Grid Search — **una sola vez**, sobre el baseline | — | — |
| `WF6300` | **A0** — ningún tratamiento, deja los ceros | ✗ | ✗ |
| `WF6310` | **A1** — asignar `NA` (baseline de la cátedra) | ✓ | ✗ |
| `WF6320` | **A2** — interpolación longitudinal (estadística clásica) | ✗ | ✓ |
| `WF6330` | **A3** — MICE | ✗ | ✓ |
| `WF6340` | **A4** — MICE + columna `ca_reparado` | ✓ | ✓ |

`A4` es la celda del 2×2 que las cuatro técnicas de la cátedra dejaban vacía. Sin
ella, una derrota de MICE contra `NA` no permite distinguir «reconstruir no sirve»
de «imputar destruyó la señal de ausencia».

---

## Dónde está la ganancia a reportar

**No hay un `PARAM.yml` único: hay uno por semilla.** El workflow original escribía
un solo archivo con nombre fijo, pero acá las 7 semillas corren dentro de la misma
sesión y se habrían pisado entre sí.

Dentro de cada `WF####`, por cada una de las 7 semillas:

```
PARAM_<semilla>.yml               <<< LA GANANCIA A REPORTAR
prediccion_<semilla>.txt          probabilidades sobre 202107
ganancias_<semilla>.txt           la curva de ganancia completa
impo_<semilla>.txt                importancia de variables
modelo_<semilla>.txt              el modelo LightGBM
curva_de_ganancia_<semilla>.pdf   el gráfico
```

más un acumulador con las 7 filas juntas:

```
resultados_<brazo>.txt
```

La métrica pedida está al final de cada `PARAM_<semilla>.yml`:

```yaml
semilla_de_esta_corrida: 100043.0
resultado:
  ganancia_suavizada_max: 33.2825
  envios: 936
```

> La extensión es **`.yml`**, no `.yaml`.

En `WF6390` no hay corridas de modelo: sólo `PARAM_gridsearch.yml` y
`tb_grid_search_01.txt`, con las 20 combinaciones de la grilla y su AUC.

---

## Las semillas

```
100043   200063   300089   500069   700021   181219   410341
```

Siete, propias, nunca la del profesor. **Por qué siete y no cinco:** el Wilcoxon
pareado de signos tiene un piso combinatorio de `2 / 2ⁿ` a dos colas. Con n=5 el
`p` más chico posible es `0.0625` y **nunca llega a 0.05**, aunque las cinco
diferencias vayan en la misma dirección. Con n=7 el piso baja a `0.0156`.

## Los hiperparámetros

Salieron de una única corrida de Grid Search (`WF6390`, semilla 100043,
AUC en validation 0.9540665) y quedaron **congelados e idénticos en los cinco
brazos**:

```r
num_leaves       = 256
min_data_in_leaf = 64
num_iterations   = 428
```

Congelarlos es más barato *y* más *ceteris paribus*: si cada brazo optimizara los
suyos, la diferencia de ganancia mezclaría el efecto del tratamiento con el de
haber caído en otro punto de la grilla.

---

## Cómo reproducirlo

Los siete notebooks están en esta misma carpeta del repositorio.
El orden es:

1. `611_CA_T4_gridsearch.ipynb` — **primero y una sola vez** (~70 min)
2. `611_CA_A1_na.ipynb`
3. `611_CA_A0_cero.ipynb`
4. `611_CA_A2_interp.ipynb`
5. `611_CA_A3_mice.ipynb`
6. `611_CA_A4_mice_flag.ipynb`
7. `611_CA_T7_analisis.ipynb` — cuando estén los cinco

Los cinco brazos son **independientes entre sí**: sólo T4 va antes de todos y T7
después de todos. Entre brazos lo único que cambia es la celda 25, la del
Catastrophe Analysis.

Las celdas 46–62 del workflow original (`dtrain`, `dvalidate`, Grid Search) **no se
ejecutan** en los brazos: con `training_pct = 1.0` el undersampling es un no-op,
`azar` está fuera de `campos_buenos`, y `dtrain` sólo alimentaba el Grid Search.
Ahorra 68 minutos por corrida sin cambiar un solo resultado.

---

## Advertencias para quien lea estos números

- **Las ganancias del Grupo A no son comparables con éstas.** El Grupo A usa
  `future = 202109` y Kaggle; el Grupo B usa `future = 202107` y la ganancia local
  del `PARAM.yml`. Son meses distintos, con distinta cantidad de bajas.
- **El rango entre las medias de los cinco brazos (0.77) es menor que el desvío
  entre semillas dentro de un mismo brazo (1.35).** Cualquier diferencia entre
  tratamientos está adentro del ruido de la semilla.
- **La potencia del diseño está calculada** y está en `H2_potencia.txt`: 0.06 con
  7 semillas, 0.095 con 15 —el techo que permite la cátedra—, 0.43 con 100. La
  afirmación correcta no es «no hay efecto» sino «si lo hay, hacen falta más de
  cien semillas para verlo».
- **Una predicción secundaria, registrada a mitad del experimento** con tres brazos
  todavía sin correr, también falló: el flag de A4 no cambió la dispersión (razón
  de varianzas 1.14, `p = 0.887`). Y la observación que quedaba en pie no sobrevive
  la corrección por multiplicidad: pasa de `p = 0.015` a `p = 0.173`. Está todo en
  `H2_varianzas.txt` y `H2_permutacion.txt`.
