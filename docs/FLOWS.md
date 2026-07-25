# Flujos de usuario — Wawa Fuerte

Especificación de pantallas y datos. **Frontend y lógica local trabajan de este documento.**

> **Vocabulario**: no hay servidor. Cuando dice "el sistema calcula/guarda", es la **capa de
> lógica local del dispositivo** (módulos de P2 y P4), no un backend remoto.

## Regla base sobre el Carné CRED

El Carné de Crecimiento y Desarrollo (CRED) es un **documento físico universal** que el MINSA
entrega a todo niño desde su primer control — no solo a quienes tienen anemia. Pero no toda
familia lo tiene a la mano o actualizado.

Por eso: **la hemoglobina nunca es obligatoria ni bloqueante.** El requerimiento de hierro
depende de la **edad** (tabla nutricional fija INS/OMS), no de la hemoglobina. La hemoglobina
solo sirve para *priorizar urgencia*. Sin ella, la app genera un plan preventivo estándar.

---

## Flujo 0 — Apertura de la app (no es login real)

No hay cuenta ni contraseña: no hay servidor con quien autenticar. Solo personaliza el saludo
si el celular es compartido en la familia.

| # | Dato pedido | Tipo | Obligatorio | Quién construye |
|---|---|---|---|---|
| 1 | Nombre de la madre/cuidador | texto libre | No (default "Usuario") | P3 (UI) → P4 (`perfil_familia`) |

Si ya existe perfil guardado, salta directo al **Flujo E (Home)**.

## Flujo A — Registro de un niño/a (se repite por cada hijo/a)

| # | Dato pedido | Tipo | Obligatorio | Uso |
|---|---|---|---|---|
| 1 | Nombre/apodo | texto libre | Sí | Display |
| 2 | Fecha de nacimiento (o edad en meses) | date / numérico | Sí | **Crítico**: determina el requerimiento estándar de hierro |
| 3 | Sexo | M / F / prefiero no decir | No | Ajuste fino de la tabla |
| 4 | Región | Costa / Sierra / Selva | Sí | Filtra ingredientes regionales en Flujo B |
| 5 | **¿Tienes a la mano el Carné CRED?** | Sí / No / No sé qué es | — | Si No → **salta al paso 8**, la app sigue funcionando |
| 6 | *(solo si Sí)* Hemoglobina (g/dL) | numérico | No | Activa modo personalizado |
| 7 | *(solo si Sí)* Fecha del último control | date | No | Se muestra como referencia ("dato de hace 2 meses") |
| 8 | Guardar perfil | botón | — | P4 escribe en `perfil_nino` |

**Multi-niño**: sin límite. Desde el Home siempre hay "+ Agregar otro niño/a".

```
perfil_nino
{ id_nino, nombre, fecha_nacimiento, sexo, region,
  tiene_cred: bool,
  hemoglobina_valor: nullable, hemoglobina_fecha: nullable }
```

## Flujo E — Home

| Elemento | Contenido |
|---|---|
| Selector de perfiles | Lista de niños registrados → toca uno para ir a su Flujo B |
| Botón | "+ Agregar otro niño/a" → Flujo A |
| Resumen (si ya hubo planes) | Ver Flujo D |

## Flujo B — Generar plan semanal (**el core del MVP**)

| # | Dato pedido | Tipo | Obligatorio | Procesa |
|---|---|---|---|---|
| 1 | Ingredientes disponibles | checklist multi-select (precargado por región) + "otro" libre | Sí (mín. 1) | P2 filtra el RAG |
| 2 | Presupuesto semanal (S/) | numérico | Sí | P2 como restricción |
| — | edad, región, hemoglobina | *(auto, del perfil)* | — | P1/P2 |

**Al presionar "Generar mi plan":**

```
P2 → buscarRecetasRelevantes(ingredientes, presupuesto, edad, region)
     → top 5 recetas del recetario INS (RAG local)

P1 → Gemma genera el plan de 7 días con esas recetas como contexto:
     - CON hemoglobina: "déficit de X mg, prioriza densidad de hierro"
     - SIN hemoglobina: "plan preventivo estándar para edad X,
       requerimiento diario Y mg" (tabla fija)

P2 → calcularHierroTotal(plan) vs requerimientoEstandarPorEdad(edad)
     → % de cobertura (funciona CON o SIN hemoglobina)
```

**Pantalla de resultado:**

| Elemento | Fuente |
|---|---|
| Plan de 7 recetas | Gemma (P1) |
| % cobertura de hierro semanal | P2 |
| Aviso si no hay hemoglobina | "Plan preventivo estándar — agrega el dato de tu Carné CRED para mayor precisión" |
| Botón 🔊 por receta | TTS local (P3) |
| Checkbox "Preparado" por día | P4 → `planes_generados` |

## Flujo C — Foto de ingredientes (STRETCH GOAL)

| # | Dato | Tipo |
|---|---|---|
| 1 | Foto de despensa/mercado | cámara — reemplaza el paso 1 del Flujo B |
| 2 | Confirmar/editar ingredientes detectados | checklist **siempre editable** (el modelo puede fallar) |

La imagen se procesa en memoria y **se descarta** — nunca se guarda en disco.

⚠️ **No es requisito del MVP.** Solo después del checkpoint de la hora 4 y si van adelantados.

## Flujo D — Seguimiento semanal

| Elemento | Fuente |
|---|---|
| "Cumpliste 5 de 7 recetas la semana pasada" | P4 lee `planes_generados` |
| "Recibió ~27mg de hierro de una meta de 35mg" | P2 recalcula |
| Ajuste del siguiente plan | Si quedó bajo, P2 prioriza mayor densidad de hierro |

No pide datos nuevos — solo lectura + recálculo al volver al Flujo B.
