--*************************************************************************--
-- Title: Assignment06
-- Author: CTarnoff
-- Desc: This file demonstrates how to use Views
-- Change Log: 2/20/21, CTarnoff, Added code for Questions 1-5 (SCHEMABINDING, Permissions, etc.)
-- Change Log: 2/21/21, CTarnoff, Added code for Questions 6-10 
-- 2/20/21, CTarnoff, Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_CTarnoff')
	 Begin 
	  Alter Database [Assignment06DB_CTarnoff] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_CTarnoff;
	 End
	Create Database Assignment06DB_CTarnoff;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_CTarnoff;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/
--'NOTES------------------------------------------------------------------------------------ 
-- 1) You can use any name you like for you views, but be descriptive and consistent
-- 2) You can use your working code from assignment 5 for much of this assignment
-- 3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5 pts): How can you create BASIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!
Create View vCategories
WITH SCHEMABINDING AS
	SELECT CategoryID, CategoryName FROM dbo.Categories;
GO
Create View vProducts
WITH SCHEMABINDING AS 
	SELECT ProductID, ProductName, CategoryID, UnitPrice FROM dbo.Products;
GO
Create View vEmployees
WITH SCHEMABINDING AS
	SELECT EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID FROM dbo.Employees;
GO
Create View vInventories
WITH SCHEMABINDING AS
	SELECT InventoryID, InventoryDate, EmployeeID, ProductID, Count as [Count] FROM dbo.Inventories;
GO

-- Question 2 (5 pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?
DENY SELECT ON Categories to Public;
GRANT SELECT ON vCategories to Public;

DENY SELECT ON Products to Public;
GRANT SELECT ON vProducts to Public;

DENY SELECT ON Employees to Public;
GRANT SELECT ON vEmployees to Public;

DENY SELECT ON Inventories to Public;
GRANT SELECT ON vInventories to Public;

-- Question 3 (10 pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!
CREATE View vCatProdPrice AS 
Select TOP 10000000 
	CategoryName, 
	ProductName,
	UnitPrice
From Categories as c 
	Join Products as p
		On c.CategoryID = p.CategoryID
ORDER BY CategoryName, ProductName;
GO

-- Question 4 (10 pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!
CREATE VIEW vPrdNameInvCountbyInvDate AS 
SELECT TOP 10000000
	ProductName,
	InventoryDate,
	Count AS [Count]
FROM Products AS p 
	Join Inventories AS i
		ON p.ProductID = i.ProductID
ORDER BY ProductName, InventoryDate, [Count];
GO

-- Question 5 (10 pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!
CREATE VIEW vInvDateEmpCount AS
SELECT DISTINCT TOP 1000000
	InventoryDate,
	[EmployeeName] = e.EmployeeFirstName + ' ' + e.EmployeeLastName
FROM Inventories as i 
	JOIN Employees as e
		ON i.EmployeeID = e.EmployeeID
ORDER BY InventoryDate;
GO

-- Question 6 (10 pts): How can you create a view that shows a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!
CREATE VIEW vCatProdInvDateCount AS
SELECT TOP 100000
	CategoryName,
	ProductName,
	InventoryDate,
	Count AS [Count]
FROM Categories as c 
	JOIN Products as p
		ON c.CategoryID = p.CategoryID
	JOIN Inventories as i
		ON p.ProductID = i.ProductID
ORDER BY CategoryName, ProductName, InventoryDate, [Count];
GO

-- Question 7 (10 pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!
CREATE VIEW vCatProdInvDateCountEmp AS
SELECT TOP 1000000
	CategoryName,
	ProductName,
	InventoryDate,
	[Count] = Count,
	[EmployeeName] = EmployeeFirstName + ' ' + EmployeeLastName
FROM Categories as c
	JOIN Products as p
		ON c.CategoryID = p.CategoryID
	JOIN Inventories as i
		ON p.ProductID = i.ProductID
	JOIN Employees as e
		ON i.EmployeeID = e.EmployeeID
ORDER BY InventoryDate, CategoryName, ProductName, [EmployeeName];
GO

-- Question 8 (10 pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 
CREATE VIEW vCatProdInvDateCountEmpChaiChang AS
SELECT TOP 1000000
	c.CategoryName,
	p.ProductName,
	i.InventoryDate,
	i.Count,
	e.EmployeeFirstName + ' ' + e.EmployeeLastName as EmployeeName
FROM Employees as e 
	JOIN Inventories AS i
		ON e.EmployeeID = i.EmployeeID
	JOIN Products as p
		ON i.ProductID = p.ProductID
	JOIN Categories as c
		ON p.CategoryID = c.CategoryID
			WHERE i.ProductID in 
				(SELECT ProductID FROM Products WHERE ProductName In ('Chai', 'Chang'))
ORDER BY i.InventoryDate, CategoryName, ProductName;
GO

-- Question 9 (10 pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!
CREATE VIEW vEmpMgrs AS
SELECT TOP 1000000
	[Manager] = Mgr.EmployeeFirstName + ' ' + Mgr.EmployeeLastName,
	[Employee] = Emp.EmployeeFirstName + ' ' + Emp.EmployeeLastName
FROM Employees as Emp Inner Join Employees as Mgr
	ON Emp.ManagerID = Mgr.EmployeeID
ORDER BY [Manager], [Employee];
GO

-- Question 10 (10 pts): How can you create one view to show all the data from all four 
-- BASIC Views?
CREATE VIEW vCatProdInvEmp AS
SELECT 
	c.CategoryID,
	CategoryName,
	p.ProductID,
	p.ProductName,
	UnitPrice,
	InventoryID,
	InventoryDate,
	Count,
	e.EmployeeID,
	[Employee] = e.EmployeeFirstName + ' ' + e.EmployeeLastName,
	[Manager] = e.EmployeeFirstName + ' ' + e.EmployeeLastName
FROM vCategories as c
	JOIN vProducts as p
		ON p.CategoryID = c.CategoryID
	JOIN vInventories as i
		ON i.ProductID = p.ProductID
	JOIN vEmployees as e
		ON e.EmployeeID = i.EmployeeID	-- Can't quiet figure out how to include the self-join logic 
GO                                      -- from Question 9 into this query in order to get the correct Employee and Manager names.

-- Here is an example of some rows selected from the view:
-- CategoryID,CategoryName,ProductID,ProductName,UnitPrice,InventoryID,InventoryDate,Count,EmployeeID,Employee,Manager
-- 1,Beverages,1,Chai,18.00,1,2017-01-01,72,5,Steven Buchanan,Andrew Fuller
-- 1,Beverages,1,Chai,18.00,78,2017-02-01,52,7,Robert King,Steven Buchanan
-- 1,Beverages,1,Chai,18.00,155,2017-03-01,54,9,Anne Dodsworth,Steven Buchanan

-- Test your Views (NOTE: You must change the names to match yours as needed!)
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vCatProdPrice]
Select * From [dbo].[vPrdNameInvCountbyInvDate]
Select * From [dbo].[vInvDateEmpCount]
Select * From [dbo].[vCatProdInvDateCount]
Select * From [dbo].[vCatProdInvDateCountEmp]
Select * From [dbo].[vCatProdInvDateCountEmpChaiChang]
Select * From [dbo].[vEmpMgrs]
Select * From [dbo].[vCatProdInvEmp]
/***************************************************************************************/