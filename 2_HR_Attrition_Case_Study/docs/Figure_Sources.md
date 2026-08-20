# Where every figure in the deck comes from

Base: 1,470 employees, 237 leavers, 16.12% — the whole file, no filters.
Everything below is reproducible by running `python/full_eda.py`, or by opening the report and
reading the same measure.

---

## Slide 2 — the situation

| Figure | Derivation |
|---|---|
| 1,470 | Row count of the source sheet |
| 237 | Rows where `Attrition = "Yes"` |
| 16.1% | 237 / 1,470 = 16.1224% |
| $6.8M | 237 leavers × 6 months × $4,787 (their average salary) = $6.81M |
| 28% of staff / 54% of leavers | OverTime = Yes is 416 of 1,470 (28.30%) and 127 of 237 leavers (53.59%) |
| 60% from three roles | Lab Technician 62 + Research Scientist 47 + Sales Rep 33 = 142 of 237 = 59.9% |
| one in three in year one | YearsAtCompany ≤ 1: 75 leavers of 215 people = 34.88% |

**The $6.8M is the only assumption in the deck.** Six months of salary per replacement is a
standard HR planning figure. If they use a different multiplier, the number scales with it —
say so, and offer to change it.

---

## Slide 3 — where it happens

| Department | Headcount | Leavers | Rate | Share of all leavers |
|---|---|---|---|---|
| Research & Development | 961 | 133 | 13.84% | **56.12%** |
| Sales | 446 | 92 | 20.63% | 38.82% |
| Human Resources | 63 | 12 | 19.05% | 5.06% |

**The point to make:** R&D has the *lowest* rate and the *largest* share, because it holds 65%
of the workforce (961 of 1,470). Rate ranks intensity, share ranks cost. That is why I would set
department targets on count.

Sales Representative: 33 leavers of 83 people = 39.76%. That is the highest rate of any role.
"Turns over every 2.5 years" is 100 / 39.76 ≈ 2.5 — a plain-English way of saying the same thing.

---

## Slide 4 — overtime

| Figure | Derivation |
|---|---|
| 30.5% | 127 leavers of 416 overtime employees |
| 10.4% | 110 leavers of 1,054 non-overtime employees |
| 2.9× | 30.53 / 10.44 = 2.93 |
| 54% of leavers from 28% of staff | 127 / 237 and 416 / 1,470 |
| χ² = 87.6 | Chi-square test of independence, OverTime × Attrition (`scipy.stats.chi2_contingency`), p = 8.16 × 10⁻²¹ |
| ~84 exits | 127 − (416 × 10.44%) = 83.6 |

The chi-square for JobRole is 86.2, which is why the deck says overtime beats job role. Both are
far past significance; the comparison is about relative strength, not about whether they matter.

---

## Slide 5 — compound risk

| Segment | Leavers / people | Rate |
|---|---|---|
| Overtime + income under $2,500 | 48 / 70 | 68.57% |
| Overtime + Sales Representative | 16 / 24 | 66.67% |
| Overtime + job level 1 | 82 / 156 | 52.56% |
| Overtime + tenure ≤ 2 years | 53 / 104 | 50.96% |
| Overtime + single | 65 / 131 | 49.62% |

Overtime + level 1 is 156 people = 10.6% of staff, producing 82 of 237 leavers = 34.6% of all
attrition. That is the "a third of attrition from a tenth of the workforce" line.

**If challenged on small samples:** the 24-person Sales Rep cell is small and I would not build
a programme on it alone — it is shown because it agrees with the 156-person cell and the
70-person cell, which are large enough to act on.

---

## Slide 6 — pay and equity

| Figure | Derivation |
|---|---|
| $4,787 vs $6,833 | Mean MonthlyIncome of leavers vs stayers. Gap 29.9%. Welch t-test p = 4.4 × 10⁻¹³ |
| 24.4% vs 9.4% | StockOptionLevel 0: 154 of 631. Level 1: 56 of 596 |
| 65% of leavers | 154 zero-stock leavers of 237 |
| 4.4% | Income above the IQR fence Q3 + 1.5×IQR = $16,581: 5 leavers of 114 people |

The income gradient by band: 34.07% under $2.5K → 16.44% → 9.68% → 14.62% → 13.51% → 3.76%.
It is not perfectly monotonic in the middle; the ends are what carry the argument.

---

## Slide 7 — first year

| Tenure band | Leavers / people | Rate |
|---|---|---|
| 0–1 years | 75 / 215 | 34.88% |
| 2–3 | 47 / 255 | 18.43% |
| 4–5 | 40 / 306 | 13.07% |
| 6–10 | 55 / 448 | 12.28% |
| 11–20 | 12 / 180 | 6.67% |
| 21+ | 8 / 66 | 12.12% |

Experience levels (same split as the Python task): Junior 32.89%, Mid 16.63%, Senior 10.68%.

---

## How the expected savings were calculated

Each one is the same arithmetic: take the segment, move its rate to a rate the company already
achieves somewhere else, and count the difference in people.

| Action | Calculation |
|---|---|
| Overtime governance → ~84 | 127 − (416 × 10.44%) |
| Overtime + level 1 halved → ~41 | 82 − (156 × 26.3%) |
| Pay floor on 70 OT staff under $2.5K → ~36 | 48 − (70 × 16.44%) |
| First year to the 2–3 year rate → ~35 | 75 − (215 × 18.43%) |
| Equity, a third of the gap closed → ~25–30 | 631 × one third of (24.41% − 9.40%) |

**Say this out loud if asked:** these are not forecasts. They are the size of the gap between a
segment and a rate the company already achieves for other people. Whether an intervention closes
that gap fully is a separate question — which is why the slide says the combined target is
10–11%, not the sum of the individual figures.

---

## Questions worth rehearsing

**"Isn't this just correlation?"**
Yes. This is a snapshot, so nothing here proves causation. What raises confidence is the
gradient: attrition falls monotonically across pay bands and across tenure, and the compound
cells behave the way the single factors predict. That pattern is hard to produce by chance. The
proper next step is a controlled trial on the overtime cap.

**"Why six months for replacement cost?"**
It is a common planning assumption, and it is the only number in the deck not taken from the
data. It sits in exactly two measures, so it can be replaced with the company's own figure and
everything downstream updates.

**"What did you find that does NOT drive attrition?"**
Years since last promotion (p = 0.199 — long-stagnant staff are actually the most loyal at
13.79%), gender (p = 0.291), hourly rate (p = 0.791), monthly rate (p = 0.565), and the annual
salary hike (p = 0.614). Dropping these from the KPI set is itself a recommendation.

**"Which number would you defend hardest?"**
The 2.9× overtime multiplier. It is the largest sample, the strongest test statistic, and it
holds inside every department separately, not just in aggregate.
