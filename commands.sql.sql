-- Cleaning up before creating new tables
DROP TABLE IF EXISTS Employment;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Education;
DROP TABLE IF EXISTS Job;
DROP TABLE IF EXISTS Location;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Salary;
DROP VIEW original_view;

/* DDL queries to build the database designed in the ERD*/

CREATE TABLE Education(
    edu_id SERIAL PRIMARY KEY,
    edu_level VARCHAR(50)
);

CREATE TABLE Employee(
    emp_id VARCHAR(8) PRIMARY KEY,
    emp_nm VARCHAR(50), 
    email VARCHAR(50),
    hire_dt DATE,
    edu_id INT REFERENCES Education(edu_id)
);

CREATE TABLE Job(
    job_id SERIAL PRIMARY KEY,
    job_title VARCHAR(50)
);

CREATE TABLE Location(
    loc_id SERIAL PRIMARY KEY,
    location VARCHAR(50),
    address VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50)
);

CREATE TABLE Department(
    dept_id SERIAL PRIMARY KEY,
    dept_nm VARCHAR(50)
);

CREATE TABLE Salary(
    salary_id SERIAL PRIMARY KEY,
    salary INT
);

CREATE TABLE Employment(
    emp_id VARCHAR(8),
    dept_id INT,
    manager_id VARCHAR(8),
    job_id INT,
    loc_id INT,
    salary_id INT REFERENCES Salary(salary_id),
    start_dt DATE,
    end_dt DATE,
PRIMARY KEY (emp_id, start_dt)
);

/* DML queries to insert the data in the database from staging table*/

INSERT INTO Education(edu_level)
Select distinct(education_lvl) from proj_stg;

INSERT INTO Employee(emp_id, emp_nm, email, hire_dt, edu_id)
select distinct ps.emp_id, ps.emp_nm, ps.email, ps.hire_dt, ed.edu_id from proj_stg as ps
inner join Education ed on ed.edu_level=ps.education_lvl;

INSERT INTO Job(job_title)
select distinct job_title from proj_stg;

INSERT INTO Location(location, address, city, state)
select distinct location, address, city, state from proj_stg;

INSERT INTO Department(dept_nm)
select distinct department_nm from proj_stg;

INSERT INTO Salary(salary)
Select distinct(salary) from proj_stg;

INSERT INTO Employment(emp_id, dept_id, manager_id, job_id, loc_id, salary_id, start_dt, end_dt)
select distinct ps.emp_id, de.dept_id, mn.emp_id, job.job_id, loc.loc_id, sa.salary_id, ps.start_dt, ps.end_dt from proj_stg as ps
full outer join Employee mn on mn.emp_nm=ps.manager
full outer join Employee em on em.emp_id=ps.emp_id
full outer join Department de on de.dept_nm=ps.department_nm
full outer join Job job on job.job_title=ps.job_title
full outer join Location loc on loc.location=ps.location
inner join Salary sa on sa.salary=ps.salary;

-- Adding foreign keys

ALTER TABLE Employment ADD FOREIGN KEY (emp_id) REFERENCES Employee(emp_id);
ALTER TABLE Employment ADD FOREIGN KEY (dept_id) REFERENCES Department(dept_id);
ALTER TABLE Employment ADD FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);
ALTER TABLE Employment ADD FOREIGN KEY (job_id)  REFERENCES Job(job_id);
ALTER TABLE Employment ADD FOREIGN KEY (loc_id) REFERENCES Location(loc_id);
ALTER TABLE Employment ADD FOREIGN KEY (salary_id) REFERENCES salary(salary_id);


--CRUD------------------
	
/*Question 1: Return a list of employees with Job Titles and Department Names*/

select em.emp_nm, dp.dept_nm, job.job_title from employment emp
inner join Employee em on em.emp_id=emp.emp_id
inner join Department dp on dp.dept_id=emp.dept_id
inner join Job job on job.job_id=emp.job_id;

/*Question 2: Insert Web Programmer as a new job title*/

INSERT INTO Job(job_title) VALUES('Web Programmer');

/*Question 3: Correct the job title from web programmer to web developer*/

UPDATE Job SET job_title='Web Developer' where LOWER(job_title)='web programmer';

/*Question 4: Delete the job title Web Developer from the database*/

DELETE FROM JOB where job_title='Web Developer';

/*Question 5: How many employees are in each department?*/

SELECT dp.dept_nm, count(emp.emp_id) from Employment emp
inner join Department dp on dp.dept_id=emp.dept_id
GROUP BY dp.dept_nm;

/*Question 6: Write a query that returns current and past jobs (include employee name, job title, department, manager name, start and end date for position) for employee Toni Lembeck.*/

select distinct em.emp_nm as Employee, j.job_title, 
                d.dept_nm,  mn.emp_nm as Manager, 
                emp.start_dt, emp.end_dt from Employment as emp
join Employee mn on mn.emp_id=emp.emp_id
join Employee em on em.emp_id=emp.emp_id
join Department d on d.dept_id=emp.dept_id
join Job j on j.job_id=emp.job_id
where em.emp_nm='Toni Lembeck';

------- STEP 4 OPTIONAL -----

/*Create a view that returns all employee attributes; results should resemble initial Excel file*/

CREATE VIEW original_view AS
SELECT em.Emp_ID, em.Emp_NM, em.email, em.hire_dt, 
    j.job_title, sa.salary, d.dept_nm as department_nm, mn.emp_nm as manager, 
    emp.start_dt, emp.end_dt, 
    loc.location, loc.address, loc.city, loc.state, ed.edu_level as education_lvl 
    FROM Employment emp
JOIN Employee mn on mn.emp_id=emp.emp_id
JOIN Employee em on em.emp_id=emp.emp_id
JOIN Department d on d.dept_id=emp.dept_id
JOIN Job j on j.job_id=emp.job_id
JOIN Location loc on loc.loc_id=emp.loc_id
JOIN Salary sa on sa.salary_id=emp.salary_id
JOIN Education ed on ed.edu_id=em.edu_id;


/*Create a stored procedure with parameters that returns current and past jobs (include employee name, job title, department, manager name, start and end date for position) when given an employee name.*/
-- Using FUNCTION if the postgres version doesn't support PROCEDURE

CREATE OR REPLACE FUNCTION employee_job_history(Employee_name text) 
RETURNS TABLE (emp_nm text, job_title text, department_nm text, manager text, 
               start_dt date, end_dt date)
AS
$$ 
    SELECT emp_nm, job_title, department_nm, manager, start_dt, end_dt FROM original_view 
    WHERE emp_nm = Employee_name;
$$
LANGUAGE SQL;

SELECT * FROM employee_job_history('Toni Lembeck');

/* create user and privileges*/
CREATE USER NoMgr;

GRANT SELECT ON Employee TO NoMgr;
GRANT SELECT ON Education TO NoMgr;
GRANT SELECT ON Job TO NoMgr;
GRANT SELECT ON Department TO NoMgr;
GRANT SELECT ON Location TO NoMgr;
GRANT SELECT ON Employment TO NoMgr;

REVOKE SELECT ON original_view FROM NoMgr;
REVOKE SELECT ON Salary FROM NoMgr;