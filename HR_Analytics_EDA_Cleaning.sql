-- 📊 HR Analytics: Data Cleaning and Exploratory Data Analysis (EDA)

-- 1️⃣ Create and Select Database
CREATE DATABASE IF NOT EXISTS hr_analytics;
USE hr_analytics;

-- 2️⃣ Drop Existing Table (if any)
DROP TABLE IF EXISTS employee_performance;

-- 3️⃣ Create Table
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

-- 4️⃣ Load Data (adjust path for your system)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/employee_data.csv'
INTO TABLE employee_performance
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(employee_id, department, region, education, gender, recruitment_channel, no_of_trainings, age, @previous_year_rating, length_of_service, KPIs_met_more_than_80, awards_won, avg_training_score)
SET previous_year_rating = NULLIF(@previous_year_rating, '');

-- 5️⃣ Check First 10 Records
SELECT * FROM employee_performance LIMIT 10;

-- 🧹 Data Cleaning --

-- 6️⃣ Find Duplicates
SELECT employee_id, COUNT(*) AS duplicate_count
FROM employee_performance
GROUP BY employee_id
HAVING COUNT(*) > 1;

-- 7️⃣ Remove Duplicates
DELETE FROM employee_performance
WHERE employee_id IN (
    SELECT employee_id
    FROM (
        SELECT employee_id
        FROM employee_performance
        GROUP BY employee_id
        HAVING COUNT(*) > 1
    ) AS duplicates
);

-- 8️⃣ Check for Nulls
SELECT 
    SUM(employee_id IS NULL) AS missing_employee_id,
    SUM(department IS NULL) AS missing_department,
    SUM(region IS NULL) AS missing_region,
    SUM(education IS NULL) AS missing_education,
    SUM(gender IS NULL) AS missing_gender,
    SUM(recruitment_channel IS NULL) AS missing_recruitment_channel,
    SUM(no_of_trainings IS NULL) AS missing_trainings,
    SUM(age IS NULL) AS missing_age,
    SUM(previous_year_rating IS NULL) AS missing_rating,
    SUM(length_of_service IS NULL) AS missing_service
FROM employee_performance;

-- 9️⃣ Update Null Ratings with Average
UPDATE employee_performance
SET previous_year_rating = (
    SELECT ROUND(AVG(previous_year_rating), 1)
    FROM employee_performance
    WHERE previous_year_rating IS NOT NULL
)
WHERE previous_year_rating IS NULL;

-- 🔍 Check for Age Outliers
SELECT * FROM employee_performance
WHERE age < 18 OR age > 65;

-- 📝 Update Missing Education
UPDATE employee_performance
SET education = 'Unknown'
WHERE education = '';

-- ✅ Verify Clean Data
SELECT * FROM employee_performance;

-- 📊 EDA --

-- 🔸 Total Records
SELECT COUNT(*) AS total_employees
FROM employee_performance;

-- 🔸 Numeric Field Summary
SELECT 
    MIN(age) AS min_age, MAX(age) AS max_age, AVG(age) AS avg_age,
    MIN(no_of_trainings) AS min_trainings, MAX(no_of_trainings) AS max_trainings, AVG(no_of_trainings) AS avg_trainings,
    MIN(previous_year_rating) AS min_rating, MAX(previous_year_rating) AS max_rating, AVG(previous_year_rating) AS avg_rating,
    MIN(length_of_service) AS min_service, MAX(length_of_service) AS max_service, AVG(length_of_service) AS avg_service
FROM employee_performance;

-- 🔸 Employee Count by Department
SELECT department, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY department
ORDER BY employee_count DESC;

-- 🔸 Employee Count by Region
SELECT region, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY region
ORDER BY employee_count DESC;

-- 🔸 Employee Count by Education
SELECT education, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY education
ORDER BY employee_count DESC;

-- 🔸 Employee Count by Recruitment Channel
SELECT recruitment_channel, COUNT(*) AS employee_count
FROM employee_performance
GROUP BY recruitment_channel
ORDER BY employee_count DESC;

-- 🔸 Trainings vs. Rating
SELECT no_of_trainings, 
       COUNT(*) AS employee_count,
       AVG(previous_year_rating) AS avg_rating
FROM employee_performance
WHERE previous_year_rating IS NOT NULL
GROUP BY no_of_trainings
ORDER BY no_of_trainings;

-- 🔸 Age Groups Distribution
SELECT 
    CASE 
        WHEN age BETWEEN 20 AND 30 THEN '20-30'
        WHEN age BETWEEN 31 AND 40 THEN '31-40'
        WHEN age BETWEEN 41 AND 50 THEN '41-50'
        ELSE '51+' 
    END AS age_group,
    COUNT(*) AS employee_count,
    AVG(previous_year_rating) AS avg_rating
FROM employee_performance
GROUP BY age_group
ORDER BY age_group;

-- ✅ End of EDA
