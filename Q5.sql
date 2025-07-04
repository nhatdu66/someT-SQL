use PE_Demo_S2019; 
GO
select
od.ProductID,
p.ProductName,
od.Quantity
from OrderDetails as od
Join Product as p
on od.ProductID = p.ID
where od.Quantity =(
select MAX(Quantity)
from OrderDetails
);
go