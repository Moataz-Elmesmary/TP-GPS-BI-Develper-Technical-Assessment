"""HR Attrition - Task 8
Classify employees by total working years and count them per level."""

import pandas as pd

SOURCE = "../data/HR_Attrition_CaseStudy_Source.xlsx"
SHEET = "WA_Fn-UseC_-HR-Employee-Attriti"

df = pd.read_excel(SOURCE, sheet_name=SHEET)

# Junior < 5, Mid 5-9, Senior 10+
df["ExperienceLevel"] = pd.cut(
    df["TotalWorkingYears"],
    bins=[-1, 4, 9, df["TotalWorkingYears"].max()],
    labels=["Junior (<5)", "Mid (5-9)", "Senior (10+)"],
)

summary = (
    df.groupby("ExperienceLevel", observed=True)
      .size()
      .reset_index(name="EmployeeCount")
)

print(summary.to_string(index=False))

# ExperienceLevel  EmployeeCount
#     Junior (<5)            228
#       Mid (5-9)            493
#    Senior (10+)            749


# Attrition by the same split - juniors leave three times more often than seniors
attrition = (
    df.assign(Left=df["Attrition"].eq("Yes"))
      .groupby("ExperienceLevel", observed=True)
      .agg(EmployeeCount=("Left", "size"),
           Leavers=("Left", "sum"),
           AttritionRate=("Left", lambda s: round(s.mean() * 100, 2)))
      .reset_index()
)

print()
print(attrition.to_string(index=False))
