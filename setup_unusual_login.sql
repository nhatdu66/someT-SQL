-- File: setup_unusual_login.sql
-- T-SQL Script to create database, schema and insert sample data

----------------------------------------------------------------------  
-- 1. Create Database  
----------------------------------------------------------------------  
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'UnusualLoginDB')  
    DROP DATABASE UnusualLoginDB;  
GO  

CREATE DATABASE UnusualLoginDB;  
GO  

USE UnusualLoginDB;  
GO  

----------------------------------------------------------------------  
-- 2. Create Tables  
----------------------------------------------------------------------  

-- 2.1 Users  
CREATE TABLE dbo.Users (  
    user_id         INT            IDENTITY(1,1) NOT NULL PRIMARY KEY,  
    username        NVARCHAR(50)   NOT NULL,  
    email           NVARCHAR(100)  NOT NULL UNIQUE,  
    password_hash   NVARCHAR(255)  NOT NULL,  
    CONSTRAINT CHK_Users_EmailFormat CHECK (email LIKE '%_@__%.__%')  
);  
GO  

-- 2.2 LoginEvents  
CREATE TABLE dbo.LoginEvents (  
    event_id        INT            IDENTITY(1,1) NOT NULL PRIMARY KEY,  
    user_id         INT            NOT NULL,  
    login_time      DATETIME2      NOT NULL,  
    ip_address      VARCHAR(45)    NOT NULL,  
    device_info     NVARCHAR(100)  NULL,  
    is_successful   BIT            NOT NULL,  
    abnormal_flag   BIT            NOT NULL DEFAULT (0),  
    CONSTRAINT FK_LoginEvents_Users  
        FOREIGN KEY(user_id) REFERENCES dbo.Users(user_id),  
    CONSTRAINT CHK_LoginEvents_IsSuccessful  
        CHECK (is_successful IN (0,1)),  
    CONSTRAINT CHK_LoginEvents_AbnormalFlag  
        CHECK (abnormal_flag IN (0,1))  
);  
GO  

-- 2.3 Alerts  
CREATE TABLE dbo.Alerts (  
    alert_id        INT            IDENTITY(1,1) NOT NULL PRIMARY KEY,  
    event_id        INT            NOT NULL,  
    alert_time      DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),  
    alert_type      NVARCHAR(50)   NOT NULL,  
    description     NVARCHAR(4000) NULL,  
    CONSTRAINT FK_Alerts_LoginEvents  
        FOREIGN KEY(event_id) REFERENCES dbo.LoginEvents(event_id),  
    CONSTRAINT CHK_Alerts_AlertType  
        CHECK (alert_type IN  
            ('Failed Login Burst', 'Unknown IP', 'Off-hours Login')  
        )  
);  
GO  

----------------------------------------------------------------------  
-- 3. Indexes for Performance  
----------------------------------------------------------------------  
CREATE INDEX IX_LoginEvents_LoginTime  
    ON dbo.LoginEvents(login_time);  

CREATE INDEX IX_LoginEvents_AbnormalFlag  
    ON dbo.LoginEvents(abnormal_flag);  
GO  

----------------------------------------------------------------------  
-- 4. Insert Sample Data  
----------------------------------------------------------------------  

-- 4.1 Users  
INSERT INTO dbo.Users (username, email, password_hash)  
VALUES  
    ('userA', 'userA@example.com', 'hashed_password_A'),  
    ('userB', 'userB@example.com', 'hashed_password_B'),  
    ('userC', 'userC@example.com', 'hashed_password_C');  
GO  

-- 4.2 LoginEvents (some normal, some failed)  
INSERT INTO dbo.LoginEvents (user_id, login_time, ip_address, device_info, is_successful)  
VALUES  
    -- Normal login  
    (1, '2025-07-23T08:00:00', '192.168.1.10', 'Chrome on Windows', 1),  
    -- Three consecutive failures within 10 minutes  
    (1, '2025-07-23T08:05:00', '192.168.1.10', 'Chrome on Windows', 0),  
    (1, '2025-07-23T08:07:00', '192.168.1.10', 'Chrome on Windows', 0),  
    (1, '2025-07-23T08:10:00', '192.168.1.10', 'Chrome on Windows', 0),  

    -- Off-hours login  
    (2, '2025-07-23T23:50:00', '203.0.113.5', 'Firefox on Linux', 1),  

    -- Login from unusual IP next day  
    (2, '2025-07-24T00:10:00', '198.51.100.7', 'Firefox on Linux', 1),  

    -- Normal login for another user  
    (3, '2025-07-24T09:00:00', '10.0.0.5', 'Safari on iOS', 1);  
GO  

-- 4.3 Mark abnormal_flag for known abnormal events  
UPDATE dbo.LoginEvents  
SET abnormal_flag = 1  
WHERE event_id IN (3, 4, 6);  
GO  

-- 4.4 Alerts for those abnormal events  
INSERT INTO dbo.Alerts (event_id, alert_type, description)  
VALUES  
    (3, 'Failed Login Burst',  
     'User 1 had 3 failed logins within 10 minutes'),  

    (4, 'Failed Login Burst',  
     'User 1 had 3 failed logins within 10 minutes'),  

    (6, 'Unknown IP',  
     'User 2 logged in from unusual IP 198.51.100.7'),  

    (5, 'Off-hours Login',  
     'User 2 logged in at 23:50, outside normal hours');  
GO  
