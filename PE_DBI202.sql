Create database PE_DBI202_FA24
Go
--Use the database
use PE_DBI202_FA24
--Create all tables

CREATE TABLE Books (
    BookID INT PRIMARY KEY IDENTITY(1,1),
    Title VARCHAR(255) NOT NULL,
    AuthorID INT,
    PublicationYear int NOT NULL,
    Genre VARCHAR(50),
    AvailableCopies INT NOT NULL
);

CREATE TABLE Borrowers (
    BorrowerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    MembershipDate DATE NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Loans (
    LoanID INT PRIMARY KEY IDENTITY(1,1),
    BorrowerID INT,
    LoanDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    FOREIGN KEY (BorrowerID) REFERENCES Borrowers(BorrowerID),
    CONSTRAINT chk_due_date CHECK (DueDate >= LoanDate)
);

CREATE TABLE DetailLoans (
    DetailLoanID INT PRIMARY KEY IDENTITY(1,1),
    LoanID INT,
    BookID INT,
    ReturnDate DATE,
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);

INSERT INTO Books (Title, AuthorID, PublicationYear, Genre, AvailableCopies)
VALUES 
('Harry Potter and the Sorcerers Stone', 1, 1997, 'Fantasy', 5),
('1984', 2, 1949, 'Dystopian', 3),
('Norwegian Wood', 3, 1987, 'Romance', 4),
('The Hobbit', 4, 1937, 'Fantasy', 2),
('One Hundred Years of Solitude', 5, 1967, 'Magical Realism', 6);

INSERT INTO Borrowers (FirstName, LastName, MembershipDate, Email)
VALUES 
('Alice', 'Smith', '2020-06-15', 'alice@example.com'),
('Bob', 'Johnson', '2019-11-10', 'bob@example.com'),
('Charlie', 'Brown', '2021-02-25', 'charlie@example.com'),
('David', 'Williams', '2018-07-30', 'david@example.com'),
('Eva', 'Davis', '2021-05-10', 'eva@example.com');

INSERT INTO Loans (BorrowerID, LoanDate, DueDate)
VALUES 
(1, '2023-10-10', '2023-11-10'),
(2, '2023-10-05', '2023-11-05'),
(3, '2023-10-08', '2023-11-08'),
(4, '2023-09-30', '2023-10-30'),
(5, '2023-10-12', '2023-11-12');

INSERT INTO DetailLoans (LoanID, BookID, ReturnDate)
VALUES 
(1, 1, '2023-11-10'),
(1, 2, '2023-11-11'),
(3, 3, NULL),
(4, 4, NULL),
(5, 5, NULL);


--Solution
-- Question 2: 
-- create table
CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY IDENTITY(1,1), 
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    Nationality VARCHAR(100) NOT NULL
);
--Insert data for the table
INSERT INTO Authors (FirstName, LastName, BirthDate, Nationality)
VALUES 
('J.K.', 'Rowling', '1965-07-31', 'British'),
('George', 'Orwell', '1903-06-25', 'British'),
('Haruki', 'Murakami', '1949-01-12', 'Japanese'),
('J.R.R.', 'Tolkien', '1892-01-03', 'British'),
('Gabriel', 'García Márquez', '1927-03-06', 'Colombian');

-- The command alter the table Book constraint, 

ALTER TABLE Books
ADD CONSTRAINT FK_Books_Authors
FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID);

--creating a foreign key to link the Book and table Authors
UPDATE Books
SET AuthorID = 1 
WHERE Title = 'Harry Potter and the Sorcerers Stone';

UPDATE Books
SET AuthorID = 2 
WHERE Title = '1984';

UPDATE Books
SET AuthorID = 3 
WHERE Title = 'Norwegian Wood';

UPDATE Books
SET AuthorID = 4 
WHERE Title = 'The Hobbit';

UPDATE Books
SET AuthorID = 5 
WHERE Title = 'One Hundred Years of Solitude';

--Question 3: Store procedure
GO
CREATE PROCEDURE GetBorrowedBooksInfo
    @BorrowerID INT
AS
BEGIN
    SELECT 
        b.BookID,
        b.Title,
        b.Genre,
        b.PublicationYear,
        l.LoanDate,
        l.DueDate,
        dl.ReturnDate
    FROM 
        Loans l
    INNER JOIN DetailLoans dl ON l.LoanID = dl.LoanID
    INNER JOIN Books b ON dl.BookID = b.BookID
    WHERE 
        l.BorrowerID = @BorrowerID;

    SELECT 
        b.BookID,
        b.Title,
        b.Genre,
        b.PublicationYear,
        l.LoanDate,
        l.DueDate
    FROM 
        Loans l
    INNER JOIN DetailLoans dl ON l.LoanID = dl.LoanID
    INNER JOIN Books b ON dl.BookID = b.BookID
    WHERE 
        l.BorrowerID = @BorrowerID
        AND dl.ReturnDate IS NULL;
END;
GO


--Test the store procedure

EXEC GetBorrowedBooksInfo @BorrowerID = 1;

--Question 4: Create the trigger
Go
CREATE TRIGGER trg_CheckAvailableCopies
ON DetailLoans
AFTER INSERT
AS
BEGIN
    -- Biến dùng để lưu thông tin BookID
    DECLARE @BookID INT;

    -- Lấy BookID từ bảng inserted (hàng mới được thêm)
    SELECT @BookID = BookID FROM inserted;

    -- Kiểm tra xem số bản sao khả dụng có bằng 0 không
    IF EXISTS (
        SELECT 1 
        FROM Books 
        WHERE BookID = @BookID AND AvailableCopies = 0
    )
    BEGIN
        -- Rollback giao dịch và hiển thị thông báo lỗi
        ROLLBACK TRANSACTION;
        RAISERROR ('The book is out of stock and cannot be borrowed.', 16, 1);
    END
    ELSE
    BEGIN
        -- Nếu sách còn khả dụng, giảm số lượng AvailableCopies đi 1
        UPDATE Books
        SET AvailableCopies = AvailableCopies - 1
        WHERE BookID = @BookID;
    END
END;


--Test the Trigger
INSERT INTO DetailLoans (LoanID, BookID, ReturnDate)
VALUES (1, 4, NULL);
--Question 5: Create view for display booking fee
Go
CREATE VIEW OverdueLoans AS
SELECT 
    b.Title AS BookTitle,
    br.FirstName AS BorrowerFirstName,
    br.LastName AS BorrowerLastName,
    l.LoanDate,
    l.DueDate,
    CASE
        WHEN l.DueDate <= GETDATE() THEN 
            'You are overdue for returning the book.'
        WHEN l.DueDate > GETDATE() THEN 
            'Please make sure to return on time.'
    END AS Notes
FROM 
    Loans l
INNER JOIN Borrowers br ON l.BorrowerID = br.BorrowerID 
INNER JOIN DetailLoans dl ON l.LoanID = dl.LoanID
INNER JOIN Books b ON dl.BookID = b.BookID
WHERE 
    dl.ReturnDate IS NULL;

--Test the View
SELECT * FROM OverdueLoans;
















