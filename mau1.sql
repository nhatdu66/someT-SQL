-- Q1.sql

CREATE TABLE Banks (
    SWIFTCode   varchar(15)    NOT NULL,
    Name        nvarchar(200)  NOT NULL,
    PRIMARY KEY (SWIFTCode)
);

CREATE TABLE Branches (
    BranchNo    varchar(20)    NOT NULL,
    Address     nvarchar(200)  NOT NULL,
    City        nvarchar(50)   NOT NULL,
    Country     nvarchar(50)   NOT NULL,
    --OpenedAt    datetime       NOT NULL,
    SWIFTCode   varchar(15)    NOT NULL,
    PRIMARY KEY (BranchNo),
    FOREIGN KEY (SWIFTCode) REFERENCES Banks(SWIFTCode)
);

CREATE TABLE Accounts (
    AccountNo   varchar(30)    NOT NULL,
    Balance     float          NOT NULL,
    BranchNo    varchar(20)    NOT NULL,
    Type        nvarchar(100)  NULL,
    PRIMARY KEY (AccountNo),
    FOREIGN KEY (BranchNo) REFERENCES Branches(BranchNo)
);

-- Q2.sql
SELECT 
    MenuItemID,
    Name,
    Description,
    Price,
    Category
FROM MenuItems
WHERE Category = 'Main Course'
  AND Price BETWEEN 25000 AND 50000;

-- Q3
SELECT
    o.OrderID,
    o.OrderDate,
    c.FullName   AS CustomerFullName,
    c.PhoneNumber,
    rt.TableNumber,
    rt.Capacity
FROM Orders o
JOIN Customers c 
  ON o.CustomerID = c.CustomerID
JOIN RestaurantTables rt 
  ON o.TableID = rt.TableID
WHERE rt.Capacity = 6
  AND o.OrderDate >= '2024-11-01'
  AND o.OrderDate <  '2025-01-01';

  --Q4
  SELECT
    e.EmployeeID,
    e.FullName    AS EmployeeFullName,
    e.Role,
    o.OrderID,
    o.OrderDate,
    o.CustomerID,
    c.FullName    AS CustomerFullName
FROM Employees e
LEFT JOIN Orders o
  ON e.EmployeeID = o.EmployeeID
  AND o.OrderDate >= '2025-03-01'
  AND o.OrderDate <  '2025-05-01'
LEFT JOIN Customers c
  ON o.CustomerID = c.CustomerID
WHERE e.Role = 'Chef'
ORDER BY e.FullName ASC,
         o.OrderID DESC;

--Q5
SELECT
    mi.MenuItemID,
    mi.Name,
    mi.Category,
    COALESCE(SUM(od.Quantity), 0)               AS TotalQuantity,
    COALESCE(SUM(od.Quantity * od.Price), 0.00)  AS TotalAmount,
    COALESCE(COUNT(DISTINCT o.CustomerID), 0)    AS NumberOfCustomers
FROM MenuItems mi
LEFT JOIN OrderDetails od
  ON mi.MenuItemID = od.MenuItemID
LEFT JOIN Orders o
  ON od.OrderID = o.OrderID
  AND o.OrderDate >= '2024-10-01'
  AND o.OrderDate <  '2024-11-01'
WHERE mi.Category = 'Main Course'
GROUP BY
    mi.MenuItemID,
    mi.Name,
    mi.Category
ORDER BY
    mi.MenuItemID;

--Q6
WITH EmpOrderCounts AS (
    SELECT
        e.EmployeeID,
        e.FullName,
        e.Role,
        COUNT(o.OrderID) AS OrderCount
    FROM Employees e
    LEFT JOIN Orders o
      ON e.EmployeeID = o.EmployeeID
    GROUP BY
        e.EmployeeID,
        e.FullName,
        e.Role
),
AvgCount AS (
    SELECT AVG(OrderCount) AS AvgOrderCount
    FROM EmpOrderCounts
)
SELECT
    eoc.EmployeeID,
    eoc.FullName,
    eoc.Role,
    eoc.OrderCount
FROM EmpOrderCounts eoc
JOIN AvgCount ac
  ON eoc.OrderCount > ac.AvgOrderCount
ORDER BY
    eoc.OrderCount DESC,
    eoc.FullName    ASC;


--Q7
WITH ItemTotals AS (
    SELECT
        mi.Category,
        mi.MenuItemID,
        mi.Name,
        SUM(od.Quantity) AS TotalQty
    FROM MenuItems mi
    JOIN OrderDetails od
      ON mi.MenuItemID = od.MenuItemID
    GROUP BY
        mi.Category,
        mi.MenuItemID,
        mi.Name
),
MaxItemPerCat AS (
    SELECT
        Category,
        MAX(TotalQty) AS MaxQty
    FROM ItemTotals
    GROUP BY Category
),
PopularItems AS (
    SELECT
        it.Category,
        it.MenuItemID,
        it.Name
    FROM ItemTotals it
    JOIN MaxItemPerCat mipc
      ON it.Category = mipc.Category
     AND it.TotalQty  = mipc.MaxQty
),
CustomerTotals AS (
    SELECT
        od.MenuItemID,
        o.CustomerID,
        c.FullName,
        SUM(od.Quantity) AS CustQty
    FROM OrderDetails od
    JOIN Orders o
      ON od.OrderID = o.OrderID
    JOIN Customers c
      ON o.CustomerID = c.CustomerID
    GROUP BY
        od.MenuItemID,
        o.CustomerID,
        c.FullName
),
MaxCustPerItem AS (
    SELECT
        MenuItemID,
        MAX(CustQty) AS MaxCustQty
    FROM CustomerTotals
    GROUP BY MenuItemID
)
SELECT
    pi.Category,
    pi.MenuItemID,
    pi.Name,
    ct.CustomerID,
    ct.FullName,
    ct.CustQty AS TotalQuantity
FROM PopularItems pi
JOIN MaxCustPerItem mcp
  ON pi.MenuItemID = mcp.MenuItemID
JOIN CustomerTotals ct
  ON pi.MenuItemID = ct.MenuItemID
 AND ct.CustQty    = mcp.MaxCustQty
ORDER BY
    pi.Category;


--Q8
CREATE PROCEDURE AddReservation
    @ReservationID    INT,
    @CustomerID       INT,
    @TableID          INT,
    @ReservationTime  DATETIME,
    @NumberOfPeople   INT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Reservations
        WHERE TableID         = @TableID
          AND ReservationTime = @ReservationTime
          AND Status         = 'Confirmed'
    )
    BEGIN
        INSERT INTO Reservations
            (ReservationID, CustomerID, TableID, ReservationTime, NumberOfPeople, Status)
        VALUES
            (@ReservationID, @CustomerID, @TableID, @ReservationTime, @NumberOfPeople, 'Confirmed');
    END
END;


--Q9
CREATE TRIGGER TrinsertReservation
ON Reservations
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN RestaurantTables rt
          ON i.TableID = rt.TableID
        WHERE i.NumberOfPeople > rt.Capacity
    )
    BEGIN
        RETURN;
    END

    INSERT INTO Reservations
        (ReservationID, CustomerID, TableID, ReservationTime, NumberOfPeople, Status)
    SELECT
        ReservationID,
        CustomerID,
        TableID,
        ReservationTime,
        NumberOfPeople,
        Status
    FROM inserted;
END;


--Q10
UPDATE MenuItems
SET Price = Price * 1.10
WHERE Category = 'Main Course';
