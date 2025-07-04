CREATE TABLE Students(
StudentID INT NOT NULL,
Name NVARCHAR(50) NULL,
Sddress NVARCHAR(200) NULL,
Gender CHAR(1) NULL,
CONSTRAINT PK_Students PRIMARY KEY (StudentID)
);
GO
CREATE TABLE Teachers(
TeacherID INT NOT NULL,
Name NVARCHAR(50) NULL,
Gender CHAR(1) NULL,
Address NVARCHAR(200) NULL,
CONSTRAINT PK_Teachers Primary KEY (TeacherID)
);
GO
CREATE Table Classes(
ClassID INT NOT NULL,
GroupID CHAR(6) NULL,
CourseID CHAR(6) NULL,
NoCredits INT NULL,
Year INT NULL,
Constraint PK_Classes primary key (CLassID)
);
GO
CREATE TABLE Attend(
StudentID INT NOT NULL,
ClassID int NOT NULL,
Date Date NOT NULL,
SLot INT NOT NULL,
Attend BIT NULL,
Constraint PK_Attend primary key (StudentID, CLassID, Date, Slot),
Constraint FK_Attend_Students foreign key (StudentID) references Students (StudentID),
Constraint FK_Attend_Classes foreign key (ClassID) references Class (ClassID)
)