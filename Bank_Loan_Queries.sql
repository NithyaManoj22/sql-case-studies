SELECT * FROM bank_loan_data

-- calculating different KPI's : DASHBOARD 1

-- Total Loan Applications: total count of loan applications would be each unique customer id in the dataset
SELECT COUNT(id) AS Total_Loan_Applications
FROM bank_loan_data

-- calculate Month to date (MTD) of loan applications on the issue date: latest month on the application for the latest year
SELECT COUNT(id) AS MTD
FROM bank_loan_data
WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)) as latest_month FROM bank_loan_data) AND
YEAR(issue_date) = (SELECT MAX(YEAR(issue_date)) as latest_year FROM bank_loan_data)

-- Calculate Month over Month : percentage change in the disbursement value of the bank from one month to the next
-- Currently calculated for previous month of MTD: MTD - PMTD / PMTD

-- this piece does not work in MS SQL server
/*SELECT DISTINCT(MONTH(issue_date)) as months FROM bank_loan_data
WHERE MONTH(issue_date) < (SELECT MAX(MONTH(issue_date)) as latest_month FROM bank_loan_data)
ORDER BY DISTINCT(MONTH(issue_date))
LIMIT 1 OFFSET 1 */

-- alternate ways of using subqueries
SELECT MAX(issue_month) AS second_max_month
FROM ( SELECT DISTINCT(MONTH(issue_date)) AS issue_month FROM bank_loan_data) as subquery1
WHERE issue_month < (SELECT MAX(MONTH(issue_date)) AS max_first_month FROM bank_loan_data) 

SELECT MAX(MONTH(issue_date)) as second_max_month FROM bank_loan_data
WHERE MONTH(issue_date) < (SELECT MAX (MONTH(issue_date)) as first_max_month FROM bank_loan_data)

-- calculating total number of transaction for the previous month to the current MTD
SELECT COUNT(id) as PMTD FROM bank_loan_data
WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)) as second_max_month FROM bank_loan_data
                           WHERE MONTH(issue_date) < (SELECT MAX (MONTH(issue_date)) as first_max_month FROM bank_loan_data))

-- calculating percentage change in transactions MoM (Month Over Month)

WITH MTD_Value AS (SELECT COUNT(id) AS MTD FROM bank_loan_data
		           WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)) as latest_month FROM bank_loan_data) AND
		                                      YEAR(issue_date) = (SELECT MAX(YEAR(issue_date)) as latest_year FROM bank_loan_data)),
PMTD_Value AS (SELECT COUNT(id) as PMTD FROM bank_loan_data
					WHERE MONTH(issue_date) = (SELECT MAX(MONTH(issue_date)) as second_max_month FROM bank_loan_data
                                               WHERE MONTH(issue_date) < (SELECT MAX (MONTH(issue_date)) as first_max_month FROM bank_loan_data)))
SELECT MTD,PMTD,
	CASE 
		WHEN PMTD = 0 THEN NULL
		ELSE ((1.0* (MTD-PMTD)/PMTD)* 100) 
	END AS percentage_change
FROM MTD_Value,PMTD_Value;







-- future work: calculate for each observation