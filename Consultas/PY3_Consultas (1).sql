use AdventureWorks2017

--------------------------------------------------------PERSON-----------------------------------------------------------------------------------------------

GO
CREATE PROCEDURE ConsultaPerson
@Filter nvarchar(50)
AS    
   SET NOCOUNT ON;
   select Person.BusinessEntityID, 
   (select AdventureWorks2017.dbo.NamePerson (Person.BusinessEntityID)) as Fullname,
	EmailAddress.EmailAddress,
	(CountryRegion.Name) as Country,
	(StateProvince.Name)as Province,
	Address.City,
	Address.AddressLine1,
	(AddressType.Name) as AddressType
from AdventureWorks2017.Person.Person
inner join AdventureWorks2017.Person.EmailAddress on Person.BusinessEntityID = EmailAddress.BusinessEntityID
inner join AdventureWorks2017.Person.BusinessEntityAddress on Person.BusinessEntityID = BusinessEntityAddress.BusinessEntityID
inner join AdventureWorks2017.Person.Address on BusinessEntityAddress.AddressID = Address.AddressID
inner join AdventureWorks2017.Person.AddressType on BusinessEntityAddress.AddressTypeID = AddressType.AddressTypeID
inner join AdventureWorks2017.Person.StateProvince on Address.StateProvinceID = StateProvince.StateProvinceID
inner join AdventureWorks2017.Person.CountryRegion on StateProvince.CountryRegionCode = CountryRegion.CountryRegionCode
group by Person.BusinessEntityID,Person.BusinessEntityID,
	EmailAddress.EmailAddress,
	CountryRegion.Name,
	StateProvince.Name,
	Address.City,
	Address.AddressLine1,
	AddressType.Name
having (select AdventureWorks2017.dbo.NamePerson (Person.BusinessEntityID)) like UPPER ('%'+@Filter+'%');
RETURN  
GO

exec ConsultaPerson N' '
--------------------------------------------------------SALES------------------------------------------------------------------------------------------------

GO
CREATE PROCEDURE ConsultaSales
@Filter nvarchar(50)
AS    
   SET NOCOUNT ON;
   SELECT ('SO' + CONVERT(varchar(10),SalesOrderHeader.SalesOrderID)) as SalesOrderNumber
      ,CONVERT(varchar,OrderDate,110) as OrderDate
      ,CONVERT(varchar,DueDate,110) as DueDate
      ,CONVERT(varchar,ShipDate,110) as ShipDate
      ,Status
      ,SalesOrderHeader.AccountNumber
      ,(iif(Person.FirstName is null,'',Person.FirstName )+' '+ iif(Person.MiddleName is null,'',Person.MiddleName ) + ' ' + iif(Person.LastName is null,'',Person.LastName)) as CustomerName
      ,(AdventureWorks2017.dbo.NamePerson (SalesOrderHeader.SalesPersonID))as SalesPersonName
      ,(CountryRegion.Name + ', ' + StateProvince.Name + ', ' + AddressLine1) as ShipToAddress,(ShipMethod.Name) as ShipMethod,SubTotal
      ,Freight,TotalDue,CONVERT(varchar,SalesOrderHeader.ModifiedDate,110) as ModifiedDate 
FROM AdventureWorks2017.Sales.SalesOrderHeader
inner join AdventureWorks2017.Sales.Customer on SalesOrderHeader.CustomerID = Customer.CustomerID
inner join AdventureWorks2017.Person.Person on Customer.PersonID = Person.BusinessEntityID
inner join AdventureWorks2017.Purchasing.ShipMethod on ShipMethod.ShipMethodID = SalesOrderHeader.ShipMethodID
inner join AdventureWorks2017.Person.Address on Address.AddressId = SalesOrderHeader.ShipToAddressID
inner join AdventureWorks2017.Person.StateProvince on Address.StateProvinceID = StateProvince.StateProvinceID
inner join AdventureWorks2017.Person.CountryRegion on StateProvince.CountryRegionCode = CountryRegion.CountryRegionCode
where SalesOrderNumber like UPPER('%' + @Filter + '%')
RETURN  
GO


--------------------------------------------------------SALESPERSON------------------------------------------------------------------------------------------

create function VentasTotales (@IDVendedor int)
returns int
as 
begin 
declare @TotalVentas int
select @TotalVentas = (select count(SalesPersonID) from  AdventureWorks2017.Sales.SalesOrderHeader where SalesOrderHeader.SalesPersonID = CAST(@IDVendedor as nvarchar(20)))
return @TotalVentas
end;


GO
CREATE PROCEDURE ConsultaSale
@Name nvarchar(50)
AS    
   SET NOCOUNT ON;
   select DISTINCT SalesPerson.BusinessEntityID,
	(select AdventureWorks2017.dbo.NamePerson (SalesPerson.BusinessEntityID)) as SalesPersonName,
	JobTitle,
	HireDate,
	EmailAddress.EmailAddress,
	PhoneNumber,
	(PhoneNumberType.Name) as PhoneNumberType,
	SickLeaveHours,
	(dbo.VentasTotales(SalesPerson.BusinessEntityID)) as TotalSales
from AdventureWorks2017.Sales.SalesPerson
inner join AdventureWorks2017.Person.Person on SalesPerson.BusinessEntityID = Person.BusinessEntityID
inner join AdventureWorks2017.HumanResources.Employee on SalesPerson.BusinessEntityID = HumanResources.Employee.BusinessEntityID
inner join AdventureWorks2017.Person.EmailAddress on SalesPerson.BusinessEntityID = EmailAddress.BusinessEntityID
inner join AdventureWorks2017.Person.PersonPhone on SalesPerson.BusinessEntityID = PersonPhone.BusinessEntityID
inner join AdventureWorks2017.Person.PhoneNumberType on PersonPhone.PhoneNumberTypeID = PhoneNumberType.PhoneNumberTypeID
group by SalesPerson.BusinessEntityID,Person.BusinessEntityID,
	JobTitle,
	HireDate,
	EmailAddress.EmailAddress,
	PhoneNumber,
	PhoneNumberType.Name,
	SickLeaveHours
having (select AdventureWorks2017.dbo.NamePerson (SalesPerson.BusinessEntityID)) like UPPER ('%'+@Name+'%');
   
RETURN  
GO


--------------------------------------------------------PRODUCT------------------------------------------------------------------------------------------

create function MayorMenorPrecioXProducto(@IDProducto int,@Flag binary)
returns money
as 
begin 
declare @Value money 
if (@Flag = 1)
begin
select @Value = (select  DISTINCT TOP 1 AdventureWorks2017.Sales.SalesOrderDetail.UnitPrice from AdventureWorks2017.Production.Product
inner join AdventureWorks2017.Sales.SalesOrderDetail
on AdventureWorks2017.Production.Product.ProductID = AdventureWorks2017.Sales.SalesOrderDetail.ProductID
where SalesOrderDetail.ProductID = CAST(@IDProducto as nvarchar(20))
	order by AdventureWorks2017.Sales.SalesOrderDetail.UnitPrice desc)
end
if (@Flag = 0)
begin
select @Value = (select  DISTINCT TOP 1 AdventureWorks2017.Sales.SalesOrderDetail.UnitPrice from AdventureWorks2017.Production.Product
inner join AdventureWorks2017.Sales.SalesOrderDetail
on AdventureWorks2017.Production.Product.ProductID = AdventureWorks2017.Sales.SalesOrderDetail.ProductID
where SalesOrderDetail.ProductID = CAST(@IDProducto as nvarchar(20))
	order by AdventureWorks2017.Sales.SalesOrderDetail.UnitPrice asc)
end
return @Value
end;  


GO
CREATE PROCEDURE ConsultaProduct
@Filter nvarchar(50)
AS    
	SET NOCOUNT ON;
	select Product.ProductID
		,Product.Name
		,ProductNumber
		,Color
		,SafetyStockLevel
		,StandardCost
		,(SELECT dbo.MayorMenorPrecioXProducto (Product.ProductID,1)) as MaxUnitPrice
		,(SELECT dbo.MayorMenorPrecioXProducto (Product.ProductID,0)) as MinUnitPrice
		,DaysToManufacture
		,(ProductSubcategory.Name) as SubCategory
		,(ProductCategory.Name) as Category
		,(ProductModel.Name) as ProductModel
		,sum([Quantity]) as Quantity
		,SellStartDate
	from AdventureWorks2017.Production.Product
	inner join AdventureWorks2017.Production.ProductSubcategory on ProductSubcategory.ProductSubcategoryID = Product.ProductSubcategoryID
	inner join AdventureWorks2017.Production.ProductCategory on ProductCategory.ProductCategoryID = ProductSubcategory.ProductCategoryID
	inner join AdventureWorks2017.Production.ProductModel on ProductModel.ProductModelID = Product.ProductModelID
	inner join AdventureWorks2017.Production.ProductInventory on ProductInventory.ProductID = Product.ProductID
	where SellEndDate is Null and Product.Name like UPPER ('%'+ @Filter +'%')
	group by Product.ProductID
		,Product.Name
		,ProductNumber
		,Color
		,SafetyStockLevel
		,StandardCost
		,DaysToManufacture
		,ProductSubcategory.Name
		,ProductCategory.Name
		,ProductModel.Name
		,SellStartDate
	order by Product.ProductID, Product.Name
RETURN  
GO


--------------------------------------------------------PROVEEDORES------------------------------------------------------------------------------------------

create function ProductosXProveedor (@IDVendor int)
returns table
as 
return (
select ProductID from AdventureWorks2017.Purchasing.Vendor
inner join AdventureWorks2017.Purchasing.ProductVendor on ProductVendor.BusinessEntityID = Vendor.BusinessEntityID
where Vendor.BusinessEntityID = @IDVendor
);

GO
CREATE PROCEDURE ConsultaProveedores
@Filter nvarchar(50)
AS    
	SET NOCOUNT ON;
	SELECT Vendor.BusinessEntityID
		,AccountNumber
		,Vendor.Name
		,AverageLeadTime
		,Product.Name as ProductName
		,ProductSubcategory.Name as SubCategoryName
		,ProductCategory.Name as CategoryName
		,StandardPrice
		,LastReceiptCost
		,MinOrderQty
		,MaxOrderQty
		,SellStartDate
		,(select count(*) from AdventureWorks2017.dbo.ProductosXProveedor(Vendor.BusinessEntityID)) as TotalProducts
	FROM AdventureWorks2017.Purchasing.Vendor
	inner join AdventureWorks2017.Purchasing.ProductVendor on ProductVendor.BusinessEntityID = Vendor.BusinessEntityID
	inner join AdventureWorks2017.Production.Product on Product.ProductID = ProductVendor.ProductID
	inner join AdventureWorks2017.Production.ProductSubcategory on ProductSubcategory.ProductSubcategoryID = Product.ProductSubcategoryID  
	inner join AdventureWorks2017.Production.ProductCategory on ProductCategory.ProductCategoryID = ProductSubcategory.ProductCategoryID
	where Vendor.Name like UPPER('%' + @Filter + '%') or ProductCategory.Name like UPPER('%' + @Filter + '%')
	group by Vendor.BusinessEntityID
		,AccountNumber
		,Vendor.Name
		,AverageLeadTime
		,Product.Name
		,ProductSubcategory.Name
		,ProductCategory.Name
		,StandardPrice
		,LastReceiptCost
		,MinOrderQty
		,MaxOrderQty
		,SellStartDate
	order by TotalProducts,Vendor.Name
RETURN  
GO

execute ConsultaProveedores N''