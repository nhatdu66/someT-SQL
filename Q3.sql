use PE_Demo_S2019; 
GO
select distinct
c.ID AS ID,
c.CustomerName,
c.Segment,
c.Country,
c.City,
c.State,
c.PostalCode,
c.Region
from Customer AS c
INNER Join Orders as o
on c.ID = o.CustomerID
where c.CustomerName like 'B%'
and o.OrderDate >= '2017-12-01'
and o.OrderDate < '2018-01-01'
order by
c.Segment DESC,
c.CustomerName ASC;
GO