/*
===========================================================================================
Quality Checks
===========================================================================================
Scripts Purpose:
  This script performs various quality checks for data consistency, accuracy,
  and standardization across the 'Silver' schemas. It includes checks for:
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid date ranges and orders.
  - Data consistency between related fields.

Usage Notes:
  - Run these checks after data loading silver layer.
  - Investigate and resolve any discrepancles found during the checks.
===========================================================================================
*/

-- ========================================================================================
-- Check 'silver.crm_cust_info'
-- ========================================================================================
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key)

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status)

-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

-- ========================================================================================
-- Check 'silver.crm_prd_info'
-- ========================================================================================
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Result
SELECT
	prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check For Nulls or Negatif Numbers
-- Expectation: No Result
SELECT
	prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT prd_line
FROM silver.crm_prd_info
WHERE prd_line != TRIM(prd_line)

-- Data Standardization & Consistency
SELECT DISTINCT
	prd_line
FROM silver.crm_prd_info

-- Check for NULLs Start Date
SELECT prd_start_dt
FROM silver.crm_prd_info
WHERE prd_start_dt = NULL

-- Check for Invalid Date Orders
SELECT
	prd_start_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ========================================================================================
-- Check 'silver.crm_sales_details'
-- ========================================================================================
-- Check for Invalid ord_num
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM (sls_ord_num);

-- Check for Invalid sls_prd_key
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key_type FROM silver.crm_prd_info);

-- Check for Invalid sls_prd_key
SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT sls_cust_id FROM silver.crm_cust_info);

-- Check for Invalid Dates
SELECT
	sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL

-- Check for Invalid Date Orders
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.
SELECT DISTINCT
	sls_sales AS old_sls_sales,
	sls_quantity,
	sls_price AS old_sls_price,
CASE
	WHEN sls_sales IS NULL 
		OR sls_sales <= 0
		OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE
	WHEN sls_price IS NULL 
		OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL 
	OR sls_quantity IS NULL 
	OR sls_price IS NULL
	OR sls_sales <= 0 
	OR sls_quantity <= 0 
	OR sls_price <=  0
ORDER BY 
	sls_sales,
	sls_quantity,
	sls_price

-- ========================================================================================
-- Check 'silver.erp_cust_az12'
-- ========================================================================================
-- Identify Out-Of-Range Dates
SELECT DISTINCT
	bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' 
	OR bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT
	gen,
	CASE
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM silver.erp_cust_az12

-- ========================================================================================
-- Check 'silver.erp_loc_a101'
-- ========================================================================================
-- Clean Country Name
SELECT
	REPLACE(cid, '-', '') AS cid,
	CASE
		WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
		WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
		WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
		ELSE TRIM(cntry)
	END AS cntry
FROM silver.erp_loc_a101

-- Data Standardization & Consistency
SELECT DISTINCT 
	cntry
FROM silver.erp_loc_a101
ORDER BY cntry

-- ========================================================================================
-- Check 'silver.erp_px_g1v2'
-- ========================================================================================
-- Cek Connection
SELECT
	id,
	cat,
	subcat,
	maintenance	
FROM silver.erp_px_g1v2
SELECT 
	prd_key
FROM silver.crm_prd_info;

-- Check for Unwanted Spaces
SELECT *
FROM silver.erp_px_g1v2
WHERE cat != TRIM(cat)
	OR subcat != TRIM(subcat)
	OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT
	cat
FROM silver.erp_px_g1v2;

-- Data Standardization & Consistency
SELECT DISTINCT
	subcat
FROM silver.erp_px_g1v2;

-- Data Standardization & Consistency
SELECT DISTINCT
	maintenance
FROM silver.erp_px_g1v2;
