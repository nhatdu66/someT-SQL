-- File: process_unusual_login.sql
-- T-SQL Script to implement abnormal‐login detection logic:
-- 1) configuration tables, 2) stored proc, 3) trigger, 4) daily scan, 5) view

USE UnusualLoginDB;
GO

----------------------------------------------------------------------  
-- 1. Configuration tables & sample data  
----------------------------------------------------------------------  
-- 1.1 Threshold for consecutive failed logins  
CREATE TABLE dbo.ConfigThresholds (
    config_id           INT            IDENTITY(1,1) PRIMARY KEY,
    config_type         NVARCHAR(50)   NOT NULL,      -- e.g. 'FailCount'
    config_value        INT            NOT NULL,      -- e.g. 3
    time_window_minutes INT            NULL           -- e.g. 30
);
GO

INSERT dbo.ConfigThresholds (config_type, config_value, time_window_minutes)
VALUES
    ('FailCount', 3, 30);      -- 3 failures in 30 minutes triggers alert
GO

-- 1.2 Off‐hours login window (normal login between 08:00–18:00)
CREATE TABLE dbo.OffHours (
    start_time TIME NOT NULL,
    end_time   TIME NOT NULL
);
GO

INSERT dbo.OffHours (start_time, end_time)
VALUES ('08:00','18:00');
GO

-- 1.3 Trusted IP list per user
CREATE TABLE dbo.TrustedIPs (
    user_id    INT         NOT NULL
        CONSTRAINT FK_TrustedIPs_Users
            REFERENCES dbo.Users(user_id),
    ip_address VARCHAR(45) NOT NULL,
    PRIMARY KEY(user_id, ip_address)
);
GO

INSERT dbo.TrustedIPs (user_id, ip_address)
VALUES
    (1, '192.168.1.10'),
    (2, '203.0.113.5'),
    (3, '10.0.0.5');
GO

----------------------------------------------------------------------  
-- 2. Stored procedure to handle a newly inserted LoginEvent  
----------------------------------------------------------------------  
CREATE PROCEDURE dbo.sp_handle_new_login_event
    @EventID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @UserID INT,
        @LoginTime DATETIME2,
        @LoginTimeOnly TIME,
        @IP VARCHAR(45),
        @IsSuccessful BIT,
        @Desc NVARCHAR(4000),
        @AlertType NVARCHAR(50),
        @IsAbnormal BIT = 0;

    -- Fetch the new event
    SELECT
        @UserID      = user_id,
        @LoginTime   = login_time,
        @IP          = ip_address,
        @IsSuccessful= is_successful
    FROM dbo.LoginEvents
    WHERE event_id = @EventID;

    SET @LoginTimeOnly = CAST(@LoginTime AS TIME);

    ------------------------------------------------------------------
    -- 2.1 Check consecutive failed‐login threshold
    ------------------------------------------------------------------
    DECLARE
        @FailThreshold INT,
        @TimeWindow    INT,
        @FailCount     INT;

    SELECT
        @FailThreshold = config_value,
        @TimeWindow    = time_window_minutes
    FROM dbo.ConfigThresholds
    WHERE config_type = 'FailCount';

    IF (@IsSuccessful = 0)
    BEGIN
        SELECT
            @FailCount = COUNT(*)
        FROM dbo.LoginEvents
        WHERE
            user_id       = @UserID
            AND is_successful = 0
            AND login_time >= DATEADD(MINUTE, -@TimeWindow, @LoginTime);

        IF (@FailCount >= @FailThreshold)
        BEGIN
            SET @IsAbnormal = 1;
            SET @AlertType = 'Failed Login Burst';
            SET @Desc = CONCAT(
                'User ', @UserID,
                ' had ', @FailCount,
                ' failed logins within ',
                @TimeWindow, ' minutes.'
            );
        END
    END

    ------------------------------------------------------------------
    -- 2.2 Check off‐hours login
    ------------------------------------------------------------------
    DECLARE
        @OffStart TIME,
        @OffEnd   TIME;

    SELECT
        @OffStart = start_time,
        @OffEnd   = end_time
    FROM dbo.OffHours;

    IF (@LoginTimeOnly < @OffStart OR @LoginTimeOnly > @OffEnd)
    BEGIN
        SET @IsAbnormal = 1;
        SET @AlertType = 'Off-hours Login';
        SET @Desc = CONCAT(
            'User ', @UserID,
            ' logged in at off-hours (',
            CONVERT(VARCHAR(8), @LoginTimeOnly, 108),
            ').'
        );
    END

    ------------------------------------------------------------------
    -- 2.3 Check unknown IP
    ------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.TrustedIPs
        WHERE
            user_id    = @UserID
            AND ip_address = @IP
    )
    BEGIN
        SET @IsAbnormal = 1;
        SET @AlertType = 'Unknown IP';
        SET @Desc = CONCAT(
            'User ', @UserID,
            ' logged in from unknown IP ', @IP, '.'
        );
    END

    ------------------------------------------------------------------
    -- 2.4 If any rule triggered, update and insert alert
    ------------------------------------------------------------------
    IF (@IsAbnormal = 1)
    BEGIN
        UPDATE dbo.LoginEvents
        SET abnormal_flag = 1
        WHERE event_id = @EventID;

        INSERT dbo.Alerts (event_id, alert_time, alert_type, description)
        VALUES (
            @EventID,
            SYSUTCDATETIME(),
            @AlertType,
            @Desc
        );
    END
END
GO

----------------------------------------------------------------------  
-- 3. Trigger: fire SP for each new LoginEvents row  
----------------------------------------------------------------------  
CREATE TRIGGER dbo.trg_after_insert_LoginEvents
ON dbo.LoginEvents
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EID INT;
    SELECT @EID = event_id FROM inserted;
    EXEC dbo.sp_handle_new_login_event @EventID = @EID;
END
GO

----------------------------------------------------------------------  
-- 4. Daily scan procedure to catch any missed events  
----------------------------------------------------------------------  
CREATE PROCEDURE dbo.sp_daily_abnormal_scan
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EID INT;
    DECLARE evt_cursor CURSOR FOR
        SELECT event_id
        FROM dbo.LoginEvents
        WHERE
            abnormal_flag = 0
            AND login_time >= DATEADD(DAY, -1, CAST(GETDATE() AS date));

    OPEN evt_cursor;
    FETCH NEXT FROM evt_cursor INTO @EID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_handle_new_login_event @EventID = @EID;
        FETCH NEXT FROM evt_cursor INTO @EID;
    END

    CLOSE evt_cursor;
    DEALLOCATE evt_cursor;
END
GO

----------------------------------------------------------------------  
-- 5. View: summary of abnormal events per user  
----------------------------------------------------------------------  
CREATE VIEW dbo.vw_AbnormalSummary
AS
SELECT
    u.user_id,
    u.username,
    COUNT(le.event_id)       AS abnormal_count,
    MAX(le.login_time)       AS last_abnormal_time
FROM dbo.LoginEvents le
JOIN dbo.Users u
    ON le.user_id = u.user_id
WHERE le.abnormal_flag = 1
GROUP BY
    u.user_id,
    u.username;
GO
