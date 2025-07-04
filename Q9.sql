use PE_Demo_S2019; 
GO
Create Trigger InsertSubCategory
on SubCategory
After INSERT
as
begin
set nocount on;
select
i.SubCategoryName,
c.CategoryName
from inserted as i
inner join Category as c
on i.CategoryID = c.ID;
end;
go