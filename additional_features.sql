-- File: additional_features.sql
-- Implements missing features from the DOCX:
--   • GeoIP lookup
--   • IP‐validation function
--   • Daily report SP
--   • Trend views (daily/weekly/monthly)
--   • Alert severity
--   • Auditor role (DCL)

USE UnusualLoginDB;
GO

----------------------------------------------------------------------  
-- 1. GeoIP lookup table  
----------------------------------------------------------------------  
CREATE TABLE dbo.GeoIP_Lookup (
    GeoID       INT           IDENTITY(1,1) PRIMARY KEY,
    RangeStart  BIGINT        NOT NULL,
    RangeEnd    BIGINT        NOT NULL,
    Country     NVARCHAR(100) NOT NULL,
    Region      NVARCHAR(100) NULL,
    City        NVARCHAR(100) NULL
);
GO

-- Sample data (IPv4 numeric ranges)
INSERT dbo.GeoIP_Lookup (RangeStart, RangeEnd, Country, Region, City)
VALUES
    (167772160, 184549375, 'United States', 'California', 'Los Angeles'),  
    (3232235776, 3232301311, 'PrivateNet', NULL, NULL);  
GO

----------------------------------------------------------------------  
-- 2. Helper: convert IPv4 to BIGINT  
----------------------------------------------------------------------  
CREATE FUNCTION dbo.fn_ip_to_bigint(@ip VARCHAR(45))
RETURNS BIGINT
AS
BEGIN
    DECLARE 
        @b0 INT = PARSENAME(@ip,4),
        @b1 INT = PARSENAME(@ip,3),
        @b2 INT = PARSENAME(@ip,2),
        @b3 INT = PARSENAME(@ip,1);
    RETURN ISNULL(@b0,0)*16777216
         + ISNULL(@b1,0)*65536
         + ISNULL(@b2,0)*256
         + ISNULL(@b3,0);
END;
GO

----------------------------------------------------------------------  
-- 3. GeoIP lookup function  
----------------------------------------------------------------------  
CREATE FUNCTION dbo.fn_get_geo_country(@ip VARCHAR(45))
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @num BIGINT = dbo.fn_ip_to_bigint(@ip);
    RETURN (
        SELECT TOP 1 Country 
        FROM dbo.GeoIP_Lookup
        WHERE @num BETWEEN RangeStart AND RangeEnd
        ORDER BY RangeStart
    );
END;
GO

----------------------------------------------------------------------  
-- 4. IP‐validation function  
----------------------------------------------------------------------  
CREATE FUNCTION dbo.fn_is_valid_ip(@ip VARCHAR(45))
RETURNS BIT
AS
BEGIN
    -- Basic IPv4/IPv6 pattern check
    RETURN CASE 
      WHEN @ip LIKE '[0-9][0-9][0-9].%.[0-9].%' 
        OR @ip LIKE '%:%' 
      THEN 1 ELSE 0 
    END;
END;
GO

----------------------------------------------------------------------  
-- 5. Alter Alerts: add severity_level  
----------------------------------------------------------------------  
ALTER TABLE dbo.Alerts
ADD severity_level NVARCHAR(20) NOT NULL
    CONSTRAINT DF_Alerts_Severity DEFAULT 'Medium';
GO

----------------------------------------------------------------------  
-- 6. Stored Procedure: daily report  
----------------------------------------------------------------------  
CREATE PROCEDURE dbo.sp_generate_daily_report
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        CONVERT(date, le.login_time)      AS report_date,
        COUNT(*)                         AS total_logins,
        SUM(CASE WHEN le.is_successful=1 THEN 1 ELSE 0 END) AS successful_logins,
        SUM(CASE WHEN le.is_successful=0 THEN 1 ELSE 0 END) AS failed_logins,
        SUM(CASE WHEN le.abnormal_flag=1 THEN 1 ELSE 0 END) AS abnormal_logins
    FROM dbo.LoginEvents le
    GROUP BY CONVERT(date, le.login_time)
    ORDER BY report_date;
END;
GO

----------------------------------------------------------------------  
-- 7. Trend Views  
----------------------------------------------------------------------  
-- 7.1 Daily login summary  
CREATE VIEW dbo.vw_DailyLoginStats
AS
SELECT
    CONVERT(date, login_time) AS day,
    COUNT(*)                 AS total_logins,
    SUM(CASE WHEN is_successful=1 THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN is_successful=0 THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN abnormal_flag=1 THEN 1 ELSE 0 END) AS abnormal
FROM dbo.LoginEvents
GROUP BY CONVERT(date, login_time);
GO

-- 7.2 Weekly abnormal trend  
CREATE VIEW dbo.vw_WeeklyAbnormalTrend
AS
SELECT
    DATEPART(isowk, login_time) AS week_number,
    DATEPART(year, login_time)   AS year,
    COUNT(*)                    AS total_abnormal
FROM dbo.LoginEvents
WHERE abnormal_flag = 1
GROUP BY DATEPART(year, login_time), DATEPART(isowk, login_time);
GO

-- 7.3 Monthly login summary  
CREATE VIEW dbo.vw_MonthlyLoginSummary
AS
SELECT
    DATEPART(year, login_time)  AS year,
    DATEPART(month, login_time) AS month,
    COUNT(*)                   AS total_logins,
    SUM(CASE WHEN abnormal_flag=1 THEN 1 ELSE 0 END) AS total_abnormal
FROM dbo.LoginEvents
GROUP BY DATEPART(year, login_time), DATEPART(month, login_time);
GO

----------------------------------------------------------------------  
-- 8. DCL: auditor role & grants  
----------------------------------------------------------------------  
-- Create a read‐only/audit role  
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'auditor')
    CREATE ROLE auditor;
GO

-- Grant access to views and report SP  
GRANT SELECT ON dbo.vw_DailyLoginStats TO auditor;
GRANT SELECT ON dbo.vw_WeeklyAbnormalTrend TO auditor;
GRANT SELECT ON dbo.vw_MonthlyLoginSummary TO auditor;
GRANT SELECT ON dbo.vw_AbnormalSummary TO auditor;
GRANT EXECUTE ON dbo.sp_generate_daily_report TO auditor;
GO

-- Done additional setup  
