-- HR Attrition — Task 7
-- Star schema built in Power BI: FactEmployee (grain = one row per employee)
-- joined to DimDepartment and DimJobRole on their surrogate keys.
-- Written in ANSI SQL; runs unchanged on SQL Server, PostgreSQL and SQLite.


-- ---------------------------------------------------------------------------
-- Schema (same shape as the Power BI model)
-- ---------------------------------------------------------------------------
CREATE TABLE DimDepartment (
    DepartmentKey  INT PRIMARY KEY,
    Department     VARCHAR(50) NOT NULL
);

CREATE TABLE DimJobRole (
    JobRoleKey     INT PRIMARY KEY,
    JobRole        VARCHAR(50) NOT NULL
);

CREATE TABLE FactEmployee (
    EmployeeNumber    INT PRIMARY KEY,
    DepartmentKey     INT NOT NULL REFERENCES DimDepartment (DepartmentKey),
    JobRoleKey        INT NOT NULL REFERENCES DimJobRole (JobRoleKey),
    Attrition         VARCHAR(3)  NOT NULL,   -- 'Yes' / 'No'
    OverTime          VARCHAR(3)  NOT NULL,
    MonthlyIncome     DECIMAL(10,2),
    JobLevel          INT,
    TotalWorkingYears INT,
    YearsAtCompany    INT
);


-- ---------------------------------------------------------------------------
-- Required output: attrition count and average monthly income per
-- Department and JobRole, ordered by attrition count descending.
-- ---------------------------------------------------------------------------
SELECT
      d.Department
    , j.JobRole
    , SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS AttritionCount
    , ROUND(AVG(f.MonthlyIncome), 2)                       AS AvgMonthlyIncome
FROM FactEmployee AS f
JOIN DimDepartment AS d ON d.DepartmentKey = f.DepartmentKey
JOIN DimJobRole    AS j ON j.JobRoleKey    = f.JobRoleKey
GROUP BY
      d.Department
    , j.JobRole
ORDER BY
      AttritionCount DESC;

-- Top of the result set:
--   Research & Development | Laboratory Technician | 62 | 3237.17
--   Sales                  | Sales Executive       | 57 | 6924.28
--   Research & Development | Research Scientist    | 47 | 3239.97
--   Sales                  | Sales Representative  | 33 | 2626.00
--   Human Resources        | Human Resources       | 12 | 4235.75


-- ---------------------------------------------------------------------------
-- Same grouping with headcount and rate. A count on its own hides the base
-- size: Sales Representative is only 33 leavers but 40% of the role.
-- ---------------------------------------------------------------------------
SELECT
      d.Department
    , j.JobRole
    , COUNT(*)                                             AS Headcount
    , SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS AttritionCount
    , ROUND(100.0 * SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END)
            / COUNT(*), 2)                                 AS AttritionRatePct
    , ROUND(AVG(f.MonthlyIncome), 2)                       AS AvgMonthlyIncome
FROM FactEmployee AS f
JOIN DimDepartment AS d ON d.DepartmentKey = f.DepartmentKey
JOIN DimJobRole    AS j ON j.JobRoleKey    = f.JobRoleKey
GROUP BY d.Department, j.JobRole
ORDER BY AttritionRatePct DESC;


-- ---------------------------------------------------------------------------
-- Overtime split inside each department, with the department's own rate
-- alongside it for comparison.
-- ---------------------------------------------------------------------------
SELECT
      d.Department
    , f.OverTime
    , COUNT(*)                                             AS Headcount
    , ROUND(100.0 * SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END)
            / COUNT(*), 2)                                 AS AttritionRatePct
    , ROUND(100.0 * SUM(SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END))
                    OVER (PARTITION BY d.Department)
            / SUM(COUNT(*)) OVER (PARTITION BY d.Department), 2)
                                                           AS DeptRatePct
FROM FactEmployee AS f
JOIN DimDepartment AS d ON d.DepartmentKey = f.DepartmentKey
GROUP BY d.Department, f.OverTime
ORDER BY d.Department, f.OverTime;


-- ---------------------------------------------------------------------------
-- Pay gap between leavers and stayers per role. A positive gap means the
-- people who left were the lower paid ones in that role.
-- ---------------------------------------------------------------------------
SELECT
      j.JobRole
    , ROUND(AVG(CASE WHEN f.Attrition = 'Yes' THEN f.MonthlyIncome END), 0) AS AvgIncomeLeavers
    , ROUND(AVG(CASE WHEN f.Attrition = 'No'  THEN f.MonthlyIncome END), 0) AS AvgIncomeStayers
    , ROUND(AVG(CASE WHEN f.Attrition = 'No'  THEN f.MonthlyIncome END)
          - AVG(CASE WHEN f.Attrition = 'Yes' THEN f.MonthlyIncome END), 0) AS PayGap
FROM FactEmployee AS f
JOIN DimJobRole AS j ON j.JobRoleKey = f.JobRoleKey
GROUP BY j.JobRole
ORDER BY PayGap DESC;
