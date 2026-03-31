-- queries.sql — SQL Analytics Lab
-- Module 3: SQL & Relational Data
--
-- Instructions:
--   Write your SQL query beneath each comment block.
--   Do NOT modify the comment markers (-- Q1, -- Q2, etc.) — the autograder uses them.
--   Test each query locally: psql -h localhost -U postgres -d testdb -f queries.sql
--
-- ============================================================
select * from employees;
-- Q1: Employee Directory with Departments
-- List all employees with their department name, sorted by department (asc) then salary (desc).
-- Expected columns: first_name, last_name, title, salary, department_name
-- SQL concepts: JOIN, ORDER BY
SELECT e.first_name, e.last_name, e.title, e.salary, d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name ASC, e.salary DESC;

-- Q2: Department Salary Analysis
-- Total salary expenditure by department. Only departments with total > 150,000.
-- Expected columns: department_name, total_salary
-- SQL concepts: GROUP BY, HAVING, SUM
SELECT d.name AS department_name, SUM(e.salary) AS total_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.name
HAVING SUM(e.salary) > 150000;

-- Q3: Highest-Paid Employee per Department
-- For each department, find the employee with the highest salary.
-- Expected columns: department_name, first_name, last_name, salary
-- SQL concepts: Window function (ROW_NUMBER or RANK), CTE
WITH ranked AS (
    SELECT e.first_name, e.last_name, e.salary, d.name AS department_name,
           ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS rn
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
)
SELECT first_name, last_name, salary, department_name
FROM ranked
WHERE rn = 1;

-- Q4: Project Staffing Overview
-- All projects with employee count and total hours. Include projects with 0 assignments.
-- Expected columns: project_name, employee_count, total_hours
-- SQL concepts: LEFT JOIN, GROUP BY, COALESCE
SELECT p.name AS project_name,
       COUNT(pa.employee_id) AS employee_count,
       COALESCE(SUM(pa.hours_allocated),0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.name;

-- Q5: Above-Average Departments
-- Departments where average salary exceeds the company-wide average salary.
-- Expected columns: department_name, avg_salary
-- SQL concepts: CTE

WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
),
company_avg AS (
    SELECT AVG(salary) AS avg_salary FROM employees
)
SELECT d.name AS department_name, da.avg_salary
FROM dept_avg da
JOIN departments d ON da.department_id = d.department_id
CROSS JOIN company_avg ca
WHERE da.avg_salary > ca.avg_salary;
-- Q6: Running Salary Total
-- Each employee's salary and running total within their department, ordered by hire date.
-- Expected columns: department_name, first_name, last_name, hire_date, salary, running_total
-- SQL concepts: Window function (SUM OVER)
SELECT d.name AS department_name, e.first_name, e.last_name, e.hire_date, e.salary,
       SUM(e.salary) OVER (PARTITION BY e.department_id ORDER BY e.hire_date) AS running_total
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name, e.hire_date;

-- Q7: Unassigned Employees
-- Employees not assigned to any project.
-- Expected columns: first_name, last_name, department_name
-- SQL concepts: LEFT JOIN + NULL check (or NOT EXISTS)
SELECT e.first_name, e.last_name, d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
LEFT JOIN project_assignments pa ON e.employee_id = pa.employee_id
WHERE pa.employee_id IS NULL;

-- Q8: Hiring Trends
-- Month-over-month hire count.
-- Expected columns: hire_year, hire_month, hires
-- SQL concepts: EXTRACT, GROUP BY, ORDER BY
SELECT EXTRACT(YEAR FROM hire_date) AS hire_year,
       EXTRACT(MONTH FROM hire_date) AS hire_month,
       COUNT(*) AS hires
FROM employees
GROUP BY hire_year, hire_month
ORDER BY hire_year, hire_month;

-- Q9: Schema Design — Employee Certifications
-- Design and implement a certifications tracking system.
--
-- Tasks:
-- 1. CREATE TABLE certifications (certification_id SERIAL PK, name VARCHAR NOT NULL, issuing_org VARCHAR, level VARCHAR)
-- 2. CREATE TABLE employee_certifications (id SERIAL PK, employee_id FK->employees, certification_id FK->certifications, certification_date DATE NOT NULL)
-- 3. INSERT at least 3 certifications and 5 employee_certification records
-- 4. Write a query listing employees with their certifications (JOIN across 3 tables)
--    Expected columns: first_name, last_name, certification_name, issuing_org, certification_date
CREATE TABLE if NOT EXISTS certifications (
    certification_id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    issuing_org VARCHAR,
    level VARCHAR
);
CREATE TABLE if NOT EXISTS employee_certifications (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    certification_id INT REFERENCES certifications(certification_id),
    certification_date DATE NOT NULL
);
INSERT INTO certifications (name, issuing_org, level) VALUES
('AWS Certified', 'Amazon', 'Advanced'),
('Scrum Master', 'Scrum Org', 'Intermediate'),
('Data Analyst', 'Google', 'Beginner');

INSERT INTO employee_certifications (employee_id, certification_id, certification_date) VALUES
(1, 1, '2023-01-01'),
(2, 2, '2023-02-01'),
(3, 3, '2023-03-01'),
(1, 2, '2023-04-01'),
(4, 1, '2023-05-01');

SELECT e.first_name, e.last_name, c.name AS certification_name,
       c.issuing_org, ec.certification_date
FROM employee_certifications ec
JOIN employees e ON ec.employee_id = e.employee_id
JOIN certifications c ON ec.certification_id = c.certification_id
ORDER BY e.last_name, e.first_name, ec.certification_date;

--  Q10 Complex Analytics Queries
SELECT p.project_id,
       p.name,
       p.budget,
       COALESCE(SUM(pa.hours_allocated), 0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa
    ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget
HAVING COALESCE(SUM(pa.hours_allocated), 0) > 0.8 * p.budget;


SELECT e.name AS employee_name,
       e.dept_id AS employee_dept,
       p.name AS project_name,
       p.dept_id AS project_dept
FROM employees e
JOIN project_assignments pa ON e.emp_id = pa.emp_id
JOIN projects p ON pa.project_id = p.project_id
WHERE e.dept_id <> p.dept_id;

-- Q11 Dynamic Reporting with Views and Functions
CREATE VIEW department_summary AS
SELECT d.name AS department_name,
       COUNT(e.emp_id) AS employee_count,
       COALESCE(SUM(e.salary), 0) AS total_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.name;

CREATE VIEW project_status AS
SELECT p.project_id,
       p.name AS project_name,
       COUNT(pa.emp_id) AS employee_count,
       COALESCE(SUM(pa.hours_allocated), 0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name;

CREATE OR REPLACE FUNCTION get_department_stats(dept_name_input TEXT)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'employee_count', COUNT(e.emp_id),
        'total_salary', COALESCE(SUM(e.salary), 0),
        'project_count', COUNT(DISTINCT p.project_id)
    )
    INTO result
    FROM departments d
    LEFT JOIN employees e ON d.dept_id = e.dept_id
    LEFT JOIN projects p ON d.dept_id = p.dept_id
    WHERE d.name = dept_name_input;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Q12 Schema Evolution and Migration
CREATE TABLE salary_history (
    id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES employees(emp_id) ON DELETE CASCADE,
    salary NUMERIC NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE
);

INSERT INTO salary_history (emp_id, salary, start_date, end_date) VALUES
(1, 1000, '2022-01-01', '2023-01-01'),
(1, 1200, '2023-01-01', '2024-01-01'),
(1, 1500, '2024-01-01', NULL),

(2, 2000, '2022-06-01', '2023-06-01'),
(2, 2200, '2023-06-01', NULL);

INSERT INTO salary_history (emp_id, salary, start_date, end_date)
SELECT emp_id,
       salary,
       hire_date,
       NULL
FROM employees;

SELECT d.name AS department,
       AVG(sh.salary) AS avg_salary
FROM salary_history sh
JOIN employees e ON sh.emp_id = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.name
ORDER BY avg_salary;

SELECT e.name, sh.salary, sh.start_date
FROM salary_history sh
JOIN employees e ON sh.emp_id = e.emp_id
WHERE sh.end_date IS NULL
  AND sh.start_date < CURRENT_DATE - INTERVAL '12 months';

  