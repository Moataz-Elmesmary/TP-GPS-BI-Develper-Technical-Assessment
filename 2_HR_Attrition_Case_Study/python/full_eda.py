"""Exploratory analysis behind the dashboard.
Reproduces every figure quoted in the report and the presentation."""

import pandas as pd

pd.set_option("display.width", 130)

SOURCE = "../data/HR_Attrition_CaseStudy_Source.xlsx"
SHEET = "WA_Fn-UseC_-HR-Employee-Attriti"

df = pd.read_excel(SOURCE, sheet_name=SHEET)
df["Left"] = df["Attrition"].eq("Yes")

print(f"{len(df)} employees, {df.Left.sum()} leavers, rate {df.Left.mean():.2%}")
print("nulls:", int(df.isna().sum().sum()),
      "| duplicate EmployeeNumber:", int(df.EmployeeNumber.duplicated().sum()))
print("single-value columns (dropped from the model):",
      [c for c in df.columns if df[c].nunique() == 1])


def by(col):
    out = (df.groupby(col)
             .agg(Headcount=("Left", "size"),
                  Leavers=("Left", "sum"),
                  RatePct=("Left", lambda s: round(s.mean() * 100, 2)))
             .sort_values("RatePct", ascending=False))
    print(f"\n{col}")
    print(out.to_string())


for col in ["OverTime", "JobRole", "Department", "BusinessTravel", "MaritalStatus",
            "JobLevel", "StockOptionLevel", "JobSatisfaction",
            "EnvironmentSatisfaction", "WorkLifeBalance"]:
    by(col)

df["AgeBand"] = pd.cut(df.Age, [17, 25, 35, 45, 55, 61],
                       labels=["18-25", "26-35", "36-45", "46-55", "56-60"])
df["IncomeBand"] = pd.cut(df.MonthlyIncome, [0, 2500, 5000, 7500, 10000, 15000, 20000],
                          labels=["<2.5K", "2.5-5K", "5-7.5K", "7.5-10K", "10-15K", "15-20K"])
df["TenureBand"] = pd.cut(df.YearsAtCompany, [-1, 1, 3, 5, 10, 20, 41],
                          labels=["0-1", "2-3", "4-5", "6-10", "11-20", "21+"])

for col in ["AgeBand", "IncomeBand", "TenureBand"]:
    by(col)


# Where two risk factors land on the same people
print("\ncompound segments")
segments = {
    "overtime + income under 2.5K": df.OverTime.eq("Yes") & df.MonthlyIncome.lt(2500),
    "overtime + Sales Rep":         df.OverTime.eq("Yes") & df.JobRole.eq("Sales Representative"),
    "overtime + job level 1":       df.OverTime.eq("Yes") & df.JobLevel.eq(1),
    "overtime + tenure <= 2y":      df.OverTime.eq("Yes") & df.YearsAtCompany.le(2),
    "overtime + single":            df.OverTime.eq("Yes") & df.MaritalStatus.eq("Single"),
    "first-year employees":         df.YearsAtCompany.le(1),
}
for name, mask in segments.items():
    print(f"  {name:30s} {df[mask].Left.mean():6.2%}  (n={mask.sum()})")


print("\nleavers vs stayers")
print(df.groupby("Attrition")[["Age", "MonthlyIncome", "TotalWorkingYears", "YearsAtCompany",
                               "YearsWithCurrManager", "DistanceFromHome",
                               "TrainingTimesLastYear"]].mean().round(2).to_string())


# IQR fences: anything past Q3 + 1.5*IQR is an outlier
print("\noutliers")
for col in ["MonthlyIncome", "YearsAtCompany", "TotalWorkingYears", "YearsSinceLastPromotion"]:
    q1, q3 = df[col].quantile([0.25, 0.75])
    fence = q3 + 1.5 * (q3 - q1)
    out = df[df[col] > fence]
    print(f"  {col:24s} fence > {fence:8.1f}   n={len(out):4d}   "
          f"their attrition {out.Left.mean():6.2%}  (company 16.12%)")
