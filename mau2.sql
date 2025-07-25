CREATE DATABASE Book_Management_System

USE Book_Management_System
-- Create Category table
CREATE TABLE Category (
    CategoryID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL
);

-- Create Book table
CREATE TABLE Book (
    BookID INT PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Author NVARCHAR(100),
	Status VARCHAR(100) NOT NULL CHECK (Status IN ('Overdue', 'Available', 'Borrowed')) DEFAULT 'Available', 
	Description NVarchar(1000),
    CategoryID INT,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
);

-- Create Reader table
CREATE TABLE Reader (
    ReaderID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15),
    Address NVARCHAR(200)
);

-- Insert data into Category table
INSERT INTO Category (CategoryID, Name) VALUES
(1, 'Văn học'),
(2, 'Khoa học'),
(3, 'Lịch sử'),
(4, 'Trẻ em');

-- Insert data into Book table
INSERT INTO Book (BookID, Title, Author, CategoryID, Quantity, Status, Description) VALUES
(1, 'Dế Mèn Phiêu Lưu Ký', 'Tô Hoài', 1, 5, 'Overdue', 'Dế Mèn Phiêu Lưu Ký'),
(2, 'Cơ học lượng tử', 'Nguyễn Văn A', 2, 3, 'Available', 'Cơ học lượng tử'),
(3, 'Lịch sử Việt Nam', 'Trần Quốc Vượng', 3, 4, 'Borrowed', 'Lịch sử Việt Nam'),
(4, 'Cây khế nhà em', 'Lê Minh Khuê', 4, 6, 'Borrowed', 'Cây khế nhà em');

-- Insert data into Reader table
INSERT INTO Reader (ReaderID, Name, Phone, Address) VALUES
(1, 'Nguyễn Văn Hùng', '0901234567', '123 Đường Láng, Hà Nội'),
(2, 'Trần Thị Mai', '0912345678', '45 Lê Lợi, TP.HCM'),
(3, 'Lê Hoàng Nam', '0923456789', '78 Trần Phú, Đà Nẵng'),
(4, 'Phạm Thị Lan', '0934567890', '12 Nguyễn Huệ, Huế');

--Question 2
--Create  Employee table
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15),
    Position NVARCHAR(50) NOT NULL
);

-- Tạo bảng BookLoanSlip
CREATE TABLE BookLoanSlip (
    BookLoanSlipID INT PRIMARY KEY,
    BorrowDate DATE NOT NULL,
    ReturnDate DATE,
    Purpose VARCHAR(50) NOT NULL 
        CHECK (Purpose IN ('At reading room', 'At home')) 
        DEFAULT 'At home',
    BookID INT NOT NULL,
    ReaderID INT NOT NULL,
    EmployeeID INT NOT NULL,
    FOREIGN KEY (BookID) REFERENCES Book(BookID),
    FOREIGN KEY (ReaderID) REFERENCES Reader(ReaderID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

--insert data for Employee table
INSERT INTO Employee (EmployeeID, Name, Phone, Position) 
VALUES 
(1, 'Nguyễn Văn An', '0987654321', 'Thủ thư'),
(2, 'Trần Thị Bình', '0978123456', 'Quản lý kho'),
(3, 'Lê Văn Cường', '0967891234', 'Nhân viên');

INSERT INTO BookLoanSlip (BookLoanSlipID, BorrowDate, ReturnDate, Purpose, BookID, ReaderID, EmployeeID) 
VALUES 
(1, '2023-10-01', '2023-10-10', 'At home', 1, 1, 1),
(2, '2023-10-02', NULL, 'At reading room', 2, 2, 2),
(3, '2023-10-03', NULL, DEFAULT, 3, 3, 3);

--Question 3 CREATE PROCEDURE
CREATE PROCEDURE Sp_AddBorrowHistory
    @BookLoanSlipID INT,
    @BorrowDate DATE,
    @ReturnDate DATE = NULL,
    @Purpose VARCHAR(50) = 'At home',
    @BookID INT,
    @ReaderID INT,
    @EmployeeID INT
AS
BEGIN
    -- Kiểm tra trạng thái sách
    DECLARE @BookStatus VARCHAR(100);
    SELECT @BookStatus = Status 
    FROM Book 
    WHERE BookID = @BookID;

    -- Nếu sách đã được mượn (Borrowed), không cho phép thêm
    IF @BookStatus = 'Borrowed'
    BEGIN
        RAISERROR('Sách đã được mượn, không thể thêm phiếu mượn mới.', 16, 1);
        RETURN;
    END

    -- Nếu sách chưa được mượn, thêm phiếu mượn và cập nhật trạng thái
    ELSE
    BEGIN
        -- Thêm phiếu mượn vào BookLoanSlip
        INSERT INTO BookLoanSlip (BookLoanSlipID, BorrowDate, ReturnDate, Purpose, BookID, ReaderID, EmployeeID)
        VALUES (@BookLoanSlipID, @BorrowDate, @ReturnDate, @Purpose, @BookID, @ReaderID, @EmployeeID);

        -- Cập nhật trạng thái sách thành "Borrowed"
        UPDATE Book 
        SET Status = 'Borrowed', Quantity = Quantity - 1 
        WHERE BookID = @BookID;

        PRINT 'Thêm phiếu mượn thành công.';
    END
END;


--Question 4 CREATE TRIGGER 
CREATE TRIGGER Trg_UpdateBookStatus
ON BookLoanSlip
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra từng bản ghi được chèn
    DECLARE @BookID INT;
    DECLARE @CurrentStatus VARCHAR(100);

    -- Lặp qua các bản ghi trong inserted
    DECLARE cursor_inserted CURSOR FOR
    SELECT BookID FROM inserted;

    OPEN cursor_inserted;
    FETCH NEXT FROM cursor_inserted INTO @BookID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Lấy trạng thái hiện tại của sách
        SELECT @CurrentStatus = Status 
        FROM Book 
        WHERE BookID = @BookID;

        -- Nếu sách đã được mượn, rollback và thông báo lỗi
        IF @CurrentStatus = 'Borrowed'
        BEGIN
            RAISERROR('Sách đã được mượn. Không thể tạo phiếu mượn.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Nếu sách có sẵn, cập nhật trạng thái thành "Borrowed"
        ELSE IF @CurrentStatus = 'Available'
        BEGIN
            UPDATE Book
            SET Status = 'Borrowed', Quantity = Quantity - 1
            WHERE BookID = @BookID;
        END

        FETCH NEXT FROM cursor_inserted INTO @BookID;
    END

    CLOSE cursor_inserted;
    DEALLOCATE cursor_inserted;
END;

--Question 5 CREATE VIEW 
CREATE VIEW vw_OverdueBorrowHistory AS
SELECT 
    b.Title AS BookTitle,
    r.Name AS ReaderName,
    bls.BorrowDate,
    bls.ReturnDate,
    DATEDIFF(DAY, bls.BorrowDate, GETDATE()) AS DaysBorrowed,
    CASE 
        WHEN bls.ReturnDate IS NULL AND DATEDIFF(DAY, bls.BorrowDate, GETDATE()) > 14 
        THEN 'Overdue: Exceeded 14 days' 
        ELSE 'On time' 
    END AS Note
FROM 
    BookLoanSlip bls
JOIN 
    Book b ON bls.BookID = b.BookID
JOIN 
    Reader r ON bls.ReaderID = r.ReaderID
WHERE 
    bls.ReturnDate IS NULL;  -- Chỉ hiển thị sách chưa trả

--select View
SELECT * FROM vw_OverdueBorrowHistory;
--or
SELECT * FROM vw_OverdueBorrowHistory 
WHERE Note LIKE 'Overdue%';