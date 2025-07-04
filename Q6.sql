use PE_Demo_S2019; 
GO
select
p.ID,
p.ProductName,
o.NumberOFOrders
from(
select
ProductID,
count(distinct OrderID) as NumberOFOrders
from OrderDetails
group by productID

) as o
Join Product as p
on p.ID = o.ProductID
where o.NumberOFOrders = (
select MIN(NumberOfOrders)
from(
select COUNT(distinct OrderID) as NumberOfOrders
from OrderDetails
group by ProductID
) as t
)
Order by p.ID;
go