use PE_Demo_S2019; 
GO
SELECT * FROM (select top 5
p.ID,
p.ProductName,
p.UnitPrice,
p.SubCategoryID
from Product as p
order by
p.UnitPrice DESC) AS HighPrices

UNION ALL

select * from (select top 5
p.ID,
p.ProductName,
p.UnitPrice,
p.SubCategoryID
from Product as p
order by
p.UnitPrice ASC) as LowPrices
order by UnitPrice DESC;
go
