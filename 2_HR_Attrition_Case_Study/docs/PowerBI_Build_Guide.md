# Power BI Build Guide — HR Attrition Case Study
**Deliverable for Tasks 1, 2 and 4** (star schema · DAX with variables · dashboards)
Follow this end-to-end and the .pbix is ready in ~45 minutes.

---

## 1. Star Schema (Task 1)

**Design decision — grain.** The dataset is a snapshot: one row per employee (no dates, no
transactions). The fact table therefore has **grain = employee**, holding the numeric facts
(income, tenure, scores) and the `Attrition` outcome flag, surrounded by dimensions that hold
descriptive attributes:

```
                 DimDepartment (3)      DimJobRole (9)
                        \                   /
                         \                 /
   DimTravel (3) ------- FactEmployee (1470) ------- DimEducation (30)
                              |
                       DimDemographics (30)
                       (Gender x MaritalStatus x AgeBand)
```

* All relationships: **1-to-many, single direction** (dimension → fact).
* Keys are surrogate integers (`DepartmentKey`, `JobRoleKey`, …) generated during load.
* Dropped columns (constant, zero information): `EmployeeCount` (=1), `Over18` (='Y'),
  `StandardHours` (=80).

**Two ways to load it — use A for speed, B to show Power Query skill:**

### Option A — load the prepared CSVs (folder `data/star_schema/`)
`FactEmployee.csv`, `DimDepartment.csv`, `DimJobRole.csv`, `DimEducation.csv`,
`DimDemographics.csv`, `DimTravel.csv`, `DimScoreLabels.csv`.
Get Data → Text/CSV → load all seven → Model view → connect each `*Key` to its dimension.

### Option B — build the dims in Power Query from the raw Excel (M below)
1. Get Data → Excel → `GBS BI HUB - BI Developer - HR Attrition Case Study (1).xlsx`,
   sheet `WA_Fn-UseC_-HR-Employee-Attriti` → rename query **Employees_Raw**, uncheck load.
2. For each dimension: **Reference** Employees_Raw → keep the attribute column(s) →
   Remove Duplicates → Sort → Add Index Column (from 1) → rename it `<Dim>Key`.
   Example M for DimJobRole:

```m
let
    Source = Employees_Raw,
    Keep   = Table.SelectColumns(Source, {"JobRole"}),
    Dedup  = Table.Distinct(Keep),
    Sorted = Table.Sort(Dedup, {{"JobRole", Order.Ascending}}),
    Key    = Table.AddIndexColumn(Sorted, "JobRoleKey", 1, 1, Int64.Type)
in
    Key
```

3. **FactEmployee**: Reference Employees_Raw → Merge (inner) with each dim on the natural
   column(s) → expand only the `*Key` → remove the natural columns that now live in dims →
   remove `EmployeeCount`, `Over18`, `StandardHours`.
4. Add the two banding columns used by the visuals (Add Column → Custom):

```m
// AgeBand (put in DimDemographics before dedup)
if [Age] <= 25 then "18-25" else if [Age] <= 35 then "26-35"
else if [Age] <= 45 then "36-45" else if [Age] <= 55 then "46-55" else "56-60"

// ExperienceLevel (matches SQL/Python Task 8)
if [TotalWorkingYears] < 5 then "Junior (<5)"
else if [TotalWorkingYears] <= 9 then "Mid (5-9)" else "Senior (10+)"
```

5. Close & Apply → Model view → create the five relationships (each `*Key` 1→*), set every
   dimension's key column **Hide in report view**, and sort `AgeBand` / `ExperienceLevel` by a
   hidden sort-order column.

## 2. Measures (Task 2)
Create an empty table `_Measures` (Enter Data → one dummy column → delete it after the first
measure). Paste every measure from **`DAX_Measures.dax`** — all of them use `VAR`/`RETURN`.
Core set used by the pages below: `Total Employees`, `Leavers`, `Attrition Rate %`,
`Attrition Rate (Company) %`, `Attrition vs Company (pp)`, `Avg Monthly Income`,
`Income Gap %`, `OverTime Risk Multiplier`, `% of Total Leavers`,
`Estimated Replacement Cost`, `High-Risk Headcount`, `Attrition Rate Income-Outliers %`.

## 3. Dashboard (Task 4) — three pages

> Theme: white background, one accent color for "leavers/risk" (red `#D64550`), one neutral
> (blue-grey `#31446C`). Titles 14pt bold, one-line insight subtitle under every page title.

### Page 1 — Executive Overview  *"Where do we stand?"*
| Zone | Visual | Fields / notes |
|---|---|---|
| KPI row (5 cards) | Card / KPI | `Total Employees` 1,470 · `Leavers` 237 · `Attrition Rate %` 16.1% · `Avg Monthly Income` $6.5K · `Estimated Replacement Cost` ≈ $6.8M |
| Left half | Clustered bar | Attrition Rate % by **JobRole**, constant line = 16.1% benchmark; data labels on; sorted desc — Sales Rep 39.8% jumps out |
| Right top | Column chart | Attrition Rate % by **Department** (Sales 20.6 / HR 19.0 / R&D 13.8) with `Total Employees` as tooltip |
| Right bottom | Donut | `% of Total Leavers` by Department — shows R&D contributes most leavers in absolute terms (133) despite lowest rate |
| Slicer panel | Slicers | Department · JobRole · Gender · AgeBand · ExperienceLevel (sync across pages) |

### Page 2 — Why they leave  *"Drivers & risk segments"*
| Zone | Visual | Fields / notes |
|---|---|---|
| Top left | 100% stacked bar | Attrition by **OverTime** — 30.5% vs 10.4%; add callout: `OverTime Risk Multiplier` = 2.9x |
| Top right | Clustered column | Attrition Rate % by **BusinessTravel** (Frequent 24.9 / Rare 15.0 / None 8.0) |
| Middle left | Line | Attrition Rate % by **IncomeBand** — falls from 34.1% (<2.5K) to 3.8% (15-20K) |
| Middle right | Heat matrix | Rows JobRole × Columns OverTime, values Attrition Rate %, conditional color — OT+SalesRep cell = **66.7%** |
| Bottom | Decomposition tree | `Leavers` explained by OverTime → JobLevel → MaritalStatus → IncomeBand (interview wow-factor: lets stakeholders explore) |
| Callout card | Card + text | "OverTime + JobLevel 1 = 52.6% attrition (82 of 156)" |

### Page 3 — Who is at risk  *"Tenure, outliers & watchlist"*
| Zone | Visual | Fields / notes |
|---|---|---|
| Top left | Area/line | Attrition Rate % by **TenureBand** — 34.9% in year 0-1 falling to 6.7% at 11-20y (onboarding cliff) |
| Top right | Column | Attrition Rate % by **ExperienceLevel** — Junior 32.9 / Mid 16.6 / Senior 10.7 |
| Middle left | Scatter | X = Age, Y = MonthlyIncome, color = Attrition, size = TotalWorkingYears — leavers cluster bottom-left; income outliers (>$16.6K fence, 114 people) almost never leave (4.4%) |
| Middle right | Box-style column | Attrition Rate % by **StockOptionLevel** (0: 24.4% vs 1: 9.4%) and by **JobSatisfaction** (1: 22.8% → 4: 11.3%) |
| Bottom | Table "Watchlist" | Active employees with OverTime=Yes & JobLevel=1: Name-less list by EmployeeNumber, Dept, Role, Income, `Attrition Risk Flag` conditional icons — ~*156-82=74 current staff in the 52.6% profile* |

**Interactions & polish**
* Sync slicers across pages (View → Sync slicers).
* Tooltips: add `Total Employees` + `% of Total Leavers` to every rate visual so small bases are visible.
* Enable drill-through on JobRole → a hidden "Role detail" page if time allows.
* Mobile layout: KPI cards + top-2 charts only.

## 4. Validation numbers (must match after build)
| Check | Value |
|---|---|
| Total Employees | 1,470 |
| Leavers | 237 |
| Attrition Rate % | 16.12% |
| Attrition Rate OT % / No-OT % | 30.53% / 10.44% |
| Sales Rep attrition | 39.76% (33/83) |
| Junior / Mid / Senior counts | 228 / 493 / 749 |
| Avg income leavers vs stayers | $4,787 vs $6,833 |
| Income-outlier attrition | 4.39% (114 employees above $16,581) |
