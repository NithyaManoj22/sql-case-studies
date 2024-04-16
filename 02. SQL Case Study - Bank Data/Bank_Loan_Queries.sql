SELECT * FROM bank_loan_data

-- calculating different KPI's : DASHBOARD 1

-- Total Loan Applications: total count of loan applications
SELECT COUNT(id) AS Total_Loan_Applications
FROM bank_loan_data

-- Calculate Month to date (MTD) of loan applications on the issue date: latest month on the application for the latest year
SELECT COUNT(id) AS MTD
FROM bank_loan_data
WHERE MONTH(issue_date) = (
							SELECT MAX(MONTH(issue_date)) as latest_month
							FROM bank_loan_data) AND
	  YEAR(issue_date) = (
							SELECT MAX(YEAR(issue_date)) as latest_year 
							FROM bank_loan_data
						 )


-- CTE to obtain most recent month 						 
WITH most_recent_month_cte AS (
								SELECT MAX(MONTH(issue_date)) as recent_month FROM bank_loan_data
								WHERE MONTH(issue_date) = (
															SELECT MAX(MONTH(issue_date)) AS max_month FROM bank_loan_data
														  )AND
														  YEAR(issue_date)= (
															SELECT MAX(YEAR(issue_date)) FROM bank_loan_data	
														  )
							  )
SELECT * INTO most_recent_month_cte FROM most_recent_month_cte


-- CTE to obtain second max month 						 
WITH second_max_month_cte AS (
								SELECT MAX(issue_month) as second_max_month FROM (
								SELECT DISTINCT(MONTH(issue_date)) AS issue_month FROM bank_loan_data
								) as subquery1
								WHERE issue_month < (
													SELECT MAX(MONTH(issue_date)) AS max_month FROM bank_loan_data
								)
							)
SELECT * INTO second_max_month_cte FROM second_max_month_cte 


-- Calculating percentage change in applications MoM (Month Over Month) for the most recent month and the previous month

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

--future work: calculate percentage change for each month in the entire dataset?????

-- Total funded amount on the MTD: 
SELECT SUM(loan_amount) as total_funded_amount_MTD 
FROM bank_loan_data
WHERE MONTH(issue_date) = (
							SELECT MAX(MONTH(issue_date)) as MTD FROM bank_loan_data
							) AND
							YEAR(issue_date) = (
												SELECT MAX(YEAR(issue_date)) AS MYTD FROM bank_loan_data
												)


-- Total funded amount on the PMTD: 
SELECT SUM(loan_amount) as total_funded_amount_PMTD 
FROM bank_loan_data
WHERE MONTH(issue_date) = (
							SELECT MAX(MONTH(issue_date)) as max_second_month FROM bank_loan_data
							WHERE  MONTH(issue_date) < (
															SELECT MAX(MONTH(issue_date)) AS max_first_month FROM bank_loan_data
														)
							)


-- Month over Month (MoM) change on the Total funded amount
-- Combining above 2 queries in a CTE to caluclate percentage change

WITH total_funded_percent_change_MTD AS (
									SELECT SUM(loan_amount) as total_funded_amount_MTD 
									FROM bank_loan_data
									WHERE MONTH(issue_date) = (
																SELECT MAX(MONTH(issue_date)) as MTD FROM bank_loan_data
																) AND
																YEAR(issue_date) = (
																					SELECT MAX(YEAR(issue_date)) AS MYTD FROM bank_loan_data
																					)),
	total_funded_percent_change_PMTD AS (
									SELECT SUM(loan_amount) as total_funded_amount_PMTD 
									FROM bank_loan_data
									WHERE MONTH(issue_date) = (
															SELECT MAX(MONTH(issue_date)) as max_second_month FROM bank_loan_data
															WHERE  MONTH(issue_date) < (
																							SELECT MAX(MONTH(issue_date)) AS max_first_month FROM bank_loan_data
																						)
															))	
	SELECT *,
	CASE 
		WHEN total_funded_amount_PMTD = 0 THEN NULL
		ELSE ((1.0* (total_funded_amount_MTD - total_funded_amount_PMTD)/total_funded_amount_PMTD)* 100)
		END
		AS MoM_total_funded_amount
    FROM
		total_funded_percent_change_MTD,
		total_funded_percent_change_PMTD


-- calculating MoM on customer payments
WITH total_payment_MTD AS(
							-- Total payment made by the customer to the bank in the current month (MTD)
							SELECT SUM(total_payment) AS Customer_Payment_MTD
							FROM bank_loan_data
							WHERE MONTH(issue_date) = (
														SELECT recent_month
														FROM most_recent_month_cte	
													  )),
	total_payment_PMTD AS (
							-- Total payment made by the customer to the bank in the previous month (PMTD)
							SELECT SUM(total_payment) AS Customer_Payment_PMTD
							FROM bank_loan_data
							WHERE MONTH(issue_date) = (
														SELECT second_max_month
														FROM second_max_month_cte	
													  ))
SELECT	*, 
        CASE 
			WHEN Customer_Payment_PMTD = 0 THEN NULL
			ELSE ((1.0* (Customer_Payment_MTD - Customer_Payment_PMTD)/Customer_Payment_PMTD)* 100)
		END
		AS MoM_total_paid_amount
FROM total_payment_MTD, total_payment_PMTD;

-- Average interest rate in MTD
SELECT ROUND(AVG(int_rate),4) * 100 AS MTD_interest_rate
FROM bank_loan_data
WHERE MONTH(issue_date) = (
							SELECT recent_month
							FROM most_recent_month_cte
							)

-- Average interest rate in PMTD
SELECT ROUND(AVG(int_rate),4) * 100 AS PMTD_interest_rate
FROM bank_loan_data
WHERE MONTH(issue_date) = (
							SELECT second_max_month
							FROM second_max_month_cte
							)

-- Average Debt to income ratio in MTD
SELECT ROUND(AVG(dti),4) * 100 AS MTD_interest_rate
FROM bank_loan_data
WHERE MONTH(issue_date) = (
							SELECT recent_month
							FROM most_recent_month_cte
							)

-- Average Debt to income ratio in PMTD
SELECT ROUND(AVG(dti),4) * 100 AS PMTD_interest_rate
FROM bank_loan_data
WHERE MONTH(issue_date) = (
							SELECT second_max_month
							FROM second_max_month_cte
							)

-- DASHBOARD 1: SUMMARY
-- Good loan vs bad loan KPI's

-- total percentage of applications for a good loan
-- good loans are loans that are currently being paid or already paid off

SELECT * FROM bank_loan_data

WITH total_app AS (
					SELECT COUNT(id) AS total_applications
					FROM  bank_loan_data
					),
	good_app AS (
			SELECT COUNT(id) as number_good_applications 
			FROM bank_loan_data
			WHERE loan_status = 'Fully Paid' OR loan_status = 'Current'
			)
SELECT (number_good_applications * 100) /total_applications  AS percent_good_applications
FROM total_app, good_app;

-- alternative query
SELECT (COUNT(CASE WHEN loan_status = 'Fully Paid' OR loan_status = 'Current' THEN id END) * 100) /
	   COUNT(id) AS good_loan_percent
FROM bank_loan_data

-- number of good loan applications
SELECT COUNT(id) AS number_good_applications 
FROM bank_loan_data
WHERE loan_status IN ( 'Fully Paid' , 'Current')

-- Good loan funded amount
SELECT SUM(loan_amount) AS good_loan_fund 
FROM bank_loan_data
WHERE loan_status IN ( 'Fully Paid' , 'Current')

-- Good loan total received amount
SELECT SUM(total_payment) AS good_loan_fund 
FROM bank_loan_data
WHERE loan_status IN ( 'Fully Paid' , 'Current')


-- Bad Loans
-- Total percent of bad loans

SELECT (COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0)/ COUNT(id) AS bad_loan_percent
FROM bank_loan_data

-- number of bad loan applications
SELECT COUNT(id) AS number_bad_applications 
FROM bank_loan_data
WHERE loan_status IN ('Charged Off')

-- Bad loan funded amount
SELECT SUM(loan_amount) AS bad_loan_fund 
FROM bank_loan_data
WHERE loan_status IN ('Charged Off')

-- Bad loan total received amount
SELECT SUM(total_payment) AS bad_loan_fund 
FROM bank_loan_data
WHERE loan_status IN ('Charged Off')

-- multiple metrics based on loan status

SELECT
		loan_status,
		COUNT(id) AS total_Loan_Applications,
		SUM(total_payment) AS Total_Amount_Received,
		SUM(loan_amount) AS Total_Funded_Amount,
		AVG(int_rate * 100) As Interest_Rate,
		AVG(dti * 100) AS DTI
FROM 
		bank_loan_data
GROUP BY
		loan_status

-- total payment and loan amount for MTD
SELECT 
		loan_status,
		SUM(total_payment) AS MTD_Total_Amount_Received,
		SUM(loan_amount) AS MTD_Total_Funded_Amount
FROM
		bank_loan_data
WHERE
		MONTH(issue_date) = (
							SELECT
									recent_month 
							FROM
									most_recent_month_cte
							)
GROUP BY
		loan_status


-- DASHBOARD 2 : OVERVIEW DASHBOARD

-- Aggregation metrics by month
SELECT 
		MONTH(issue_date) as Month_Number,
		DATENAME(MONTH, issue_date) AS Month_Name,
		COUNT(id) AS Total_Loan_Applications,
		SUM(loan_amount) AS Total_Funded_Amount,
		SUM(total_payment) AS Total_Received_Amount
FROM
		bank_loan_data
GROUP BY
		MONTH(issue_date),DATENAME(MONTH, issue_date)
ORDER BY
		MONTH(issue_date)

-- Aggregation metrics by State
SELECT 
		address_state,
		COUNT(id) AS Total_Loan_Applications,
		SUM(loan_amount) AS Total_Funded_Amount,
		SUM(total_payment) AS Total_Received_Amount
FROM
		bank_loan_data
GROUP BY
		address_state
ORDER BY
		SUM(loan_amount) DESC

-- Aggregation metrics by Term
SELECT 
		term,
		COUNT(id) AS Total_Loan_Applications,
		SUM(loan_amount) AS Total_Funded_Amount,
		SUM(total_payment) AS Total_Received_Amount
FROM
		bank_loan_data
GROUP BY
		term
ORDER BY
		term

-- Aggregation metrics by employment length
SELECT 
		emp_length,
		COUNT(id) AS Total_Loan_Applications,
		SUM(loan_amount) AS Total_Funded_Amount,
		SUM(total_payment) AS Total_Received_Amount
FROM
		bank_loan_data
GROUP BY
		emp_length
ORDER BY
		emp_length

-- Aggregation metrics by purpose
SELECT 
		purpose,
		COUNT(id) AS Total_Loan_Applications,
		SUM(loan_amount) AS Total_Funded_Amount,
		SUM(total_payment) AS Total_Received_Amount
FROM
		bank_loan_data
GROUP BY
		purpose
ORDER BY
		COUNT(id) DESC

-- Aggregation metrics by purpose
SELECT 
		home_ownership,
		COUNT(id) AS Total_Loan_Applications,
		SUM(loan_amount) AS Total_Funded_Amount,
		SUM(total_payment) AS Total_Received_Amount
FROM
		bank_loan_data
GROUP BY
		home_ownership
ORDER BY
		COUNT(id) DESC

		SELECT * FROM bank_loan_data