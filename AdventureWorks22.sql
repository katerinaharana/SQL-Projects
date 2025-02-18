use AdventureWorks2022
--1 a list of all employees with their BusinessEntityID, JobTitle, and HireDate.
SELECT 
    e.BusinessEntityID, 
    e.JobTitle, 
    e.HireDate
FROM HumanResources.Employee e;

--2 the number of employees who are currently assigned to each department. 

SELECT
    d.Name AS DepartmentName,
    COUNT(e.BusinessEntityID) AS EmployeeCount
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d 
    ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL
GROUP BY d.Name
ORDER BY EmployeeCount DESC; 

--3 total monthly salary of all employees from the EmployeePayHistory table
-- (note:multiple rate instances for the same employee) 
WITH EmployeeLatestSalary AS (
    SELECT 
        ep.BusinessEntityID, 
        ep.Rate AS HourlyRate, 
        ep.RateChangeDate,
        ROW_NUMBER() OVER (PARTITION BY ep.BusinessEntityID 
                           ORDER BY ep.RateChangeDate DESC) AS RowNum
    FROM HumanResources.EmployeePayHistory ep
)
SELECT 
    SUM(els.HourlyRate * 40 * 4.33) AS TotalMonthlySalary
FROM EmployeeLatestSalary els
WHERE els.RowNum = 1;

--2.4 List employees who have not received a salary increase in the last 2 years.

--using subquery for max rate per employee
SELECT 
    e.BusinessEntityID, 
    p.FirstName, 
    p.LastName, 
    e.JobTitle, 
    ep.Rate AS LatestRate, 
    ep.RateChangeDate
FROM HumanResources.Employee e
JOIN Person.Person p 
    ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.EmployeePayHistory ep 
    ON e.BusinessEntityID = ep.BusinessEntityID
WHERE ep.RateChangeDate = (
    SELECT MAX(ep2.RateChangeDate)
    FROM HumanResources.EmployeePayHistory ep2
    WHERE ep2.BusinessEntityID = e.BusinessEntityID
);
 --different approach using Row Number
WITH EmployeeLatestSalary AS (
    SELECT 
        ep.BusinessEntityID, 
        ep.Rate AS LatestSalary, 
        ep.RateChangeDate,
        ROW_NUMBER() OVER (PARTITION BY ep.BusinessEntityID 
                           ORDER BY ep.RateChangeDate DESC) AS RowNum
    FROM HumanResources.EmployeePayHistory ep
)
SELECT 
    e.BusinessEntityID, 
    p.FirstName, 
    p.LastName, 
    e.JobTitle, 
    els.LatestSalary, 
    els.RateChangeDate
FROM HumanResources.Employee e
JOIN Person.Person p 
    ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON e.BusinessEntityID = edh.BusinessEntityID
JOIN EmployeeLatestSalary els 
    ON e.BusinessEntityID = els.BusinessEntityID
WHERE els.RowNum = 1;  -- Ensures only the latest salary per employee

-- using min and groupby
SELECT 
    e.BusinessEntityID, 
    e.JobTitle, 
    e.HireDate, 
    MIN(ep.RateChangeDate) AS RateChangeDate  -- Or MAX() for latest
FROM HumanResources.Employee e
JOIN HumanResources.EmployeePayHistory ep 
    ON e.BusinessEntityID = ep.BusinessEntityID
WHERE ep.RateChangeDate <= DATEADD(YEAR, -2, '2022-12-31')
GROUP BY e.BusinessEntityID, e.JobTitle, e.HireDate;


--2.5 a list of employees and their department names. Include only employees who belong to departments with DepartmentID less than 10
--and who have not received a salary increase in the last 2 years

SELECT DISTINCT 
    e.BusinessEntityID, 
    e.JobTitle, 
    e.HireDate, 
    d.DepartmentID,
    d.Name AS DepartmentName, 
    ep.RateChangeDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeePayHistory ep 
    ON e.BusinessEntityID = ep.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d 
    ON edh.DepartmentID = d.DepartmentID
WHERE ep.RateChangeDate = (
    SELECT MAX(RateChangeDate) 
    FROM HumanResources.EmployeePayHistory 
    WHERE BusinessEntityID = e.BusinessEntityID
)

AND ep.RateChangeDate <= DATEADD(YEAR, -2, '2022-12-31')  -- Employees whose last raise was before 31.12.2022
AND edh.EndDate IS NULL  -- Ensures only current department assignments
AND d.DepartmentID < 10  -- Filters only departments with ID less than 10
ORDER BY d.Name;

--2.6 VIEW named EmployeeSalaryOverview that shows each employee's name, job title, department name, and most recent salary.

CREATE VIEW EmployeeSalaryOverview AS
SELECT 
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    e.JobTitle,
    d.Name AS DepartmentName,
    eph.Rate AS MostRecentSalary
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
JOIN HumanResources.EmployeePayHistory eph ON e.BusinessEntityID = eph.BusinessEntityID
WHERE eph.RateChangeDate = (
    SELECT MAX(RateChangeDate) 
    FROM HumanResources.EmployeePayHistory eph_sub
    WHERE eph_sub.BusinessEntityID = e.BusinessEntityID
)

--2.7 CTE 
WITH RankedEmployees AS (
    SELECT
        p.FirstName + ' ' + p.LastName AS EmployeeName,  -- Combine First and Last name
        e.JobTitle,
        d.Name AS DepartmentName,
        eph.Rate AS Salary,  -- Employee's most recent salary
        ROW_NUMBER() OVER (PARTITION BY d.DepartmentID ORDER BY eph.Rate DESC) AS SalaryRank  -- Ranking employees by salary in each department
    FROM HumanResources.Employee e
    JOIN Person.Person p 
        ON e.BusinessEntityID = p.BusinessEntityID
    JOIN HumanResources.EmployeeDepartmentHistory edh 
        ON e.BusinessEntityID = edh.BusinessEntityID
    JOIN HumanResources.Department d 
        ON edh.DepartmentID = d.DepartmentID
    JOIN HumanResources.EmployeePayHistory eph 
        ON e.BusinessEntityID = eph.BusinessEntityID
    WHERE eph.RateChangeDate = (
        SELECT MAX(RateChangeDate) 
        FROM HumanResources.EmployeePayHistory 
        WHERE BusinessEntityID = e.BusinessEntityID
    )
    AND edh.EndDate IS NULL  -- Ensures only employees who are currently in the department
)
-- Main Query to fetch the top 5 highest-paid employees per department
SELECT EmployeeName, JobTitle, DepartmentName, Salary
FROM RankedEmployees
WHERE SalaryRank <= 5  -- Filter to get only the top 5 highest-paid employees
ORDER BY DepartmentName, Salary DESC;  -- Sort by department and salary
