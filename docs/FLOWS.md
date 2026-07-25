# User flows — Wawa Fuerte

Screen and data specification. **The UI and the local logic work from this document.**

> **Vocabulary**: there is no server. Where it says "the system computes/stores", that means the
> **local logic layer on the device** (the P2 and P4 modules), not a remote backend.
>
> **Language**: this document is written in English, but the strings quoted in `"…"` are the
> literal in-app copy shown to the user and stay in Spanish — the app's users are Spanish-speaking
> families in Peru. Field names (`perfil_nino`, `hemoglobina_valor`, …) are identifiers, not prose,
> and stay as they are in the code.

## Base rule about the CRED booklet

The *Carné de Crecimiento y Desarrollo* (CRED) is a **universal physical document** that MINSA
issues to every child from their first check-up — not only to those who already have anemia. But
not every family has it at hand or up to date.

Therefore: **hemoglobin is never mandatory and never blocking.** The iron requirement depends on
**age** (fixed INS/WHO nutritional table), not on hemoglobin. Hemoglobin only serves to *prioritise
urgency*. Without it, the app generates a standard preventive plan.

---

## Flow 0 — Opening the app (not a real login)

There is no account and no password: there is no server to authenticate against. It only
personalises the greeting when the phone is shared within the family.

| # | Data requested | Type | Required | Who builds it |
|---|---|---|---|---|
| 1 | Mother's/caregiver's name | free text | No (defaults to "Usuario") | P3 (UI) → P4 (`perfil_familia`) |

If a saved profile already exists, jump straight to **Flow E (Home)**.

## Flow A — Registering a child (repeated for each child)

| # | Data requested | Type | Required | Use |
|---|---|---|---|---|
| 1 | Name/nickname | free text | Yes | Display |
| 2 | Date of birth (or age in months) | date / number | Yes | **Critical**: determines the standard iron requirement |
| 3 | Sex | M / F / prefer not to say | No | Fine-tunes the table |
| 4 | Region | Coast / Highlands / Jungle | Yes | Filters regional ingredients in Flow B |
| 5 | **Do you have the CRED booklet at hand?** | Yes / No / I don't know what that is | — | If No → **skip to step 8**, the app keeps working |
| 6 | *(only if Yes)* Hemoglobin (g/dL) | number | No | Enables personalised mode |
| 7 | *(only if Yes)* Date of the last check-up | date | No | Shown as a reference ("reading from 2 months ago") |
| 8 | Save profile | button | — | P4 writes to `perfil_nino` |

**Multi-child**: no limit. The Home always offers "+ Agregar otro niño/a".

```
perfil_nino
{ id_nino, nombre, fecha_nacimiento, sexo, region,
  tiene_cred: bool,
  hemoglobina_valor: nullable, hemoglobina_fecha: nullable }
```

## Flow E — Home

| Element | Contents |
|---|---|
| Profile selector | List of registered children → tap one to go to their Flow B |
| Button | "+ Agregar otro niño/a" → Flow A |
| Summary (if there are past plans) | See Flow D |

## Flow B — Generate the weekly plan (**the core of the MVP**)

| # | Data requested | Type | Required | Processed by |
|---|---|---|---|---|
| 1 | Available ingredients | multi-select checklist (preloaded by region) + free-text "other" | Yes (min. 1) | P2 filters the RAG |
| 2 | Weekly budget (S/) | number | Yes | P2, as a constraint |
| — | age, region, hemoglobin | *(automatic, from the profile)* | — | P1/P2 |

**On pressing "Generar mi plan":**

```
P2 → buscarRecetasRelevantes(ingredientes, presupuesto, edad, region)
     → top 5 recipes from the INS recipe book (local RAG)

P1 → Gemma generates the 7-day plan with those recipes as context:
     - WITH hemoglobin: "deficit of X mg, prioritise iron density"
     - WITHOUT hemoglobin: "standard preventive plan for age X,
       daily requirement Y mg" (fixed table)

P2 → calcularHierroTotal(plan) vs requerimientoEstandarPorEdad(edad)
     → % coverage (works WITH or WITHOUT hemoglobin)
```

**Result screen:**

| Element | Source |
|---|---|
| Plan of 7 recipes | Gemma (P1) |
| Weekly iron coverage % | P2 |
| Notice when there is no hemoglobin | "Plan preventivo estándar — agrega el dato de tu Carné CRED para mayor precisión" |
| 🔊 button per recipe | Local TTS (P3) |
| "Preparado" checkbox per day | P4 → `planes_generados` |

## Flow C — Ingredient photo (STRETCH GOAL)

| # | Data | Type |
|---|---|---|
| 1 | Photo of the pantry/market | camera — replaces step 1 of Flow B |
| 2 | Confirm/edit the detected ingredients | **always editable** checklist (the model can get it wrong) |

The image is processed in memory and **discarded** — it is never written to disk.

⚠️ **Not an MVP requirement.** Only after the hour-4 checkpoint and only if the team is ahead.

## Flow D — Weekly follow-up

| Element | Source |
|---|---|
| "Cumpliste 5 de 7 recetas la semana pasada" | P4 reads `planes_generados` |
| "Recibió ~27mg de hierro de una meta de 35mg" | P2 recomputes |
| Adjusting the next plan | If it fell short, P2 prioritises higher iron density |

It asks for no new data — only reading + recomputation when returning to Flow B.
