/****** Script for SelectTopNRows command from SSMS  ******/

--Total record is 541909
--135080 records have no customerid
--406829 records have customerid


;with Online_Retail as
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [Unique].[dbo].[Online Retail]
	  where CustomerID is not null
  )
  , quantity_unit_price as
  (
  SELECT *
  FROM Online_Retail
  WHERE Quantity >0 AND UnitPrice !=0
  )
  ,dup_check as
  (
  SELECT *, ROW_NUMBER () OVER (partition by InvoiceNo, StockCode,Quantity order by InvoiceDate) AS dup_flag
  FROM quantity_unit_price
  )
  SELECT *
  into #online_retail_cleaned
  FROM dup_check
  WHERE dup_flag = 1
  --392669 clean data
  -- 5215 duplicate records
 

 --Cohort Analysis--

 SELECT *
 FROM #online_retail_cleaned

 --Unique identifier
 --Initial start date (first purchase date)
 --Revenue

SELECT CustomerID,
       MIN(InvoiceDate) AS First_Purchase_date,
	   DATEFROMPARTS(year(min(InvoiceDate)),MONTH(min(InvoiceDate)),1) AS Cohort_date
into #Cohort
FROM #online_retail_cleaned
GROUP BY CustomerID

SELECT *
FROM #Cohort


--Creating Cohort Index

SELECT
      second.*,
	  cohort_index= year_diff*12+ month_diff + 1
	  into #cohort_retention
FROM
  (
	SELECT 
	       first.*,
		   year_diff = invoice_year-cohort_year,
		   month_diff =invoice_month-cohort_month
	FROM
	   (
		SELECT
			 o.*,
			 c.Cohort_date,
			 year(o.InvoiceDate) AS invoice_year,
			 month(o.InvoiceDate) AS invoice_month,
			 year(c.Cohort_date) AS cohort_year,
			 month(c.Cohort_date) AS cohort_month
		FROM #online_retail_cleaned o
		left join #Cohort c
		on o.CustomerID = c.CustomerID
		)first
	)second


--pivot table to see cohort index

SELECT *
into #cohort_pivot
FROM
   (
	select distinct CustomerID,
			Cohort_date,
			cohort_index
	from #cohort_retention
)tbl
pivot (
       count (CustomerID)
	   for cohort_index IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12] ,[13])
	   ) AS pivot_table
order by Cohort_date


--to show in percentage
SELECT *
from #cohort_pivot
order by Cohort_date

select Cohort_date, 1.0*[1]/[1]*100 as [1], 
       1.0*[2]/[1]*100 as [2],
	   1.0*[3]/[1]*100 as [3],
	   1.0*[4]/[1]*100 as [4],
       1.0*[5]/[1]*100 as [5],
	   1.0*[6]/[1]*100 as [6],
	   1.0*[7]/[1]*100 as [7],
	   1.0*[8]/[1]*100 as [8],
	   1.0*[9]/[1]*100 as [9],
	   1.0*[10]/[1]*100 as[10],
	   1.0*[11]/[1]*100 as [11],
	   1.0*[12]/[1]*100 as [12],
	   1.0*[13]/[1]*100 as [13]
from #cohort_pivot
order by Cohort_date



Thank you.