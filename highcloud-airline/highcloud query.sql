CREATE database highcloud;
use highcloud;
select*from maindata;
select count(*) from maindata;
/*"1.calcuate the following fields from the Year	Month (#)	Day  fields ( First Create a Date Field from Year , Month , Day fields)"
   A.Year
   B.Monthno
   C.Monthfullname
   D.Quarter(Q1,Q2,Q3,Q4)
   E. YearMonth ( YYYY-MMM)
   F. Weekdayno
   G.Weekdayname
   H.FinancialMOnth
   I. Financial Quarter 
*/
SET SQL_SAFE_UPDATES = 0;


#fulldate

ALTER TABLE maindata
ADD COLUMN FullDate DATE;
select*from maindata;
UPDATE maindata
SET FullDate = STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d');

#monthno

ALTER TABLE maindata
ADD COLUMN MonthNo INT;
UPDATE maindata
SET MonthNo = MONTH(FullDate);
select*from maindata;

#monthfullname

ALTER TABLE maindata
ADD COLUMN MonthFullName VARCHAR(20);
UPDATE maindata
SET MonthFullName = MONTHNAME(FullDate);
select*from maindata;

#QUARTER
ALTER TABLE maindata
ADD COLUMN QuarterLabel VARCHAR(2);
UPDATE maindata
SET QuarterLabel = CASE QUARTER(FullDate)
    WHEN 1 THEN 'Q1'
    WHEN 2 THEN 'Q2'
    WHEN 3 THEN 'Q3'
    WHEN 4 THEN 'Q4'
END;

#YEARMONTH

ALTER TABLE maindata
ADD COLUMN YearMonth VARCHAR(8);
UPDATE maindata
SET YearMonth = DATE_FORMAT(FullDate, '%Y-%b')
WHERE FullDate IS NOT NULL;

#WEEKDAYNO

ALTER TABLE maindata
ADD COLUMN WeekdayNo INT;
UPDATE maindata
SET WeekdayNo = DAYOFWEEK(FullDate)
WHERE FullDate IS NOT NULL;

#weekdayname
ALTER TABLE maindata
ADD COLUMN WeekdayName VARCHAR(10);
UPDATE maindata
SET WeekdayName = DAYNAME(FullDate)
WHERE FullDate IS NOT NULL;

#FINANCIALMONTH
ALTER TABLE maindata
ADD COLUMN FinancialMonth INT;
UPDATE maindata
SET FinancialMonth = CASE 
    WHEN MONTH(FullDate) >= 4 THEN MONTH(FullDate) - 3
    ELSE MONTH(FullDate) + 9
END
WHERE FullDate IS NOT NULL;

#FINANCIAL_QTR
ALTER TABLE maindata
ADD COLUMN Financial_Qtr VARCHAR(2);
UPDATE maindata
SET Financial_Qtr = CASE 
    WHEN MONTH(FullDate) BETWEEN 4 AND 6 THEN 'Q1'
    WHEN MONTH(FullDate) BETWEEN 7 AND 9 THEN 'Q2'
    WHEN MONTH(FullDate) BETWEEN 10 AND 12 THEN 'Q3'
    WHEN MONTH(FullDate) BETWEEN 1 AND 3 THEN 'Q4'
END
WHERE FullDate IS NOT NULL;



CREATE VIEW DATAVIEW AS
SELECT 
    STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d') AS FullDate,

    Year AS Year,
    MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) AS MonthNo,

    MONTHNAME(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) AS MonthFullName,
    CASE QUARTER(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d'))
        WHEN 1 THEN 'Q1'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Q4'
    END AS QuarterLabel,
    DATE_FORMAT(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d'), '%Y-%b') AS YearMonth,
    DAYOFWEEK(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) AS WeekdayNo,
    DAYNAME(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) AS WeekdayName,

    CASE 
        WHEN MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) >= 4 
            THEN MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) - 3
        ELSE MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) + 9
    END AS FinancialMonth,

    CASE 
        WHEN MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) BETWEEN 4 AND 6 THEN 'Q1'
        WHEN MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) BETWEEN 7 AND 9 THEN 'Q2'
        WHEN MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-', Day), '%Y-%m-%d')) BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    END AS Financial_Qtr
FROM maindata;
SELECT*FROM dataview;

/*2. Find the load Factor percentage on a yearly , Quarterly , Monthly basis ( Transported passengers / Available seats)*/
SELECT 
    YEAR(FullDate) AS Year,
    SUM(TransportedPassengers) / SUM(AvailableSeats) * 100 AS LoadFactorPercentage
FROM maindata
WHERE FullDate IS NOT NULL
GROUP BY YEAR(FullDate)
ORDER BY Year;

SELECT 
    YEAR(FullDate) AS Year,
    QUARTER(FullDate) AS Quarter,
    SUM(TransportedPassengers) / SUM(AvailableSeats) * 100 AS LoadFactorPercentage
FROM maindata
WHERE FullDate IS NOT NULL
GROUP BY YEAR(FullDate), QUARTER(FullDate)
ORDER BY Year, Quarter;

SELECT
    Year,
    MonthFullName,
    ROUND((SUM(TransportedPassengers) / SUM(AvailableSeats)) * 100, 2) AS LoadFactorpercentage
FROM maindata
GROUP BY Year, MonthNo, MonthFullName
ORDER BY Year, MonthNo;

/*3. Find the load Factor percentage on a Carrier Name basis ( Transported passengers / Available seats)
*/

SELECT 
    CarrierName,
    SUM(TransportedPassengers) / SUM(AvailableSeats) * 100 AS LoadFactorPercentage
FROM maindata
WHERE FullDate IS NOT NULL
GROUP BY CarrierName
ORDER BY LoadFactorPercentage DESC
limit 10;

/*4. Identify Top 10 Carrier Names based passengers preference 
*/
SELECT 
    CarrierName,
    CONCAT(ROUND(SUM(TransportedPassengers) / 1000000, 0), 'M') AS total_passenger
FROM maindata
GROUP BY CarrierName
ORDER BY sum(TransportedPassengers) DESC
LIMIT 10;








/*5. Display top Routes ( from-to City) based on Number of Flights */
SELECT
    FromToCity,
    CONCAT(ROUND(SUM(DeparturesPerformed) / 1000, 1), 'K') AS TotalFlights
FROM maindata
GROUP BY FromToCity
ORDER BY SUM(DeparturesPerformed) DESC
LIMIT 10;

/*6. Identify the how much load factor is occupied on Weekend vs Weekdays.
*/

SELECT 
    CASE 
        WHEN WeekdayName IN ('Saturday','Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,
    SUM(TransportedPassengers) / SUM(AvailableSeats) * 100 AS LoadFactorPercentage
FROM maindata
WHERE FullDate IS NOT NULL
GROUP BY DayType;




/*7. Identify number of flights based on Distance group*/

SELECT 
    CASE 
        WHEN Distance <= 500 THEN '0-500'
        WHEN Distance <= 1000 THEN '501-1000'
        WHEN Distance <= 1500 THEN '1001-1500'
        WHEN Distance <= 2000 THEN '1501-2000'
        ELSE '2000+'
    END AS DistanceGroup,
    sum(DeparturesPerformed) AS total_flight
FROM maindata
GROUP BY 
    CASE 
        WHEN Distance <= 500 THEN '0-500'
        WHEN Distance <= 1000 THEN '501-1000'
        WHEN Distance <= 1500 THEN '1001-1500'
        WHEN Distance <= 2000 THEN '1501-2000'
        ELSE '2000+'
    END;