# Predicción Final — Competencia Kaggle

Ernesto A. Zapata Icart · Modalidad Gerencial · `future = 202109` · **cierre 20-sep 23:59:59**

Este archivo es la hoja de trabajo del 16 al 20 de septiembre. Antes de entregar
se reemplaza por un README que explique qué se corrió (lo exige el PDF §5: los
profesores tienen que poder regenerar el submit exacto).

---

## 0. Bloqueantes — resolver ANTES de correr

- [ ] **`kaggle.json` en el Drive.** La celda 6 hace
      `cp /content/buckets/b1/kaggle/kaggle.json ~/.kaggle`. En los experimentos
      esto fallaba (`cannot stat`) y no importaba, porque el Grupo B no subía a
      Kaggle. **Ahora sí importa: sin ese archivo no hay submit.**
      Hay que crear `My Drive/dm/kaggle/` y poner ahí el token
      (Kaggle → Settings → API → Create New Token).
- [ ] **Estar inscripto en la competencia** `utn-2026-virtual-mgr`. Aceptar las
      reglas desde la web de Kaggle o el submit se rechaza.
- [ ] Verificar que el límite de submits diarios alcanza: el notebook sube
      **11 archivos** por corrida (`seq(800, 1300, by = 50)`) y Kaggle permite 20.

## 1. Ya aplicado en `719_final_gerencial.ipynb`

| qué | antes | ahora | por qué |
|---|---|---|---|
| semilla | `102191` | `100043` | §6.12: las semillas siempre se cambian a las propias. `102191` es la del profesor |
| experimento | `6300` | `7190` | **`6300` es la carpeta de A0_cero.** Correr con ese número pisaba las corridas del experimento entregado |
| ruta Drive | `My Drive/dmeyf` | `My Drive/dm` | tus datasets y tus `WF63xx` viven en `dm` |
| outputs | guardados | limpios | el notebook arranca de cero |

Vienen del merge de la cátedra y quedan como están: URL `utn2026-b40a`,
competencia `utn-2026-virtual-mgr`, `future = 202109`.

## 2. Una fila por experimento — completar leyendo el Google Slides

Procedimiento (Hoja de Ruta, 16-sep): leer la **Recomendación Concreta** de cada
problema, comparar A contra B, decidir, y tocar la celda.

| etapa del workflow | celda | grupo A recomienda | grupo B recomienda | decisión | hecho |
|---|:--:|---|---|---|:--:|
| **CA** Catastrophe Analysis | **25** | _(Silvia · Mariela)_ | **mío: no tocar** | ver §3 | ☑ |
| **DR** Data Drifting | 27 | | | | ☐ |
| **FE** intra-mes | 29 | | | | ☐ |
| **FE** histórico | 35 | | | | ☐ |
| **TS** Training Strategy | 43 | | | | ☐ |
| **HT** Hyperparameter Tuning | 57 | | | | ☐ |
| **FT** Final Training | 66 | | | | ☐ |
| cortes / envíos a Kaggle | 81 | | | | ☐ |

La celda 27 (Data Drifting) hoy dice literalmente
`# sin codigo en esta primera version del workflow`: si algún grupo recomienda
algo ahí, se escribe de cero.

Las celdas 32 (FE por Random Forest) y 39 (canaritos) están vacías a propósito —
son sólo para Analista Sr. No son tus problemas.

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
