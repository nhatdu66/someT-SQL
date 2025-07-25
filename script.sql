-- File: script_labeled.sql
-- T-SQL Script with labeled sections and sample outputs for each requirement

USE UnusualLoginDB;
GO

------------------------------------------------------------------------
-- a) Abnormal login events in the last 24 hours
------------------------------------------------------------------------
PRINT '==== a) Abnormal login events in last 24 hours ====';
SELECT
    le.event_id,
    le.user_id,
    u.username,
    le.login_time,
    le.ip_address,
    a.alert_type,
    a.description
FROM dbo.LoginEvents AS le
JOIN dbo.Alerts AS a
  ON le.event_id = a.event_id
JOIN dbo.Users AS u
  ON le.user_id = u.user_id
WHERE le.abnormal_flag = 1
  AND le.login_time >= DATEADD(HOUR, -24, GETDATE());
GO

------------------------------------------------------------------------
-- b) User login counts: total, successful, failed
------------------------------------------------------------------------
PRINT '==== b) User login counts ====';
SELECT
    u.username,
    COUNT(le.event_id) AS total_logins,
    SUM(CASE WHEN le.is_successful = 1 THEN 1 ELSE 0 END) AS successful_logins,
    SUM(CASE WHEN le.is_successful = 0 THEN 1 ELSE 0 END) AS failed_logins
FROM dbo.Users AS u
LEFT JOIN dbo.LoginEvents AS le
  ON u.user_id = le.user_id
GROUP BY u.username;
GO

------------------------------------------------------------------------
-- c/d/e) Trigger for 3 failures in 30 minutes:
--    c) auto‐detect via trigger
--    d) count fails in last 30m
--    e) if >=3, flag & alert
------------------------------------------------------------------------
PRINT '==== c/d/e) Inserting 3 fails for user 1 to test trigger ====';
-- Insert 3 failed events for user_id = 1
INSERT INTO dbo.LoginEvents (
    user_id, login_time, ip_address, device_info, is_successful
)
VALUES
    (1, DATEADD(MINUTE, -20, GETDATE()), '10.0.0.99', 'TestDevice', 0),
    (1, DATEADD(MINUTE, -10, GETDATE()), '10.0.0.99', 'TestDevice', 0),
    (1, GETDATE(),                        '10.0.0.99', 'TestDevice', 0);
GO

PRINT 'Inserted events:';
SELECT TOP(3)
    event_id,
    user_id,
    login_time,
    ip_address,
    is_successful,
    abnormal_flag
FROM dbo.LoginEvents
WHERE user_id = 1
  AND ip_address = '10.0.0.99'
ORDER BY login_time DESC;
GO

PRINT 'Generated alerts for those events:';
SELECT
    alert_id,
    event_id,
    alert_time,
    alert_type,
    description
FROM dbo.Alerts
WHERE alert_type = 'Failed Login Burst'
  AND description LIKE '%10.0.0.99%';
GO

------------------------------------------------------------------------
-- f) Stored Procedure: daily report for today
------------------------------------------------------------------------
PRINT '==== f) Today''s login report ====';
EXEC dbo.sp_generate_daily_report;
GO

------------------------------------------------------------------------
-- g) Function: IP‐validation tests
------------------------------------------------------------------------
PRINT '==== g) IP format validation ====';
SELECT
    t.ip_address,
    dbo.fn_is_valid_ip(t.ip_address) AS is_valid_ip
FROM (VALUES
    ('192.168.0.1'),
    ('999.999.999.999'),
    ('fe80::1'),
    ('not_an_ip')
) AS t(ip_address);
GO
