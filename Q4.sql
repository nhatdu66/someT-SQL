use PE_Demo_S2019; 
GO
select
od.OrderID,
o.OrderDate,
SUM(od.Quantity * od.SalePrice * (1-od.Discount)) AS TotalAmount
from OrderDetails as od
Join Orders as o
on od.OrderID = o.ID
group by
od.OrderID,
o.OrderDate
having
SUM(od.Quantity * od.SalePrice * (1 - od.Discount)) >8000
Order by
TotalAmount DESC;
go