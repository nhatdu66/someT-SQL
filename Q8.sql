use PE_Demo_S2019; 
GO
create procedure TotalAmount
@OrderID NVARCHAR(255),
@TotalAmount FLOAT OUTPUT
as
BEGIN
SET NOCOUNT ON;
SELECT @TotalAmount = Sum(Quantity * SalePrice * (1-Discount))
FROM OrderDetails
where OrderID = @OrderID;
IF @TotalAmount IS NULL
SET @TotalAmount = 0;
END;
go