use AdventureWorks2017
--------------------------------###TRIGGERS###-----------------------------------
----------------------------AfterUpdate-----------------------
if OBJECT_ID('trAfterUpdateCustomer','TR') is not null
begin
	drop trigger trAfterUpdateCustomer
end;

GO

create trigger trAfterUpdateCustomer
on Sales.Customer
AFTER UPDATE as declare
	@ID int,
	@personID int,
	@storeID int,
	@territoryID int,
	@accountNumber varchar(25),
	@Mensaje varchar(255);

	select @ID = ins.CustomerID from DeLETED ins;
	select @personID = ins.PersonID from DeLETED ins;
	select @storeID = ins.StoreID from DeLETED ins;
	select @territoryID = ins.TerritoryID from DeLETED ins;
	select @accountNumber = ins.AccountNumber from DeLETED ins;

	set @Mensaje = 'Se realiz� un UPDATE con los valores de id = '+cast(@ID as varchar)
begin
	drop trigger trInsteadOfDelProduct
end;
GO

create trigger trInsteadOfDelProduct
on Production.Product
INSTEAD OF DELETE  as declare
	@ID int,
	@name varchar(25),
	@productNumber varchar(25),
	@Mensaje varchar(255);
		select @name = ins.Name from DELETED ins;
		select @productNumber = ins.ProductNumber from DELETED ins;