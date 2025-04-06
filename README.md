# 📘 AdventureWorks2022 SQL Queries - Employee & Salary Analysis

This project contains a set of SQL queries targeting employee and salary data in the **AdventureWorks2022** sample database using **SQL Server**.

## 💾 Database
- **Database Name**: `AdventureWorks2022`
- **Schemas Used**: `HumanResources`, `Person`

## 🛠 Requirements
- Microsoft SQL Server (2019+ recommended)
- AdventureWorks2022 sample database installed

---

##  Query Summary

### 1. List All Employees
```sql
SELECT BusinessEntityID, JobTitle, HireDate 
FROM HumanResources.Employee;
```
- **Purpose**: Display all employees with their ID, job title, and hire date.

---

### 2. Number of Employees per Department (Currently Assigned)
```sql
-- Counts active employees per department using JOINs and GROUP BY
```
- **Logic**:
  - Joins `Employee`, `EmployeeDepartmentHistory`, and `Department`
  - Filters to only current assignments (`EndDate IS NULL`)
  - Groups by department name
- **Returns**: Department name and employee count

---

### 3. Total Monthly Salary (Latest Rate per Employee)
```sql
-- Uses a CTE and ROW_NUMBER to get the latest pay rate per employee
```
- **Assumptions**: 
  - 40 hours/week × 4.33 weeks/month
- **Output**: Sum of estimated monthly salaries for all employees

---

### 4. Employees Without a Raise in the Last 2 Years

#### 🔹 Method 1: Subquery for Max RateChangeDate
```sql
-- Gets latest rate change per employee using correlated subquery
```

#### 🔹 Method 2: CTE + ROW_NUMBER()
```sql
-- Uses ROW_NUMBER to filter out only the latest salary per employee
```

#### 🔹 Method 3: GROUP BY + MIN/MAX
```sql
-- Uses aggregation and a date filter (before 2020-12-31) to identify old salary records
```

---

### 5. Employees in Departments (ID < 10) & No Raise in 2+ Years
```sql
-- Combines salary and department filters to list employees who haven't received a raise
-- in over 2 years AND belong to departments with ID < 10
```
- **Filters**:
  - `RateChangeDate` before `2020-12-31`
  - `DepartmentID < 10`
  - `EndDate IS NULL` (still active in department)

---

### 6. View: `EmployeeSalaryOverview`
```sql
CREATE VIEW EmployeeSalaryOverview AS
...
```
- **Purpose**: Create a reusable view showing:
  - Employee full name
  - Job title
  - Department name
  - Most recent salary
- **Logic**:
  - Joins with `Person` table for names
  - Filters to the most recent `RateChangeDate`

---

### 7. Top 5 Highest Paid Employees per Department

#### ✅ CTE: `RankedEmployees`
```sql
-- Uses ROW_NUMBER() to rank employees by salary within each department
-- Filters top 5 per department
```
- **Logic**:
  - Partition by `DepartmentID`
  - Order by `Rate` descending
- **Filters**:
  - Latest salary per employee
  - Current department assignment only (`EndDate IS NULL`)

---

## 📁 Tables Used

| Table Name                                 | Description                          |
|-------------------------------------------|--------------------------------------|
| `HumanResources.Employee`                 | Core employee data                   |
| `HumanResources.EmployeePayHistory`       | Employee salary change history       |
| `HumanResources.Department`               | Department metadata                  |
| `HumanResources.EmployeeDepartmentHistory`| Historical department assignments    |
| `Person.Person`                           | Names of employees                   |

---
---

## 🧾 License
This project uses publicly available Microsoft sample data and is intended for **educational and demonstration purposes only**.
