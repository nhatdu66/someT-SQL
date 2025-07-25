use PE_DBI202;
go

--q1
CREATE TABLE tblAirport (
    Airportcode  nchar(10)    NOT NULL PRIMARY KEY,
    Name         nvarchar(20)  NULL,
    City         nvarchar(50)  NULL,
    State        nvarchar(50)  NULL
);

CREATE TABLE tblAirPlane (
    AirplaneID    nchar(10)    NOT NULL PRIMARY KEY,
    AirplaneName  nvarchar(20)  NULL,
    TotalSeat     int           NULL,
    Company       nvarchar(50)  NULL
);

CREATE TABLE CanLand (
    Airportcode  nchar(10)    NOT NULL,
    AirplaneID   nchar(10)    NOT NULL,
    TimeLand     datetime      NULL,
    PRIMARY KEY (Airportcode, AirplaneID),
    FOREIGN KEY (Airportcode) REFERENCES tblAirport(Airportcode),
    FOREIGN KEY (AirplaneID)  REFERENCES tblAirPlane(AirplaneID)
);

--q2
SELECT 
    s.StudentID,
    s.StudentLastName,
    s.StudentFirstName,
    d.DepartmentName
FROM Students s
JOIN Departments d
  ON s.DepartmentID = d.DepartmentID
WHERE d.DepartmentName = 'Computer Science';

--q3
SELECT 
    StudentID,
    StudentLastName,
    StudentFirstName
FROM Students
WHERE StudentFirstName LIKE 'T%'
ORDER BY StudentLastName;

--q4
SELECT
    StudentID,
    StudentLastName,
    StudentFirstName,
    DATEDIFF(YEAR, StudentBirthday, GETDATE()) AS Age
FROM Students
WHERE DATEDIFF(YEAR, StudentBirthday, GETDATE()) > 20;

--q5
SELECT
    d.DepartmentID,
    d.DepartmentName,
    COUNT(s.StudentID) AS NumberOfStudents
FROM Departments d
LEFT JOIN Students s
  ON d.DepartmentID = s.DepartmentID
GROUP BY
    d.DepartmentID,
    d.DepartmentName;

--q6
WITH LatestAttempt AS (
    SELECT
        StudentID,
        SubjectID,
        MAX(NumberExams) AS MaxExam
    FROM Results
    GROUP BY
        StudentID,
        SubjectID
)
SELECT
    r.StudentID,
    st.StudentFirstName,
    st.StudentLastName,
    sb.SubjectName,
    r.Score AS FinalGrade
FROM Results r
JOIN LatestAttempt la
  ON r.StudentID  = la.StudentID
 AND r.SubjectID  = la.SubjectID
 AND r.NumberExams= la.MaxExam
JOIN Students st
  ON r.StudentID = st.StudentID
JOIN Subjects sb
  ON r.SubjectID = sb.SubjectID
ORDER BY
    r.StudentID;


--q7
WITH FailCounts AS (
    SELECT
        sub.DepartmentID,
        d.DepartmentName,
        sub.SubjectID,
        sub.SubjectName,
        COUNT(*) AS NumberOfFailExams
    FROM Results r
    JOIN Subjects sub
      ON r.SubjectID = sub.SubjectID
    JOIN Departments d
      ON sub.DepartmentID = d.DepartmentID
    WHERE r.Score < 5
    GROUP BY
        sub.DepartmentID,
        d.DepartmentName,
        sub.SubjectID,
        sub.SubjectName
),
MaxFails AS (
    SELECT
        DepartmentID,
        MAX(NumberOfFailExams) AS MaxFail
    FROM FailCounts
    GROUP BY DepartmentID
)
SELECT
    fc.DepartmentName,
    fc.SubjectName,
    fc.NumberOfFailExams
FROM FailCounts fc
JOIN MaxFails mf
  ON fc.DepartmentID      = mf.DepartmentID
 AND fc.NumberOfFailExams = mf.MaxFail;

 --q8
 SELECT
    StudentID,
    StudentLastName,
    StudentFirstName
FROM Students
WHERE StudentScholarship = (
    SELECT MAX(s2.StudentScholarship)
    FROM Students s2
    JOIN Departments d2
      ON s2.DepartmentID = d2.DepartmentID
    WHERE d2.DepartmentName = 'Mathematics'
);

--q9
CREATE PROCEDURE proc_report
    @deptname varchar(50),
    @result   int OUTPUT
AS
BEGIN
    SELECT
        @result = COUNT(s.StudentID)
    FROM Students s
    JOIN Departments d
      ON s.DepartmentID = d.DepartmentID
    WHERE d.DepartmentName = @deptname;
END;

--q10
CREATE FUNCTION fn_students(@departmentID int)
RETURNS TABLE
AS
RETURN
(
    SELECT
        StudentID,
        StudentLastName,
        StudentFirstName,
        StudentSex,
        StudentBirthday,
        StudentEmail,
        StudentPhone,
        StudentAddress,
        DepartmentID,
        StudentScholarship
    FROM Students
    WHERE DepartmentID       = @departmentID
      AND StudentScholarship > 0
);
