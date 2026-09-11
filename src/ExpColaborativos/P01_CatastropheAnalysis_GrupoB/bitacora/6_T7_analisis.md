# Bitácora — `T7_analisis`

**No entrena nada.** Lee los 5 `resultados_<brazo>.txt` y corre el test.

| | |
|---|---|
| **notebook** | `611_CA_T7_analisis.ipynb` |
| **cuándo** | cuando los 5 brazos terminaron sus 7 semillas |
| **entrada** | `WF6300/…` … `WF6340/resultados_A4_mice_flag.txt` |

## Antes de correr

- [ ] Los 5 `resultados_<brazo>.txt` existen
- [ ] Cada uno tiene **7 filas**
- [ ] Total: **35 corridas**. El notebook lo verifica solo e imprime las que falten

## Los 4 contrastes, declarados ANTES de ver los resultados

| # | contraste | qué aísla | H2 predice |
|---|---|---|---|
| 1 | A1 vs A0 | señalar, sin reconstruir | **A1 > A0** |
| 2 | A3 vs A1 | reconstruir en vez de señalar | **A3 < A1** |
| 3 | **A4 vs A3** | **el flag, con el valor constante** | **A4 > A3** |
| 4 | A4 vs A1 | el valor, con la señal constante | **A4 ≈ A1** |

**El 3 es el decisivo.** A3 y A4 comparten imputación, semilla de datos e
hiperparámetros; lo único que los separa es la columna `ca_reparado`.

Wilcoxon pareado por semilla, dos colas, corrección de **Holm** por los 4
contrastes.

## Por qué 7 semillas y no 5

El Wilcoxon de rangos con signo tiene un piso combinatorio: con `n` pares, el
p-value más chico posible es `2 / 2^n` a dos colas.

| n | p mínimo |
|---|---|
| 5 | 0.0625 — **nunca llega a 0.05** |
| 6 | 0.03125 |
| 7 | 0.0156 |

Con 5 semillas, aunque las 5 diferencias fueran en la misma dirección, el test
**no puede** reportar significancia a dos colas.

---

## La vara: el ruido de fondo

El notebook imprime el desvío entre semillas **dentro** de cada brazo, y el rango
entre las medias de los brazos. **Si el segundo es menor que el primero, no hay
nada que discutir**: las diferencias entre tratamientos están adentro del ruido
de la semilla. Ese es un resultado válido y hay que reportarlo como tal.

## Resultados — corrido el 2026-09-08

`filas leidas: 35 (esperadas: 35)` ✓

| # | contraste | dif. mediana | gana en | p | p (Holm) | ¿signif.? |
|---|---|---|---|---|---|---|
| 1 | A1 vs A0 | +0.9400 | 5/7 | 0.5781 | 1.0000 | **no** |
| 2 | A3 vs A1 | +0.0275 | 4/7 | 0.8125 | 1.0000 | **no** |
| 3 | **A4 vs A3** | **+0.0100** | 4/7 | 0.8125 | 1.0000 | **no** |
| 4 | A4 vs A1 | +0.0275 | 4/7 | 1.0000 | 1.0000 | **no** |

- **Desvío medio entre semillas (ruido de fondo):** **1.3454**
- **Rango entre las medias de los brazos:** **0.7654**

> **El rango entre brazos (0.77) es MENOR que el ruido entre semillas (1.35).**
> Ésa era la vara declarada de antemano, y dice que no hay nada que distinguir:
> las diferencias entre tratamientos están dentro del ruido de la semilla.

### La predicción secundaria de varianza

```
razon de varianzas A4/A3 = 1.14   p = 0.8870
```

A3 y A4 comparten imputación, semilla de datos e hiperparámetros; sólo los separa
`ca_reparado`. **El flag no cambia nada.** La predicción falla en su prueba más
limpia.

### Corrección por multiplicidad

```
permutacion, desvio minimo:       p = 0.1731
permutacion, razon max/min:       p = 0.1603
Bartlett:                         p = 0.1061
Fligner-Killeen:                  p = 0.2743
```

La estabilidad de A1 (desvío 0.53 contra 1.30–1.88 del resto) **no es
estadísticamente notable** una vez que se corrige por haber elegido ese brazo
después de ver los datos, entre cinco.

### Potencia

| n | potencia |
|---|---|
| 7 | 0.060 |
| 15 (techo del profesor) | 0.095 |
| 100 | 0.426 |

Con el ruido observado, el efecto no es detectable con ningún `n` permitido.

## Verificación cruzada

Los números coinciden **exactamente** con los calculados por fuera del notebook
(en R sobre `entorno-ds:1.0`, a partir de las salidas pegadas de cada brazo) y con
los del dry-run del propio T7 antes de correrlo. Tres caminos independientes, el
mismo resultado.

## Archivos que deja

- [ ] `H2_todas_las_corridas.txt` (35 filas)
- [ ] `H2_matriz_brazo_semilla.txt` (5 × 7)
- [ ] `H2_resumen_por_brazo.txt`
- [ ] `H2_wilcoxon.txt`
- [ ] `H2_resultados.pdf` — boxplot por brazo, con una línea por semilla

## Conclusión del experimento

**H2 no se sostiene. Los datos apoyan H1 (Irrelevancia).**

Ningún método de Catastrophe Analysis produjo un efecto detectable sobre la
ganancia, ni en promedio ni en dispersión. Cuatro contrastes declarados de
antemano, cuatro nulos con `p_holm = 1`. La predicción secundaria de varianza,
registrada a mitad de camino y con tres brazos sin correr, también falló.

El detalle completo está en [`CONCLUSIONES.md`](CONCLUSIONES.md).
