-- 📊 1. Create and Select the Database
CREATE DATABASE IF NOT EXISTS hr_analytics;
USE hr_analytics;

-- 🧹 2. Drop Tables If Exist
DROP TABLE IF EXISTS employee_performance;
DROP TABLE IF EXISTS employee_performance_staging;

-- 🏗️ 3. Create Main Table
CREATE TABLE employee_performance (
    employee_id INT PRIMARY KEY,
    department VARCHAR(100),
    region VARCHAR(100),
    education VARCHAR(100),
    gender VARCHAR(10),
    recruitment_channel VARCHAR(100),
    no_of_trainings INT,
    age INT,
    previous_year_rating DECIMAL(2,1),
    length_of_service INT,
    KPIs_met_more_than_80 TINYINT,
    awards_won TINYINT,
    avg_training_score DECIMAL(5,2)
);

-- 🏗️ 4. Create Staging Table for Handling Duplicates
CREATE TABLE employee_performance_staging LIKE employee_performance;

-- 📥 5. Load CSV into Staging Table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/employee_data.csv'
INTO TABLE employee_performance_staging
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(employee_id, department, region, education, gender, recruitment_channel, no_of_trainings, age, @previous_year_rating, length_of_service, KPIs_met_more_than_80, awards_won, avg_training_score)
SET previous_year_rating = NULLIF(@previous_year_rating, '');

-- 🧹 6. Insert Deduplicated Data into Main Table (Keep highest training score per employee)
INSERT INTO employee_performance (
    employee_id, department, region, education, gender,
    recruitment_channel, no_of_trainings, age, previous_year_rating,
    length_of_service, KPIs_met_more_than_80, awards_won, avg_training_score
)
SELECT 
    employee_id, department, region, education, gender,
    recruitment_channel, no_of_trainings, age, previous_year_rating,
    length_of_service, KPIs_met_more_than_80, awards_won, avg_training_score
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY avg_training_score DESC) AS rn
    FROM employee_performance_staging
) AS ranked
WHERE rn = 1;

-- 👀 7. View First 10 Records
SELECT * FROM employee_performance LIMIT 10;

-- 🔍 8. Check for Null Values
SELECT 
    SUM(employee_id IS NULL) AS missing_employee_id,
    SUM(department IS NULL) AS missing_department,
    SUM(region IS NULL) AS missing_region,
    SUM(education IS NULL OR education = '') AS missing_education,
    SUM(gender IS NULL) AS missing_gender,
    SUM(recruitment_channel IS NULL) AS missing_recruitment_channel,
    SUM(no_of_trainings IS NULL) AS missing_trainings,
    SUM(age IS NULL) AS missing_age,
    SUM(previous_year_rating IS NULL) AS missing_rating,
    SUM(length_of_service IS NULL) AS missing_service
FROM employee_performance;

-- ⚠️ 9. Disable Safe Update Mode Temporarily
SET SQL_SAFE_UPDATES = 0;

-- 🛠️ 10. Fill Missing Ratings with Average
UPDATE employee_performance
JOIN (
    SELECT ROUND(AVG(previous_year_rating), 1) AS avg_rating
    FROM employee_performance
    WHERE previous_year_rating IS NOT NULL
) AS avg_data
ON employee_performance.previous_year_rating IS NULL
SET employee_performance.previous_year_rating = avg_data.avg_rating;

-- 🛠️ 11. Set Empty Education to 'Unknown'
UPDATE employee_performance
SET education = 'Unknown'
WHERE education = '';

-- ⚠️ 12. Re-enable Safe Update Mode (Optional)
SET SQL_SAFE_UPDATES = 1;

-- 👀 13. Check for Age Outliers
SELECT * FROM employee_performance
WHERE age < 18 OR age > 65;

-- ✅ 14. Final Cleaned Data Preview
SELECT * FROM employee_performance LIMIT 20;

-- 📈 15. EDA: Total Employees
SELECT COUNT(*) AS total_employees
FROM employee_performance;

-- 📊 16. Summary Stats for Numeric Fields
SELECT 
    MIN(age) AS min_age, MAX(age) AS max_age, ROUND(AVG(age), 1) AS avg_age,
    MIN(no_of_trainings) AS min_trainings, MAX(no_of_trainings) AS max_trainings, ROUND(AVG(no_of_trainings), 1) AS avg_trainings,
    MIN(previous_year_rating) AS min_rating, MAX(previous_year_rating) AS max_rating, ROUND(AVG(previous_year_rating), 1) AS avg_rating,
    MIN(length_of_service) AS min_service, MAX(length_of_service) AS max_service, ROUND(AVG(length_of_service), 1) AS avg_service
FROM employee_performance;

-- 📌 17. Count by Department
SELECT department, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY department
ORDER BY employee_count DESC;

-- 📌 18. Count by Region
SELECT region, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY region
ORDER BY employee_count DESC;

-- 📌 19. Count by Education
SELECT education, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY education
ORDER BY employee_count DESC;

-- 📌 20. Count by Recruitment Channel
SELECT recruitment_channel, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY recruitment_channel
ORDER BY employee_count DESC;

-- 📈 21. Trainings vs. Avg Rating
SELECT no_of_trainings, 
       COUNT(*) AS employee_count,
       ROUND(AVG(previous_year_rating), 2) AS avg_rating
FROM employee_performance
GROUP BY no_of_trainings
ORDER BY no_of_trainings;

-- 🧮 22. Age Group Distribution
SELECT 
    CASE 
        WHEN age BETWEEN 20 AND 30 THEN '20-30'
        WHEN age BETWEEN 31 AND 40 THEN '31-40'
        WHEN age BETWEEN 41 AND 50 THEN '41-50'
        ELSE '51+' 
    END AS age_group,
    COUNT(*) AS employee_count,
    ROUND(AVG(previous_year_rating), 2) AS avg_rating
FROM employee_performance
GROUP BY age_group
ORDER BY age_group;
