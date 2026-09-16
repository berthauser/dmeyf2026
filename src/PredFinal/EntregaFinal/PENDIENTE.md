# Predicción Final — Competencia Kaggle

Ernesto A. Zapata Icart · Modalidad Gerencial · `future = 202109` · **cierre 20-sep 23:59:59**

Este archivo es la hoja de trabajo del 16 al 20 de septiembre. Antes de entregar
se reemplaza por un README que explique qué se corrió (lo exige el PDF §5: los
profesores tienen que poder regenerar el submit exacto).

---

## 0. Bloqueantes — RESUELTOS el 2026-09-16

- [x] **`kaggle.json` en el Drive.** Estaba en `My Drive/dmeyf/kaggle/`, no en
      `My Drive/dm/kaggle/`, que es donde lo busca la celda del `%%shell`. Se copió
      a `dm/kaggle/kaggle.json` y como `b1` es un symlink al Drive, quedó
      **persistente**: no hay que repetirlo en cada sesión de Colab.
- [x] **Inscripción confirmada.** `kaggle competitions list --group entered` da
      `utn-2026-virtual-mgr` con `userHasEntered = True`, y
      `kaggle competitions submissions -c utn-2026-virtual-mgr` responde
      "No submissions found" — la respuesta correcta para alguien inscripto sin
      submits todavía.
- [x] **Token válido**, autenticando como `ezicart@frp.utn.edu.ar`.
- [ ] Límite de submits: el notebook sube **11 archivos** por corrida
      (`seq(800, 1300, by = 50)`) y Kaggle permite 20 por día.

Cierre en Kaggle: **2026-09-21 03:00 UTC** = medianoche del 20 al 21 en Argentina.
Coincide con el "20-sep 23:59:59" del cronograma.

Ernesto está inscripto en las cuatro competencias (`inicial`, `virtual-jr`,
`virtual-mgr`, `virtual-sr`). La que cuenta es **`utn-2026-virtual-mgr`**, ya fija
en la celda del submit.

## 1. Ya aplicado en `719_final_gerencial.ipynb`

| qué | antes | ahora | por qué |
|---|---|---|---|
| semilla | `102191` | `100043` | §6.12: las semillas siempre se cambian a las propias. `102191` es la del profesor |
| experimento | `6300` | `7190` | **`6300` es la carpeta de A0_cero.** Correr con ese número pisaba las corridas del experimento entregado |
| ruta Drive | `My Drive/dmeyf` | `My Drive/dm` | tus datasets y tus `WF63xx` viven en `dm` |
| outputs | guardados | limpios | el notebook arranca de cero |

Vienen del merge de la cátedra y quedan como están: URL `utn2026-b40a`,
competencia `utn-2026-virtual-mgr`, `future = 202109`.

## 2. Una fila por problema — completar leyendo el Google Slides

Numeración segun el `UTN_2026_virtual.pptx` de la cátedra (12 problemas). Las
celdas se ubican por **título de sección** con el panel de índice de Colab; `idx`
es la posición en el `.ipynb` contando las de texto.

De los 12, **siete aplican a Gerencial**:

| # | tema | sección en el 719 | idx | A recomienda | B recomienda | decisión | hecho |
|---|---|---|:--:|---|---|---|:--:|
| **01** | Catastrophe Analysis | 6.3.1.2 CA | **25** | _(Silvia · Mariela)_ | **mío: no tocar** | ver §3 | ☑ |
| **02** | Data Drifting | movido al final del FE intra-mes | 29 | `estandarizar` | **`rank_cero_fijo`** | **B — aplicado** | ☑ |
| **03** | FE intra-mes, variables manuales | 6.3.1.3 FE_intra_manual | 29 | mantener baseline | **Exp 2: Z-Score + ratios** | **B — aplicado** | ☑ |
| **04** | Training Strategy, meses de pandemia | 6.3.2.1 | 43 | **no quitar meses** | excluir 202003-202012 | **A — sin cambios** | ☑ |
| **05** | FE histórico | 6.3.1.5 FEhist | 35 | **dejar tal cual** | +lag3, delta3, ma3 | **A — sin cambios** | ☑ |
| **11** | HT, desbalanceo en LightGBM | 6.3.2.2, `param_fijos` | 54 | **no activar balanceo** | _(sin grupo B)_ | **A — sin cambios** | ☑ |
| **12** | Undersampling | 6.3.2.1, `training_pct` | 43 | 0.1 | **`training_pct` = 0.01** | **B — aplicado** | ☑ |

**Los cinco que no se corren:** #06 PCA, #08 FE con Random Forest y #09 Boruta vs
Canaritos no están implementados en el notebook final; #07 (testing en dos o más
meses) no deja recomendación operativa; #10 (algoritmo genético) no tiene bloque
propio. No se agrega nada salvo indicación expresa de la cátedra.

**#02 Data Drifting — resuelto el 2026-09-16, se adoptó `rank_cero_fijo`.**

Los grupos se contradicen: A recomienda `estandarizar` (p<0.05 contra los otros
siete); B recomienda `rank_cero_fijo` y **declara que no alcanzó significancia**
con Wilcoxon + Bonferroni. Se eligió el de B por dos razones:

1. **El cara a cara.** B midió `rank_cero_fijo` > `estandarizar` en **10/10
   semillas** — el peor rival que enfrentaron. Contra el resto ganan 9/10.
2. **La implementación.** `drift_estandarizar` de la cátedra tiene un bug fatal:
   `mean(campo)` en vez de `mean(get(campo))`, o sea le pasa el *nombre* de la
   columna a `mean()`, que devuelve `NA`; como después borra la columna original,
   deja **todas las variables monetarias en `NA`**. `drift_rank_cero_fijo` usa
   `frank(get(campo))` correctamente. El 10/10 de B es lo que uno esperaría si
   ese código se corrió sin corregir.

Reservas registradas: B no alcanzó significancia; `rank_cero_fijo` tiene **mayor
desvío** que el resto, y el experimento del Problema 01 mostró que el ruido de la
semilla domina; y los períodos no coinciden — A corrió sobre 202109 (el de esta
predicción final), B sobre 202107.

**Desvío de orden documentado:** el bloque no va en su sección 6.3.1.3 sino al
final del FE intra-mes (idx 29). `rank_cero_fijo` renombra `<campo>` a
`<campo>_rank` y borra el original; en la posición original, el guard
`atributos_presentes(c("mpayroll","cliente_edad"))` daría `FALSE` y
`mpayroll_sobre_edad` no se crearía, **sin error ni warning**. La celda 27 quedó
con la nota que explica esto.

**#03 FE intra-mes — resuelto el 2026-09-16, se adoptó el Experimento 2 del Grupo B.**

Los dos grupos **no midieron lo mismo**, así que el nulo de A no refuta a B:

- **A** comparó "original vs manual vs automático": ninguna alternativa mejoró de
  forma significativa, diferencia de **0.46 %** entre las tres. Recomiendan
  mantener el baseline.
- **B** construyó otra cosa —flags de tenencia + Z-Score antes de los ratios— y
  midió **W = 1.00, p = 0.0039** sobre 10 semillas, con la mediana de ganancia
  pasando de **33.351 a 34.544** (+1.19 puntos), ganando en 9 de 10 semillas.

Con n=10 el piso del Wilcoxon a dos colas es `2/2¹⁰ = 0.00195`, así que
`p = 0.0039` es casi el mínimo alcanzable. Para dimensionarlo: el rango entero
entre las medias de los cinco brazos del Problema 01 fue **0.77**; esto es más
grande que todo aquel eje experimental.

**Qué se implementó.** La lámina de Recomendación Concreta de B decía sólo
*"usar la arquitectura validada del Experimento 2"*, que no es ejecutable; las
láminas del Experimento 2 sí lo especifican. El set exacto no está publicado —la
tabla de B es de **importancia**, no de definición— así que se reconstruyen los
ratios que nombra, leyendo la convención del sufijo `_z`: los ratios contra
`cliente_edad` usan el valor crudo, los ratios entre monetarias usan los Z-Score.
Son 4 flags, 7 Z-Score y 8 ratios.

**Riesgo declarado — combinación no probada.** B midió su +1.19 contra *su*
baseline, que casi seguro usaba `deflacion` en drift. Acá queda apilado con
`rank_cero_fijo` del #02: dos correcciones de drift conviviendo. No es
incoherente (los `z_*`, `flag_*` y `ratio_*` no matchean el regex
`^(m|Visa_m|Master_m|vm_m)` y no se rankean), pero nadie lo midió junto.
**Plan B barato si la corrida da algo raro:** poner `PARAM$DR$metodo <- "ninguno"`
y quedarse con el Z-Score como única corrección — es cambiar un string.

**Orden dentro de la celda 29:** baseline de la cátedra → Experimento 2 → Data
Drifting. Los Z-Score se calculan sobre los valores originales, antes de que
`rank_cero_fijo` los reemplace por rangos.

**#04 Training Strategy — resuelto el 2026-09-16, no se quitan meses.**

Cara a cara: los dos grupos probaron lo mismo y recomiendan lo opuesto. A dice
*no consumir tiempo ni recursos quitando meses*; B dice *entrenar excluyendo
202003-202012*.

**Lo que decide es el tamaño del dataset de cada modalidad.** El Gerencial está
reducido a `[202005, 202109]` —lo dice la propia sección de Training Strategy— y
tiene 14 meses de `training` y 15 de `final_train`; el Junior tiene 29 y 31.

| | queda | pierde |
|---|---|---|
| Junior | 31 → 21 meses | −32 % |
| **Gerencial** | **15 → 7 meses** | **−53 %** |

En Gerencial el período excluido empieza antes de que arranquen los datos, así que
se lleva 202005 a 202012 completos: ocho de quince meses, y el `training` cae de
14 a 6. Siete meses de final train está **por debajo de los nueve** que la cátedra
toma como piso, y el PDF dice que entrenar en más datos produce mejores modelos y
que no se pueden tomar atajos con menos meses. La recomendación de B es razonable
en su dataset y es amputación en éste.

Además, A corrió sobre `future = 202109` con Kaggle, el mismo terreno que esta
predicción final; B midió sobre 202107. **No se pudo determinar la modalidad del
Grupo B** — si fueran gerenciales habrían medido esa poda del 53 % y valdría
repensarlo; el rango que excluyen sugiere que no.

La sugerencia secundaria de A tampoco aplica: proponen explorar la quita de
**202002**, mes que en Gerencial **no existe**.

Nota: de haber adoptado la de B, el resultado del Problema 01 quedaba sin efecto
— 202006 saldría del training y el `NA` no tendría sobre qué actuar.

**#05 FE histórico — resuelto el 2026-09-16, no se toca la sección.**

Los dos grupos **implementaron la media móvil**; difieren en el veredicto. A dice
*dejar la sección tal cual* y comparte igualmente el código del rolling mean
"en caso de que desee sacrificar más horas de cómputo (**15 % más de tiempo**) e
intentar mejorar la ganancia media **ínfimamente**". B recomienda agregar `lag3`,
`delta3` y `ma3`, con implementación completa pero **sin mostrar tamaño de efecto
ni p-value** en sus láminas.

**El costo en este notebook.** `cols_lagueables` son todas las columnas menos tres,
y hoy se generan 4 transformaciones por columna; B propone 7:

```
hoy:    base + 4 × (base − 3)  ≈  5 × base
con B:  base + 7 × (base − 3)  ≈  8 × base
```

**+60 % de columnas**, y no sobre el dataset original: el #03 acaba de agregar 19
columnas (4 flags + 7 Z-Score + 8 ratios) que también entran a `cols_lagueables`.
El +15 % que midió A era por agregar **sólo** el rolling mean, no tres
transformaciones.

Se sigue a A porque es el único que puso el trade-off en números y su veredicto es
"ínfima". Hay una sola corrida disponible y un Grid Search de 50 minutos por
delante.

**Bug en el código de A:** define `roll_window <- 3` pero después usa
`frollmean(x, n = w, ...)`, y `w` no existe — tira `object 'w' not found`. El
fragmento de la lámina no se corrió tal como está. **El de B sí está bien
escrito** (`frollmean(.SD, n = 3, align = "right", fill = NA, na.rm = TRUE)`); es
la versión a usar si alguna vez se agrega el rolling mean.

Punto intermedio descartado, disponible si hiciera falta: agregar sólo `ma3`
(donde convergieron los dos grupos) da ~+25 % de columnas en vez de +60 %.

**#11 HT desbalanceo — resuelto el 2026-09-16, sin cambios. Sólo hubo Grupo A.**

Conclusión de A: *"el aumento de ganancia observado en semillas individuales es
consecuencia directa de la alta volatilidad e inestabilidad introducida por los
parámetros de desbalanceo. La variación se explica por la inestabilidad de las
semillas, no por una mejora sustancial del modelo."* Recomiendan no activar
parámetros agresivos de balanceo y dejar la sección de optimización como está.

Verificado: `param_fijos` **no tiene** ningún parámetro de balanceo —ni
`is_unbalance`, ni `scale_pos_weight`, ni fracciones de bagging—, así que "dejar
como está" es literalmente no tocar nada.

Vale para el README: la conclusión de A tiene **la misma estructura** que el
resultado del Problema 01 — el ruido de la semilla explica lo que parecía efecto.
Dos experimentos independientes sobre etapas distintas del workflow llegando a lo
mismo.

En la versión del `UTN_2026_virtual.pptx` del 3-sep había láminas de un Grupo B
para el #11 (hipótesis: *"el LGBM es robusto frente al desbalance"*, sesgos,
bibliografía), que apuntaban al mismo lado. No llegaron a entregar Recomendación
Concreta.

---

## Reproducibilidad — agregado fuera de los 12 problemas

`param_fijos` no fijaba `num_threads` ni `deterministic`. Sin eso LightGBM **no es
reproducible entre máquinas**: el orden de reducción en punto flotante cambia con
la cantidad de hilos, y la misma semilla da otro modelo. Es el mismo problema que
se corrigió en la Rev2 del notebook CA05 del Grupo A del Problema 01.

El PDF §5 lo exige: *"los profesores tienen que ser capaces de correr esos scripts
y generar exactamente el archivo que usted ha subido a Kaggle"*.

Agregado el 2026-09-16:

```r
num_threads= 2,
deterministic= TRUE,
```

Aplica a las dos etapas: el Grid Search los toma vía
`modifyList(PARAM$lgbm$param_fijos, x)` y el modelo final vía
`fijos <- copy(PARAM$lgbm$param_fijos)`. Costo: la corrida es más lenta y queda
limitada a 2 hilos.

**#12 Undersampling — resuelto el 2026-09-16, `training_pct <- 0.01`.**

Verificado en el notebook: `training_pct` → `fold_train` → `dtrain` (idx 47), y
`dtrain` se usa **únicamente** en `Estimar_AUC_lightgbm()` (idx 55), o sea el Grid
Search. El modelo final usa `dfinal_train` (idx 66), sin undersampling. El propio
comentario de la cátedra lo dice: *"solamente por un tema de VELOCIDAD"*. Es el
mismo hallazgo que permitió saltear las celdas 46–62 en el Problema 01, y el
Grupo B llegó a él por su cuenta: *"la degradación del grid existe... pero no
llega al modelo final: se pierde al armar `param_final`"*.

A recomienda 0.1; B recomienda 0.01. Gana B, con un golpe directo a A:

- **B midió el 0.1 de A y le dio el peor de los cinco niveles** — y lo sabe porque
  su comparación primaria estaba pre-registrada justamente sobre 0.1.
- Sin punto de ruptura hasta 0.01: 14.373 filas contra 779.565.
- 0.01 tiene la **media más alta** de los cinco niveles.
- **87 % menos de cómputo**: 48,8 min → 6,5 min.
- Cubrieron el único canal por el que el grid contamina el modelo final,
  `num_iterations`, que sí pasa a `param_final`: +36 % en 0.01, `r = +0.373`, y
  aun así la ganancia no cae.

**Efecto colateral buscado:** compensa el costo de `deterministic = TRUE` y
`num_threads = 2`. Son los únicos parámetros que tocan el Grid Search y van en
direcciones opuestas.

**Control agregado (idx 47):** un `cat()` que imprime cuántas filas quedaron en
`dtrain` sobre las posibles. Las cifras de B vienen de `z621` (Junior, 29 meses de
training); el Gerencial tiene 14, así que su `dtrain` es más chico de entrada.
**Mirar ese número antes de dejar correr el Grid Search:** si quedan muy pocas
filas, subir a 0.05 o 0.1.

**#11 lo dio por inexistente** el `mapa_experimentos_gerencial_junior_v2.xlsx`
("No identificado en el PPT"). Es falso: está en el PPT, con hipótesis, sesgos y
bibliografía, marcado para *Analista Jr y Gerencial*, y toca
`bagging_fraction`, `bagging_freq`, `neg_bagging_fraction`,
`pos_bagging_fraction`, `is_unbalance` y `scale_pos_weight`.

**#12 toca un parámetro ya conocido:** `training_pct = 1.0` vuelve el undersampling
un no-op (`runif ∈ [0,1)` hace que `azar < 1.0` sea siempre verdadero). Es el
hallazgo que permitió saltear las celdas 46–62 en el experimento del Problema 01.

Las celdas 32 (FE por Random Forest) y 39 (canaritos) están vacías a propósito:
son sólo para Analista Sr.

## 3. La celda 25 es la tuya y ya está decidida

El experimento H2 dio **nulo en los cuatro contrastes declarados** (`p Holm = 1`)
y la receta que se presentó en el video es *dejar la celda 25 como está*, con el
`NA` de la cátedra. Así que acá no se cambia nada — y eso **es** el resultado, no
una omisión.

Si el Grupo A recomienda reemplazar el `NA` por MICE: su único resultado
significativo (ST vs MICE, `p = 0.02427`) **no sobrevive Holm** sobre sus 9 tests
(`p_holm = 0.2184`, y con 9 tests hay 37 % de chance de al menos un falso
positivo). Está el argumento para no seguirlos, pero la decisión es leer su
Recomendación Concreta primero.

## 4. Decisión pendiente: ¿se recorre el Grid Search?

El notebook trae el Grid Search completo (celdas 49–62): 4 × 5 = 20
combinaciones, **~50 minutos**, más 7 minutos de instalar LightGBM.

Los hiperparámetros congelados del experimento (`num_leaves = 256`,
`min_data_in_leaf = 64`, `num_iterations = 428`) salieron de `WF6390`, que
validaba en **otro mes**. Acá `PARAM$trainingstrategy$validate <- c(202107)`.
Reusarlos ahorra 50 minutos pero optimiza para una validación que ya no es la de
este notebook.

**Sugerencia: correrlo.** Hay cinco días y es una sola vez.

Recordar además que `min_data_in_leaf = 64` cayó en el **borde inferior** de la
grilla, así que el óptimo podría estar más abajo de lo explorado.

## 5. El experimento propio — lo exige §6.15

> No está permitido que un alumno simplemente recoja las conclusiones de las
> todas las exposiciones, corra esa configuración, y esa sea su entrega final.

Hay que agregar algo propio. El candidato natural sale del propio experimento H2:
lo que se midió es que **el ruido de la semilla es más grande que cualquier
diferencia entre tratamientos** (rango entre medias de brazos 0.77 contra desvío
entre semillas de 1.35, y la mejor y la peor corrida salieron de la *misma*
semilla, `700021`).

Si la semilla domina, promediar sobre semillas debería ganar más que cualquier
elección de método: entrenar N modelos que sólo difieren en la semilla y promediar
las probabilidades antes de cortar. Es barato, se apoya en evidencia propia ya
medida, y es exactamente el "último experimento" que pide la cátedra.

Queda a decidir el 17 o 18, según cuánto tarde la corrida base.

## 6. Fechas

| cuándo | qué |
|---|---|
| 16-sep 13:00–15:00 | arranca el Torneo de Videos — votar día por medio |
| 16 al 20-sep | leer Recomendaciones Concretas, armar y correr este notebook |
| **20-sep 23:58** | límite de solución reproducible en GitHub |
| **20-sep 23:59:59** | cierre Kaggle — **seleccionar a mano el submit** con el que se compite |
| 27-sep | notas finales |

Ojo con el último punto: si no se elige el submit manualmente, Kaggle toma el que
él quiera, no el mejor.

---

## Experimento propio — semillerío (PDF §6.15)

§6.15 prohíbe que juntar las conclusiones ajenas *sea* la entrega: hay que agregar
experimentos propios. El elegido sale de la evidencia ya medida.

**Por qué éste.** El experimento del Problema 01 y la conclusión del Problema 11
midieron lo mismo por caminos distintos: **el ruido de la semilla explica lo que
parecía efecto del método**. En el Problema 01 el rango entre las medias de los
cinco brazos fue **0.77** y el desvío entre semillas dentro de un brazo **1.35**,
y la mejor y la peor corrida de las 35 salieron de la **misma** semilla (700021).
El Problema 11 lo dijo igual: *"la variación se explica por la inestabilidad de
las semillas, no por una mejora sustancial del modelo"*. Si la semilla domina,
promediar sobre semillas debería rendir más que cualquier elección de método.

**Implementación** (idx 68 y 70): se entrenan N modelos idénticos salvo la
semilla y se **promedian las probabilidades** antes de cortar.

```r
PARAM$semillerio <- c(100043, 200063, 300089, 500069, 700021)
```

- La predicción se acumula **dentro** del loop, no se guardan los N modelos vivos.
- `dfinal_train` se reusa entre iteraciones — probado en el Problema 01 con 7
  semillas y `free_raw_data = TRUE`.
- `final_model` queda con el **último** modelo del loop: es el que se graba en
  `modelo.txt` y del que sale `impo.txt`.
- **idx 76 quedó neutralizada a propósito.** Ahí el notebook original hacía
  `prediccion <- predict(final_model, ...)`, que pisaría el promedio con la salida
  de un solo modelo. Ahora sólo verifica el largo.
- Para una corrida de prueba: dejar **una sola** semilla y el notebook se comporta
  como el original.

**Costo:** N entrenamientos finales en vez de uno.

---

## Llave para correr sin submitear (idx 81)

```r
PARAM$kaggle$submit <- TRUE   # FALSE genera los CSV pero no los sube
```

En `FALSE` escribe los 11 archivos en `./kaggle/` y avisa por consola, sin gastar
submits ni ensuciar el leaderboard. Pensada para la corrida de prueba.

---

## Orden de trabajo sugerido para el 17-sep

1. Abrir el notebook del repo en Colab **con la cuenta sandbox**, y
   `Archivo → Guardar una copia en Drive`.
2. Runtime **Python 3**: correr las dos primeras celdas (montaje del Drive y el
   `%%shell`). Esta vez el `cp` del `kaggle.json` ya no falla.
3. Runtime **R**: correr desde *Inicializacion*.
4. **Mirar el `cat()` de `dtrain`** antes de dejar correr el Grid Search. Si
   quedaron muy pocas filas, subir `training_pct` a 0.05.
5. El Grid Search va a tardar **más** que los 50 min anunciados por
   `deterministic = TRUE` y `num_threads = 2`, y **menos** por
   `training_pct = 0.01`. Neto: imposible de predecir, pero acotado.
6. Primera pasada con **una sola semilla** y `PARAM$kaggle$submit <- FALSE`, para
   ver que todo corre de punta a punta.
7. Recién después: las 5 semillas y `submit <- TRUE`.
8. **Antes del 20-sep 23:59:59, elegir a mano en Kaggle** cuál de los submits
   compite.
