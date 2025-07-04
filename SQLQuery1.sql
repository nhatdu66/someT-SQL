SELECT *
FROM LoginEvents
WHERE abnormal_flag = 1
  AND login_time >= DATEADD(DAY, -1, GETDATE());
SELECT 
    u.username,
    COUNT(le.event_id) AS total_logins,
    SUM(CASE WHEN le.is_successful = 1 THEN 1 ELSE 0 END) AS successful_logins,
    SUM(CASE WHEN le.is_successful = 0 THEN 1 ELSE 0 END) AS failed_logins
FROM Users u
JOIN LoginEvents le ON u.user_id = le.user_id
GROUP BY u.username, u.user_id;