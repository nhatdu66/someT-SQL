use PE_Demo_S2019; 
GO
declare @SportsCatID INT;
insert into Category (CategoryName)
values ('Sports');
set @SportsCatID = SCOPE_IDENTITY();
Insert into SubCategory (SubCategoryName, CategoryID)
Values
('Tennis', @SportsCatID),
('Football', @SportsCatID);
go