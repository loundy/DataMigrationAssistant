#This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
#THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
#INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#We grant you a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute
#the object code form of the Sample Code, provided that you agree:
#(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
#(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
#(iii) to indemnify, hold harmless, and defend Us and our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code. 
# ----------------------------------------------------------------------------- 
#
# Script: DMA_Processor.ps1 
# Author: Chris Lound - Senior Premier Field Engineer - Data Platform.
# Date: 19/03/2017 
# Version:  5.0
# Synopsis: Create data warehouse for reporting on DMA data
# Keywords: 
# Notes:  Script is called by dmaProcessor function if createwarehouse is 1
# Comments: 
# 5.0   Script seperated from DMA_Processor v5 -19/03/20179
#       Changed views to use Date instead of DateKey
#       Updated DatabaseReadiness Views to be platform specific (Azure/OnPrem)
#       Added HistoryLog schema and objects

#------------------------------------------------------------------------------------ CREATE FUNCTIONS -------------------------------------------------------------------------------------

function createWarehouse 
{
param(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $serverName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $warehouseName 
)

    $srv = New-Object Microsoft.SqlServer.Management.SMO.Server($serverName)
    
    $connectionString = "Server=$serverName;Database=$warehouseName;Trusted_Connection=True;"

    #create reporting database
    $dbwCheck = $srv.Databases | Where {$_.Name -eq "$warehouseName"} | Select Name
    if(!$dbwCheck)
    {            
        $dbw = New-Object Microsoft.SqlServer.Management.Smo.Database ($srv, $warehouseName)

        try
        {
            $dbw.Create()
            Write-Host("Database $warehouseName created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create database $warehouseName") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        $dbw=$srv.Databases.Item($warehouseName)
        Write-Host ("Database $warehouseName already exists") -ForegroundColor Yellow
    }
    
    # Create reporting schema
    $schemaCheck = $dbw.Schemas | where {$_.Name -eq "reporting"}
    if(!$schemaCheck)
    {
        $sch  = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Schema -argumentlist $dbw, "reporting"  
        $sch.Owner = "dbo"   
        
        try
        {
            $sch.Create() 
            Write-Host ("Schema reporting created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create schema reporting") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("Schema reporting already exists") -ForegroundColor Yellow
    }

    # create historylog schema
    $schemaCheck = $dbw.Schemas | where {$_.Name -eq "historyLog"}
    if(!$schemaCheck)
    {
        $sch  = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Schema -argumentlist $dbw, "historyLog"  
        $sch.Owner = "dbo"   
        
        try
        {
            $sch.Create() 
            Write-Host ("Schema historyLog created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create schema historyLog") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("Schema historyLog already exists") -ForegroundColor Yellow
    }

    #create dimCategory
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimCategory"}
    if(!$tableCheck)
    {            
        $dimCategorytbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimCategory")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimCategorytbl, "CategoryKey", [Microsoft.SqlServer.Management.Smo.DataType]::Smallint)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimCategorytbl, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
              
        $dimCategorytbl.Columns.Add($col1)
        $dimCategorytbl.Columns.Add($col2)
        
        try
        {
            $dimCategorytbl.Create()
            Write-Host ("Table dimCategory created successfully") -ForegroundColor Green
        }
        catch
        {
            Write-Host("Failed to create table dimCategory") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimCategorytbl,"PK_dimCategory_Categorykey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimCategory_CategoryKey created successfully") -ForegroundColor Green

            $CommandText = @'
insert into dimCategory (Category) VALUES ('NA')
insert into dimCategory (Category) VALUES ('Storage')
insert into dimCategory (Category) VALUES ('Security')
insert into dimCategory (Category) VALUES ('Compatibility')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("failed to create primary key PK_dimCategory_CategoryKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimCategory already exists") -ForegroundColor Yellow
    }


    #create dimChangeCategory
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimChangeCategory"}
    if(!$tableCheck)
    {            
        $dimChangeCategorytbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimChangeCategory")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimChangeCategorytbl, "ChangeCategoryKey", [Microsoft.SqlServer.Management.Smo.DataType]::Smallint)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimChangeCategorytbl, "ChangeCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        
        $dimChangeCategorytbl.Columns.Add($col1)
        $dimChangeCategorytbl.Columns.Add($col2)
        
        try
        {        
            $dimChangeCategorytbl.Create()
            Write-Host ("Table dimChangeCategory created successfully") -ForegroundColor Green

        }
        catch
        {
            write-host("Failed to create table dimChangeCategory") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimChangeCategorytbl,"PK_dimChangeCategory_ChangeCategoryKey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimChangeCategory_ChangeCategoryKey created successfully") -ForegroundColor Green

            $CommandText = @'
insert into dimChangeCategory (ChangeCategory) VALUES ('NA')
insert into dimChangeCategory (ChangeCategory) VALUES ('BehaviorChange')
insert into dimChangeCategory (ChangeCategory) VALUES ('NotDefined')
insert into dimChangeCategory (ChangeCategory) VALUES ('MigrationBlocker')
insert into dimChangeCategory (ChangeCategory) VALUES ('Deprecated')
insert into dimChangeCategory (ChangeCategory) VALUES ('BreakingChange')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimChangeCategory_ChangeCategoryKey") -ForegroundColor Red
            $error[0]|format-list -force
        }                
    }
    else
    {
        Write-Host ("Table dimChangeCategory already exists") -ForegroundColor Yellow
    }


    #create dimDate
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimDate"}
    if(!$tableCheck)
    {            
        $dimDatetbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimDate")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "DateKey", [Microsoft.SqlServer.Management.Smo.DataType]::Int)
        $col1.Nullable = $false
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "Date", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "Day", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "DaySuffix", [Microsoft.SqlServer.Management.Smo.DataType]::Char(2))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "Weekday", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "WeekDayName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(10))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "IsWeekend", [Microsoft.SqlServer.Management.Smo.DataType]::Bit)
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "IsHoliday", [Microsoft.SqlServer.Management.Smo.DataType]::Bit)
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl,  "Holidaytext", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(64))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "DOWInMonth", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "DayOfYear", [Microsoft.SqlServer.Management.Smo.DataType]::Smallint)
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "WeekOfMonth", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "WeekOfYear", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "ISOWeekOfYear", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "Month", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col16 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "MonthName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(10))
        $col17 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "Quarter", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col18 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "QuarterName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(6))
        $col19 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "Year", [Microsoft.SqlServer.Management.Smo.DataType]::Int)
        $col20 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "MMYYYY", [Microsoft.SqlServer.Management.Smo.DataType]::Char(6))
        $col21 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "MonthYear", [Microsoft.SqlServer.Management.Smo.DataType]::Char(7))
        $col22 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "FirstDayOfMonth", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col23 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "LastDayofMonth", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col24 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "FirstDayOfQuarter", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col25 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "LastDayOfQuarter", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col26 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "FirstDayOfYear", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col27 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "LastDayOfYear", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col28 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "FirstDayOfNextMonth", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        $col29 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDatetbl, "FirstDayOfNextYear", [Microsoft.SqlServer.Management.Smo.DataType]::Date)
        
        $dimDatetbl.Columns.Add($col1)
        $dimDatetbl.Columns.Add($col2)
        $dimDatetbl.Columns.Add($col3)
        $dimDatetbl.Columns.Add($col4)
        $dimDatetbl.Columns.Add($col5)
        $dimDatetbl.Columns.Add($col6)
        $dimDatetbl.Columns.Add($col7)
        $dimDatetbl.Columns.Add($col8)
        $dimDatetbl.Columns.Add($col9)
        $dimDatetbl.Columns.Add($col10)
        $dimDatetbl.Columns.Add($col11)
        $dimDatetbl.Columns.Add($col12)
        $dimDatetbl.Columns.Add($col13)
        $dimDatetbl.Columns.Add($col14)
        $dimDatetbl.Columns.Add($col15)
        $dimDatetbl.Columns.Add($col16)
        $dimDatetbl.Columns.Add($col17)
        $dimDatetbl.Columns.Add($col18)
        $dimDatetbl.Columns.Add($col19)
        $dimDatetbl.Columns.Add($col20)
        $dimDatetbl.Columns.Add($col21)
        $dimDatetbl.Columns.Add($col22)
        $dimDatetbl.Columns.Add($col23)
        $dimDatetbl.Columns.Add($col24)
        $dimDatetbl.Columns.Add($col25)
        $dimDatetbl.Columns.Add($col26)
        $dimDatetbl.Columns.Add($col27)
        $dimDatetbl.Columns.Add($col28)
        $dimDatetbl.Columns.Add($col29)
                
        try
        {
            $dimDatetbl.Create()
            Write-Host ("Table dimDate created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table dimDate") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimDatetbl,"PK_dimDate_Datekey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimDate_DateKey created successfully") -ForegroundColor green

            $CommandText = @'
DECLARE @StartDate DATE = '20170101', @NumberOfYears INT = 15;

DECLARE @CutoffDate DATE = DATEADD(YEAR, @NumberOfYears, @StartDate);

-- this is just a holding table for intermediate calculations:
CREATE TABLE #dim
(
  [date]       DATE PRIMARY KEY, 
  [day]        AS DATEPART(DAY,      [date]),
  [month]      AS DATEPART(MONTH,    [date]),
  FirstOfMonth AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
  [MonthName]  AS DATENAME(MONTH,    [date]),
  [week]       AS DATEPART(WEEK,     [date]),
  [ISOweek]    AS DATEPART(ISO_WEEK, [date]),
  [DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
  [quarter]    AS DATEPART(QUARTER,  [date]),
  [year]       AS DATEPART(YEAR,     [date]),
  FirstOfYear  AS CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
  Style112     AS CONVERT(CHAR(8),   [date], 112),
  Style101     AS CONVERT(CHAR(10),  [date], 101)
);

INSERT #dim([date]) 
SELECT d
FROM
(
  SELECT d = DATEADD(DAY, rn - 1, @StartDate)
  FROM 
  (
    SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
      rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
    FROM sys.all_objects AS s1
    CROSS JOIN sys.all_objects AS s2
    ORDER BY s1.[object_id]
  ) AS x
) AS y;


insert into dimdate
SELECT
  DateKey       = CONVERT(INT, Style112),
  [Date]        = [date],
  [Day]         = CONVERT(TINYINT, [day]),
  DaySuffix     = CONVERT(CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE 
                  CASE RIGHT([day], 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
	              WHEN '3' THEN 'rd' ELSE 'th' END END),
  [Weekday]     = CONVERT(TINYINT, [DayOfWeek]),
  [WeekDayName] = CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date])),
  [IsWeekend]   = CONVERT(BIT, CASE WHEN [DayOfWeek] IN (1,7) THEN 1 ELSE 0 END),
  [IsHoliday]   = CONVERT(BIT, 0),
  HolidayText   = CONVERT(VARCHAR(64), NULL),
  [DOWInMonth]  = CONVERT(TINYINT, ROW_NUMBER() OVER 
                  (PARTITION BY FirstOfMonth, [DayOfWeek] ORDER BY [date])),
  [DayOfYear]   = CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date])),
  WeekOfMonth   = CONVERT(TINYINT, DENSE_RANK() OVER 
                  (PARTITION BY [year], [month] ORDER BY [week])),
  WeekOfYear    = CONVERT(TINYINT, [week]),
  ISOWeekOfYear = CONVERT(TINYINT, ISOWeek),
  [Month]       = CONVERT(TINYINT, [month]),
  [MonthName]   = CONVERT(VARCHAR(10), [MonthName]),
  [Quarter]     = CONVERT(TINYINT, [quarter]),
  QuarterName   = CONVERT(VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' 
                  WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END), 
  [Year]        = [year],
  MMYYYY        = CONVERT(CHAR(6), LEFT(Style101, 2)    + LEFT(Style112, 4)),
  MonthYear     = CONVERT(CHAR(7), LEFT([MonthName], 3) + LEFT(Style112, 4)),
  FirstDayOfMonth     = FirstOfMonth,
  LastDayOfMonth      = MAX([date]) OVER (PARTITION BY [year], [month]),
  FirstDayOfQuarter   = MIN([date]) OVER (PARTITION BY [year], [quarter]),
  LastDayOfQuarter    = MAX([date]) OVER (PARTITION BY [year], [quarter]),
  FirstDayOfYear      = FirstOfYear,
  LastDayOfYear       = MAX([date]) OVER (PARTITION BY [year]),
  FirstDayOfNextMonth = DATEADD(MONTH, 1, FirstOfMonth),
  FirstDayOfNextYear  = DATEADD(YEAR,  1, FirstOfYear)
FROM #dim
OPTION (MAXDOP 1)
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimDate_DateKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimDate already exists") -ForegroundColor Yellow
    }


    #create dimObjectType
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimObjectType"}
    if(!$tableCheck)
    {            
        $dimObjectTypetbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimObjectType")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimObjectTypetbl, "ObjectTypeKey", [Microsoft.SqlServer.Management.Smo.DataType]::Smallint)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimObjectTypetbl, "ObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(40))
             
        $dimObjectTypetbl.Columns.Add($col1)
        $dimObjectTypetbl.Columns.Add($col2)
      
        try
        {          
            $dimObjectTypetbl.Create()
            Write-Host ("Table dimObjectType created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table dimObjectType") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimObjectTypetbl,"PK_dimObjectType_ObjectTypekey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimObjectType_ObjectTypeKey created successfully") -ForegroundColor Green

            $CommandText = @'
insert into dimObjectType (ObjectType) VALUES ('NA')
insert into dimObjectType (ObjectType) VALUES ('View')
insert into dimObjectType (ObjectType) VALUES ('Signature')
insert into dimObjectType (ObjectType) VALUES ('Database Options')
insert into dimObjectType (ObjectType) VALUES ('FullTextIndex')
insert into dimObjectType (ObjectType) VALUES ('Function')
insert into dimObjectType (ObjectType) VALUES ('Login')
insert into dimObjectType (ObjectType) VALUES ('Trigger')
insert into dimObjectType (ObjectType) VALUES ('Procedure')
insert into dimObjectType (ObjectType) VALUES ('User')
insert into dimObjectType (ObjectType) VALUES ('SqlSignatureEncryptionMechanism')
insert into dimObjectType (ObjectType) VALUES ('Database')
insert into dimObjectType (ObjectType) VALUES ('Symmetric Key')
insert into dimObjectType (ObjectType) VALUES ('Certificate')
insert into dimObjectType (ObjectType) VALUES ('Column')
insert into dimObjectType (ObjectType) VALUES ('Table')
insert into dimObjectType (ObjectType) VALUES ('SqlFile')
insert into dimObjectType (ObjectType) VALUES ('Computed Column')
insert into dimObjectType (ObjectType) VALUES ('FullTextIndex')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimObjectType_ObjectTypeKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimObjectType already exists") -ForegroundColor Yellow
    }


    #create dimRules
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimRules"}
    if(!$tableCheck)
    {            
        $dimRulestbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimRules")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "RulesKey", [Microsoft.SqlServer.Management.Smo.DataType]::Int)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "RuleID", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(36))
        $col2.Nullable = $false
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(500))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "ChangeCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(25))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimRulestbl, "DatabaseCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
       
        $dimRulestbl.Columns.Add($col1)
        $dimRulestbl.Columns.Add($col2)
        $dimRulestbl.Columns.Add($col3)
        $dimRulestbl.Columns.Add($col4)
        $dimRulestbl.Columns.Add($col5)
        $dimRulestbl.Columns.Add($col6)
        $dimRulestbl.Columns.Add($col7)
        $dimRulestbl.Columns.Add($col8)
        $dimRulestbl.Columns.Add($col9)
        
        try
        {        
            $dimRulestbl.Create()
            Write-Host ("Table dimRules created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table dimRules") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimRulestbl,"PK_dimRules_Ruleskey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimRules_RulesKey created successfully") -ForegroundColor Green

            $CommandText = @'
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('NA','NA','NA','NA','NA','NA','NA','NA')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00003','Turn on autogrow for all data and log files after the migration is completed on the target server.','You may experience transaction failures when database data or log files run out of space.','Assessment detected data or log files that are not set to autogrow on your source SQL Server. New and enhanced features require additional disk space for user databases and the tempdb system database. Consider enabling the auto grow setting for all data and log files on your target SQL Server instance after the migration is completed. While you still set autogrow ON, for a managed production system, you must consider autogrow to be merely a contingency for unexpected growth. Do not manage your data and log growth on a day-to-day basis with autogrow.','Verify autogrow is turned on for all data and log files during the upgrade process - https://go.microsoft.com/fwlink/?LinkId=798526','Medium','BehaviorChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00006','BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements are not supported','Assessment detected BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements. These backup/restore options are not supported anymore.','Remove BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements from scripts. Microsoft highly recommends to set your database recovery to FULL recovery mode and perform regular transactional log backups to prevent the log from growing too big. If you do not need point-in-time recovery, switch to SIMPLE recovery mode','BACKUP (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkID=698472 Deprecated Database Engine Features for SQL Server - https://go.microsoft.com/fwlink/?LinkID=698477','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00300','Remove the use of PASSWORD in BACKUP command','Some of the detected BACKUP command options have been deprecated or discontinued such as, BACKUP { DATABASE | LOG } WITH PASSWORD and BACKUP { DATABASE | LOG } WITH MEDIAPASSWORD. BACKUP { DATABASE | LOG } WITH PASSWORD and BACKUP { DATABASE | LOG } WITH MEDIAPASSWORD have been discontinued in SQL Server 2012.','Remove the use of BACKUP { DATABASE | LOG } WITH PASSWORD and BACKUP { DATABASE | LOG } WITH MEDIAPASSWORD commands. Instead use backup encryption for securing your backups. This syntax should not be used for creating future backup scripts.','BACKUP (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkID=698472 Deprecated Database Engine Features for SQL Server - https://go.microsoft.com/fwlink/?LinkID=698477','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00007','BACKUP/RESTORE TRANSACTION statements are deprecated or discontinued','Your BACKUP and RESTORE transaction log operations fail','Remove BACKUP/RESTORE TRANSACTION statements from scripts and use the new supported options, BACKUP/RESTORE LOG.','BACKUP (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkID=698472 Deprecated Database Engine Features for SQL Server - https://go.microsoft.com/fwlink/?LinkID=698477 Restore a Transaction Log Backup (SQL Server) - https://go.microsoft.com/fwlink/?LinkID=825569','Warning','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00301','WITH CHECK OPTION is not supported in views that contain TOP in compatibility mode 90 and above','Assessment detected a view that uses the WITH CHECK OPTION and a TOP clause in the SELECT statement of the view or in a referenced view. Views defined this way incorrectly allow data to be modified through the view and may produce inaccurate results when the database compatibility mode is set to 80 and earlier. Data cannot be inserted or updated through a view that uses WITH CHECK OPTION when the view or a referenced view uses the TOP clause and the database compatibility mode is set to 90 or later.','Modify views that use both WITH CHECK OPTION and TOP if data modification through the view is required.','Not Provided','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00013','COMPUTE clause is not allowed in database compatibility 110','The COMPUTE clause generates totals that appear as additional summary columns at the end of the result set. However, this clause is no longer supported in SQL Server 2012.','The T-SQL module needs to be re-written using the ROLLUP operator instead. The code below demonstrates how COMPUTE can be replaced with ROLLUP. USE AdventureWorks GO SELECT SalesOrderID, UnitPrice, UnitPriceDiscount FROM Sales.SalesOrderDetail ORDER BY SalesOrderID COMPUTE SUM(UnitPrice), SUM(UnitPriceDiscount) BY SalesOrderID GO SELECT SalesOrderID, UnitPrice, UnitPriceDiscount,SUM(UnitPrice) as UnitPrice , SUM(UnitPriceDiscount) as UnitPriceDiscount FROM Sales.SalesOrderDetail<br/>GROUP BY SalesOrderID, UnitPrice, UnitPriceDiscount WITH ROLLUP ','Not Provided','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00302','Discontinued DBCC commands referenced in your T-SQL objects','Many DBCC commands that were available in prior releases have been replaced with DMVs and DMFs, or no longer exist; therefore, using these commands may cause errors and unforeseen effects after upgrading your SQL Server.','Re-write the code, replace DBCC DBREINDEX with ALTER INDEX with REBUILD option. Re-write the code, replace DBCC INDEXDEFRAG with ALTER INDEX with REORGANIZE option. Re-write the code, replace DBCC SHOWCONTIG with sys.dm_db_index_physical_stats. Use of DBCC PINTABLE/DBCC UNPINTABLE is not required and has been removed to prevent additional problems. The syntax for this command still works but does not affect the server. Refer to SQL Server books online for equivalent DMVs and DMFs that you may want to use instead of deprecated and discontinued DBCC commands.','Deprecated Database Engine Features in SQL Server - https://go.microsoft.com/fwlink/?LinkID=698477 Discontinued Database Engine Functionality in SQL Server - https://go.microsoft.com/fwlink/?LinkID=698744','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00021','Verify all filegroups are writeable during the upgrade process','ou may have to set filegroups to the READ_WRITE mode during the migration.','Assessment detected one or more database file groups in read-only mode. Depending on how you upgrade your databases to the new SQL Server platform, you may have to set filegroups to the READ_WRITE mode. Use ALTER DATABASE to set the filegroup to READ_WRITE.','Verify all filegroups are writeable during the upgrade process - https://go.microsoft.com/fwlink/?LinkID=798551','High','BreakingChange','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00020','Read-only databases cannot be upgraded','Assessment detected one or more read-only databases.','Depending on the method you choose to upgrade, you may have to set database READ_WRITE during the upgrade process.','Read-only databases cannot be upgraded - https://go.microsoft.com/fwlink/?LinkId=798552','High','BreakingChange','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00023','SQL Server native SOAP support is discontinued in SQL Server 2014 and above','SQL Server Native XML Web Services has been removed in this SQL Server release.','Modify applications that currently use Native XML Web Services. Microsoft recommends to leverage technologies such as .NET Windows Communication Foundation (WCF) that provide a much more robust way to build Web services. This is especially the case for best practices and features related to scalability and security.  Native XML Web Services: Deprecated in SQL Server 2008 - https://go.microsoft.com/fwlink/?LinkId=798554','SQL Server native SOAP support is discontinued in this version of SQL Server - https://go.microsoft.com/fwlink/?LinkId=798553','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00305','Encryption using RC4 or RC4_128 is not supported','Assessment detected a symmetric key which uses an unsupported encryption algorithm. Repeated use of the same RC4 or RC4_128 KEY_GUID on different blocks of data will result in the same RC4 key because SQL Server does not provide a salt automatically. Using the same RC4 key repeatedly is a well-known error that will result in very weak encryption. Therefore, the RC4 and RC4_128 keywords are not supported in database compatibility Level 110 onwards.','The RC4 algorithm is only supported for backward compatibility. New material can only be encrypted using RC4 or RC4_128 when the database is in compatibility level 90 or 100. (Not recommended.) Use a newer algorithm such as one of the AES algorithms instead. In SQL Server 2012 and higher material encrypted using RC4 or RC4_128 can be decrypted in any compatibility level.','Choose an encryption algorithm - https://go.microsoft.com/fwlink/?LinkID=798555','Error','Deprecated','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00332','FASTFIRSTROW table hint usage','The usage of FASTFIRSTROW as a table hint has been discontinued in SQL 2012.','We recommend that hints be used only as a last resort by experienced developers and database administrators.  If you have to use FASTFIRSTROW hint, you can evaluate the query hint OPTION (FAST 1) instead. FAST number_rows Specifies that the query is optimized for fast retrieval of the first number_rows. This is a nonnegative integer. After the first number_rows are returned, the query continues execution and produces its full result set.','Discontinued Database Engine Functionality in SQL Server 2016 - https://go.microsoft.com/fwlink/?LinkId=798548','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00318','FOR BROWSE is not allowed in views in 90 or later compatibility modes','The FOR BROWSE clause is allowed (and ignored) in views when the database compatibility mode is set to 80. The FOR BROWSE clause is not allowed in views when the database compatibility mode is set to 90 or later.','Before you change the database compatibility mode to 90 or later, remove the FOR BROWSE clause from view definitions.','Not Provided','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00335','FOR XML AUTO queries return derived table references in 90 or later compatibility modes','When the database compatibility level is set to 90 or later, FOR XML queries that execute in AUTO mode return references to derived table aliases. When the compatibility level is set to 80, FOR XML AUTO queries return references to the base tables that define a derived table. For example, the following query, which includes a derived table, produces different results under compatibility levels 80, 90, or later: SELECT *  FROM (SELECT a.id AS a, b.id AS b  FROM Test a JOIN Test b ON a.id=b.id) AS DerivedTest  FOR XML AUTO; Under compatibility level 80, the query returns the following results. The results reference the base table aliases a and b of the derived table instead of the derived table alias. a=1; b b=1; a=2; b=2; Under compatibility level 90 or later, the query returns references to the derived table alias DerivedTest instead of to the derived tables base tables. DerivedTest a=1; b=1; DerivedTest a=;2; b=2;','Modify your application as required to account for the changes in results of FOR XML AUTO queries that include derived tables and that run under compatibility level 90 or later.','Not Provided','Info','BehaviorChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00040','Full-Text Search has changed since SQL Server 2008','Full-Text Search has changed since SQL Server 2008.','Many full-text search options and settings have changed. Therefore, when you upgrade to SQL Server 2014 or SQL Server 2016  Full-Text Search, some of your settings might need modification. We recommend you to test your applications leveraging the Full-Text features.','Breaking Changes to Full-Text Search - https://go.microsoft.com/fwlink/?LinkId=798556','Warning','BehaviorChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00044','Remove user-defined type (UDT)s named after the reserved GEOMETRY and GEOGRAPHY data types.','Microsoft SQL Server introduced new data types GEOMETRY and GEOGRAPHY for storing &quot;Spatial Data&quot;. The terms used for spatial data types should not be used as names for either common language runtime (CLR) or alias UDTs.','Remove UDTs named after the reserved GEOMETRY and GEOGRAPHY data types.','Remove UDTs named after the reserved GEOMETRY and GEOGRAPHY data types - https://go.microsoft.com/fwlink/?LinkID=724415','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00050','Table hints in indexed view definitions are ignored in compatibility mode 80 and are not allowed in compatibility mode 90 or above.','Table hints in indexed view definitions are ignored in compatibility mode 80 and are not allowed in compatibility mode 90 or above.','Table hints must be removed from the definitions of indexed views. Regardless of which compatibility mode is used, we recommend that you test the application. By testing the application, you can make sure it performs as expected when indexed views are created, updated, and accessed, including when indexed views are matched to queries.','Table hints in indexed view definitions are ignored in 80 compatibility mode and are not allowed in 90 mode or later - https://go.microsoft.com/fwlink/?LinkID=733249','Warning','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00319','SERVERPROPERTY(''LCID'') result differs from SQL Server 2000','In SQL Server 2000, when SERVERPROPERTY(LCID) is run on binary collation servers, the function always returns a value of 33280, regardless of the actual collation of the server. In SQL Server 2005 or later versions, SERVERPROPERTY(LCID) returns the Windows locale identifier (LCID) that corresponds to the collation of the server.','Modify applications to expect SERVERPROPERTY(LCID) to return the Windows LCID that corresponds to the collation of the server.','SQL Server 2000 Retired Technical documentation - https://go.microsoft.com/fwlink/?LinkID=798557','Info','BehaviorChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00306','Deprecated data types TEXT, IMAGE or NTEXT','These data types are checked as deprecated. In some cases, using TEXT, IMAGE or NTEXT might harm performance','Deprecated data types are marked to be discontinued on next versions of SQL Server, should use new data types such as: (varchar(max), nvarchar(max), varbinary(max) and etc.)','ntext, text, and image (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkId=798558','Warning','Deprecated','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00337','Upgrade for memory optimized tables requires extra disk space when upgrading from SQL Server 2014 to SQL Server 2016.','The format of the data files for memory-optimized tables changes between SQL Server 2014 and SQL Server 2016. This impacts in-place upgrade, as well as attach/restore of a database from SQL Server 2014 DB to SQL Server 2016. When upgrading or attaching a SQL Server 2014 database that uses in-memory optimized tables, SQL Server will temporary require extra disk space equal to the size of all the durable memory optimized tables in this database.','Ensure there is sufficient space on disk to store the existing database plus additional storage equal to the current size of the containers in the MEMORY_OPTIMIZED_DATA filegroup in the database to perform an in-place upgrade, or when attaching or restoring a SQL Server 2014 database to a SQL Server 2016 instance. Use the following query to determine the disk space currently required for the MEMORY_OPTIMIZED_DATA filegroup, and consequently also the amount of free disk space required for upgrade to succeed: select cast(sum(size) as float)*8/1024/1024 size in GB from sys.database_files where data_space_id in (select data_space_id from sys.filegroups where type=NFX) ','Memory-Optimized Tables - https://go.microsoft.com/fwlink/?LinkID=717919 Creating and Managing Storage for Memory-Optimized Objects - https://go.microsoft.com/fwlink/?LinkID=717927','Warning','BehaviorChange','120')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00058','After upgrade, new reserved keywords cannot be used as identifiers','After upgrade, new reserved keywords listed in the following KB article cannot be used as identifiers. - https://go.microsoft.com/fwlink/?LinkID=825116','Do not use these keywords as identifiers in future development. For the existing schema and applications, refer to the object by using delimited identifiers. For example, the statement, CREATE TABLE [MERGE] ([MERGE] int); uses brackets to delimit the object name MERGE.','After upgrade, new reserved keywords cannot be used as identifiers - https://go.microsoft.com/fwlink/?LinkID=825116','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00062','Tables and Columns named NEXT may lead to an error using compatibility Level 110 and above','Tables or columns named NEXT were detected. Sequences, introduced in Microsoft SQL Server 2012, use the ANSI standard NEXT VALUE FOR function. If a table or a column is named NEXT and the column is aliased as VALUE, and if the ANSI standard AS is omitted, the resulting statement can cause an error.','Rewrite statements to include the ANSI standard AS keyword when aliasing a table or column. For example, when a column is named NEXT and that column is aliased as VALUE, the query SELECT NEXT VALUE FROM TABLE will cause an error and should be rewritten as SELECT NEXT AS VALUE FROM TABLE. Similarly, when a table is named NEXT and that table is aliased as VALUE, the query SELECT Col1 FROM NEXT VALUE will cause an error and should be rewritten as SELECT Col1 FROM NEXT AS VALUE. ','Not Provided','Medium','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00321','Non ANSI style left outer join usage','Non ANSI outer join operations (*= or =*) are not supported and will not work in compatibility levels 90 and above.','Microsoft recommends rewriting the query using ANSI outer join operators (LEFT OUTER JOIN, RIGHT OUTER JOIN). An example how a Non ANSI join can be replaced with ANSI LEFT OUTER JOIN Query with non ANSI style LEFT OUTER JOIN: SELECT A.id as aid, b.id as bid FROM A, B WHERE A.id *= B.id Query with ANSI style LEFT OUTER JOIN: SELECT A.id as aid, b.id as bid FROM A LEFT OUTER JOIN B ON  A.id = B.id ','Using Joins - https://go.microsoft.com/fwlink/?LinkID=825566','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00322','Non ANSI style right outer join usage','Non ANSI outer join operations (*= or =*) are not supported and will not work in compatibility levels 90 and above.','Microsoft recommends rewriting the query using ANSI outer join operators (LEFT OUTER JOIN, RIGHT OUTER JOIN). An example how a Non ANSI join can be replaced with ANSI LEFT OUTER JOIN Query with non ANSI style LEFT OUTER JOIN: SELECT A.id as aid, b.id as bid FROM A, B WHERE A.id *= B.id Query with ANSI style LEFT OUTER JOIN: SELECT A.id as aid, b.id as bid FROM A LEFT OUTER JOIN B ON  A.id = B.id ','Using Joins - https://go.microsoft.com/fwlink/?LinkID=825566','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00336','Certain XPath functions are not allowed in OPENXML queries','In SQL Server 2005 and above, MSXML 3.0 is the underlying engine used to process XPath expressions that are used within OPENXML queries. MSXML 3.0 has a stricter XPath 1.0 engine in which support for the following functions has been removed: format-number() formatNumber() current() element-available() function-available() system-property()','In the case of format-number() and formatNumber(), you can use FORMAT (Transact-SQL) - http://go.microsoft.com/fwlink/?LinkID=825565. For the other unsupported functions listed earlier, there is no direct workaround','OPENXML - https://go.microsoft.com/fwlink/?LinkID=703890','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00325','ORDER BY specifies integer ordinal','This rule checks stored procedures, functions, views and triggers for use of ORDER BY clause specifying ordinal column numbers as sort columns. A sort column can be specified as a nonnegative integer representing the position of the name or alias in the select list, but this is not recommended. An integer cannot be specified when the order_by_expression appears in a ranking function. A sort column can include an expression, but when the database is in SQL 90 compatibility mode or higher, the expression cannot resolve to a constant.','Specify the sort column as a name or column alias rather than hard coding the ordinal.','Bad habits to kick : ORDER BY ordinal - https://go.microsoft.com/fwlink/?LinkId=798560 DISCLAIMER: Third-party link provided as-is and Microsoft does not offer any guarantees or warranties regarding the content on the third party site.','Warning','BehaviorChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00326','Constant expressions are not allowed in the ORDER BY clause in 90 or later compatibility modes','Constant expressions are allowed (and ignored) in the ORDER BY clause when the database compatibility mode is set to 80 or earlier. However, these expressions in the ORDER BY clause will cause the statement to fail when the database compatibility mode is set to 90 or later. Here is an example of such problematic statements: SELECT * FROM Production.Product ORDER BY CASE WHEN  1=2 THEN 3 ELSE 2 END ','Before you change the database compatibility mode to 90 or later, modify statements that use constant expressions in the ORDER BY clause to use a column name or column alias, or a nonnegative integer representing the position of the name or alias in the select list.','Not Provided','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00308','Legacy style RAISERROR calls should be replaced with modern equivalents','RAISERROR calls like the below example are termed as legacy-style because they do not include the commas and the parenthesis. RAISERROR 50001 this is a test This method of calling RAISERROR is deprecated in SQL Server 2008 and removed in SQL Server 2012 regardless of the database compatibility level. ','Rewrite the statement using the current RAISERROR syntax, or evaluate if the modern approach of TRY...CATCH...THROW is feasible if you are using SQL Server 2012 or above.','Deprecated Database Engine Features in SQL Server 2008 - https://go.microsoft.com/fwlink/?LinkId=798561 Please clarify which RAISERROR variation is on the deprecation list - https://go.microsoft.com/fwlink/?LinkId=798562  RAISERROR (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkID=825559 THROW (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkID=825560 ','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00086','XML is a reserved system type name','XML is a reserved system type name. User-Defined types cannot use reserved type names.','In SQL Server 2005 and above, XML is a reserved system type. Use sp_rename to rename the type either before or after you upgrade and modify the application to work with the new type name.','XML (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkID=825567','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00328','SET ROWCOUNT used in the context of DML statements such as INSERT, UPDATE, or DELETE','Using SET ROWCOUNT will not affect DELETE, INSERT, and UPDATE statements in SQL Server 2014 and above. Avoid using SET ROWCOUNT with DELETE, INSERT, and UPDATE statements in new development work, and plan to modify applications that currently use it.','Use the TOP clause instead.','SET ROWCOUNT (Transact-SQL) - https://go.microsoft.com/fwlink/?LinkId=798563','High','BehaviorChange','130')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00110','New column in output of sp_helptrigger may impact applications','New column trigger_schema has been added to the output of sp_helptrigger. This may impact your applications.','Review the use of sp_helptrigger in applications. You may need to modify your applications to accommodate the additional column. Instead, you can use the sys.triggers catalog view.','New column in output of sp_helptrigger may impact applications - https://go.microsoft.com/fwlink/?LinkId=798564','Warning','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00113','SQL Mail has been discontinued','SQL Mail has been discontinued starting from SQL Server 2012. SQL Mail runs in-process to SQL Server service. If SQL Mail goes down, so does the server. Database Mail runs outside SQL Server in a separate process, is scalable, and does not require Extended MAPI client components to be installed on the production server.','Avoid using this feature in new development work, and plan to modify applications that currently use this feature. To send mail, use Database Mail. Use Database Mail instead of SQL Mail - https://go.microsoft.com/fwlink/?LinkId=798566','SQL Mail - https://go.microsoft.com/fwlink/?LinkId=798565','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00311','Detected statements that reference removed system stored procedures that are not available in database compatibility level 100 and higher.','Following unsupported system and extended stored procedures cannot be used in database compatibility level 100 and above: Area: Role management  sp_addgroup sp_changegroup sp_dropgroup sp_helpgroup  Area: Web assistant  sp_makewebtask sp_dropwebtask sp_runwebtask sp_enumcodepages  Area: Remote servers  sp_addremotelogin sp_addserver sp_dropremotelogin sp_helpremotelogin sp_remoteoption  Area: Database management  sp_attach_db sp_attach_single_file_db  Area: Database objects  sp_bindrule sp_bindefault sp_change_users_login sp_depends sp_renamedb sp_getbindtoken  sp_unbindrule sp_unbindefault  Area: Database options  sp_bindsession  sp_resetstatus   Area: Extended stored procedures  xp_grantlogin  xp_revokelogin xp_loginConfig  Area: Extended stored procedures programming  sp_addextendedproc sp_dropextendedproc sp_helpextendedproc  Area: Removable databases  sp_certify_removable sp_create_removable sp_dbremove  Area: Security  sp_addapprole sp_dropapprole sp_addlogin sp_droplogin sp_adduser sp_dropuser sp_grantdbaccess sp_revokedbaccess sp_addrole sp_droprole sp_approlepassword sp_password sp_changeobjectowner sp_defaultdb sp_defaultlanguage sp_denylogin sp_grantlogin sp_revokelogin sp_srvrolepermission sp_dbfixedrolepermission','Remove references to unsupported system procedures before upgrading to database compatibility level 100.','Not Provided','Error','BreakingChange','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00312','Remove references to undocumented system tables','Many system tables that were undocumented in prior releases have changed or no longer exist; therefore, using these tables may cause errors after upgrading to SQL Server 2008.','The list of undocumented system tables that are removed is provided in the below article. Remove references to undocumented system tables - https://go.microsoft.com/fwlink/?LinkID=708254 The Corrective Action provides the alternative replacements for some of the unsupported objects that can be used to modify your applications.','NamedTableReference Class - https://go.microsoft.com/fwlink/?LinkID=703911 SchemaObjectFunctionTableReference Class - https://go.microsoft.com/fwlink/?LinkID=703927 Remove references to undocumented system tables - https://go.microsoft.com/fwlink/?LinkID=708254','Warning','Deprecated','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00333','Unqualified Join(s) detected','Starting with database compatibility level 90 and higher, in rare occasions, the unqualified join syntax can cause missing join predicate warnings, leading to long running queries.','An example of Unqualified join  is select * from table1, table2 where table1.col1 = table2.col1  Use  explicit JOIN syntax in all cases. SQL Server supports the below explicit joins: LEFT OUTER JOIN or LEFT JOIN RIGHT OUTER JOIN or RIGHT JOIN FULL OUTER JOIN or FULL JOIN INNER JOIN','Missing join Predicate Event Class - https://go.microsoft.com/fwlink/?LinkId=798567 Deprecation of Old Style JOIN Syntax: Only A Partial Thing - https://go.microsoft.com/fwlink/?LinkId=798568 DOC : Please strive to use ANSI-style joins instead of deprecated syntax - https://go.microsoft.com/fwlink/?LinkId=798569 Missing join predicate icon should be red - https://go.microsoft.com/fwlink/?LinkId=798570','Info','BehaviorChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00317','Inline XDR Schema Generation is deprecated','The XMLDATA directive to the FOR XML option is deprecated. The XMLDATA directive in FOR XML returns an inline XDR schema together with the query result. However, the XDR schema does not support all the new data types and other enhancements introduced in SQL Server 2005 and above.','Use XSD generation in the case of RAW and AUTO modes. There is no replacement for the XMLDATA directive in EXPLICIT mode. You can also request an inline XSD schema by using the XMLSCHEMA directive.','Inline XDR Schema Generation - https://go.microsoft.com/fwlink/?LinkId=798571','Warning','Deprecated','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00001','Syntax issue on the source server','While parsing the schema on the source database, one or more syntax issues were found. Syntax issues on the source database indicate that some objects contain unsupported syntax due to which all assessment rules were not run on the object.','Review the list of objects and issues reported, fix the syntax errors, and re-run assessment before migrating this database.','Not Provided','Error','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00042','The Microsoft Full-Text Engine for SQL Server will not load unsigned third-party components by default','A third-party filter, such as a PDF filter, that is currently installed on the server will not be loaded by the Microsoft Full-Text Engine for SQL Server by default after upgrade.','To load a third party filter, you must set load_os_resource and turn off verify_signature on that instance.','Not Provided','Warning','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00056','Maintenance Plans:Log shipping maintenance plans wont upgrade','Not Provided','Not Provided','Not Provided','Warning','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00076','SQL Express replication agents','Not Provided','Reconfigure replication synchronization if you upgrade to SQL Server Express Edition','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00078','Merge  Publisher and Subscriber identity ranges','Upgrading might assign new identity ranges for merge replication','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00080','Merge Jet subscriptions','Merge replication no longer supports Jet subscriptions, which can be used by Access','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00082','Log shipping will not run after upgrading','Log shipping will not run after upgrading','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00084','Upgrading will modify queued updating subscriptions that use Message Queuing','Upgrading will modify queued updating subscriptions that use Message Queuing','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00005','Large backup or restore history tables make upgrade appear to not respond','Not Provided','Large backup or restore history tables make upgrade appear to not respond.','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00053','Changes to CPU and memory limits for SQL Server Standard and Enterprise','Changes to CPU and memory limits for SQL Server Standard and Enterprise','Not Provided','Not Provided','Not Provided','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00025','Use the full path to register extended stored procedure DLL names','Extended stored procedures that were previously registered without the full path for the DLL name may not work after you upgrade. This is because the old BINN directory is not added to the new path during the upgrade process. SQL Server may not be able to locate the extended stored procedures.','Before you upgrade, follow these steps for each extended stored procedure that was not registered with a full path name:  1. Run sp_dropextendedproc to remove the extended stored procedure.   2. Run sp_addextendedproc to register the extended stored procedure with the full path name.','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00014','Verify that no database files are on compressed drives during the upgrade process','Not Provided','Verify that no database files are on compressed drives during the upgrade process','Not Provided','Not Provided','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00019','After upgrade, your database compatibility level may have changed to a new level.','The migration process may have changed your source compatibility level to a new minimum supported level on the target SQL Server.','We recommend you to validate your applications typical workload against the new compatibility level before release the database for production use.','Not Provided','High','BehaviorChange','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00059','Upgrade all target servers before upgrading the master server','Not Provided','Upgrade all target servers before upgrading the master server','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00051','Large constants are typed as large-value types in 90 or later compatibility modes','Large constants are typed as large-value types in 90 or later compatibility modes','Not Provided','Not Provided','Not Provided','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00307','Identical table names in the same FROM clause should be prefixed by table alias.','In SQL Server 2005 or later, duplicate table names (even if they are fully qualified using the DBname.schema.tablename convention) are only allowed in a FROM clause if they have unique aliases. In SQL 2000 these would have been allowed even without the alias.','Prefix all tables in the FROM clause with aliases, and refer to the columns with the alias prefixed.','http://blogs.msdn.com/ialonso/archive/2007/12/21/msg-1013-the-object-s-and-s-in-the-from-clause-have-the-same-exposed-names-use-correlation-names-to-distinguish-them.aspx http://social.msdn.microsoft.com/Forums/en/transactsql/thread/d9b8e6d0-430f-42f2-9c94-d78ceebad919 http://stackoverflow.com/questions/8956577/how-can-i-correct-the-correlation-names-on-this-sql-join  DISCLAIMER: Third-party link provided as-is and Microsoft does not offer any guarantees or warranties regarding the content on the third party site.','Info','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00119','Remove DDL operations on the inserted and deleted tables inside DML triggers','Not Provided','Remove DDL operations on the inserted and deleted tables inside DML triggers','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00114','Service account requirements for upgrading to SQL Server 2008 on a domain controller','Service account requirements for upgrading to SQL Server 2008 on a domain controller','Not Provided','Not Provided','Not Provided','Not Provided','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00001','ActiveX Subsystem is not supported anymore.','Not Provided','ActiveX Subsystem is not supported anymore','Not Provided','Medium','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00008','Remove the cdc schema if you plan to enable change data capture','Not Provided','Remove the cdc schema if you plan to enable change data capture','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00010','Warning about client side usage of GEOMETRY, GEOGRAPHY and HIERARCHYID','Not Provided','Warning about client side usage of GEOMETRY, GEOGRAPHY and HIERARCHYID','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00012','Remove statements that modify column-level permissions on system objects','Not Provided','Remove statements that modify column-level permissions on system objects','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00018','Remove calls to the deprecated DBCC CONCURRENCYVIOLATION command','Not Provided','Remove calls to the deprecated DBCC CONCURRENCYVIOLATION command','Not Provided','Not Provided','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00027','Identifies distributed partitioned views with datetime columns','The distributed partition views (DPVs) that are listed in the report contain potential remote references to smalldatetime columns. Under compatibility level 110, remote smalldatetime columns are now returned to local servers as smalldatetime columns instead of as datetime columns.  This behavior change may make the DPV unable to accept updates.','You may need to modify the data type on the remote column to datetime to adjust for this change.','Not Provided','Warning','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00028','Remove statements that drop system objects','Not Provided','Remove statements that drop system objects','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00030','Use sp_rename to rename duplicate index name','Not Provided','Use sp_rename to rename duplicate index name','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00032','Look for duplicate SIDs','Not Provided','Remove duplicate login security identifier (SID)','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00035','Length of full-text catalog names restricted to 120 characters','Length of full-text catalog names restricted to 120 characters','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00036','FullText:Itemcount changed for Fulltext Catalog','FULLTEXTCATALOGPROPERTY ItemCount property returns fewer items','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00038','Full-text indexes on nonpersisted, computed columns are not allowed','Full-text indexes on nonpersisted, computed columns are not allowed','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00039','Modify stored procedures that use discontinued Full-Text Search properties','Not Provided','Modify stored procedures that use discontinued Full-Text Search properties','Not Provided','Not Provided','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00045','Modify indexes that depend on the return type of HOST_ID','Modify indexes that depend on the return type of HOST_ID','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00048','0xFFFF character is not valid as an object identifier.','0xFFFF character is not valid as an object identifier.','Before you change the database compatibility mode to 90 or later, rename the object that contains the 0xFFFF character.','http://go.microsoft.com/fwlink/?LinkID=733411&clcid=0x409','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00055','SQL Server Agent log shipping job category causes upgrade to fail','SQL Server Agent log shipping job category causes upgrade to fail','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00061','Remove UDTs named after the reserved DATE and TIME data types','Not Provided','Remove UDTs named after the reserved DATE and TIME data types','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00066','Update OPENXML XPath expressions to remove unsupported functions','Not Provided','Update OPENXML XPath expressions to remove unsupported functions','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00070','osql no longer supports the ED and !! commands','osql no longer supports the ED and !! commands','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00072','Target of OUTPUT INTO cannot have triggers enabled','Target of OUTPUT INTO cannot have triggers enabled','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00108','SOUNDEX','Warns on use of SOUNDEX','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00111','SQL Server Agent Service cannot use SQL Server Authentication','SQL Server Agent Service cannot use SQL Server Authentication','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00116','Modify applications to expect bigint values from sysperfinfo.cntr_value','Not Provided','Modify applications to expect bigint values from sysperfinfo.cntr_value','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00121','Trusted Remote Logins','The trusted option in remote login mapping is no longer supported','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00123','Modify UPDATETEXT statements that Additional and write to binary large objects (BLOBs)','Not Provided','Modify UPDATETEXT statements that read and write to binary large objects (BLOBs)','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00127','SELECT * FROM FN_GET_AUDIT_FILE Will break as the audit log schema has changed with the addition of 2 new columns','SELECT * FROM FN_GET_AUDIT_FILE Will break as the audit log schema has changed with the addition of 2 new columns','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00132','Changes to the storage format for types xs:dateTime, xs:date, and xs:time','Changes to the storage format for types xs:dateTime, xs:date, and xs:time','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00133','Replace usage of the xp_sqlagent_proxy_account extended stored procedure with new stored procedures','Not Provided','Replace usage of the xp_sqlagent_proxy_account extended stored procedure with new stored procedures','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00134','Rename use sys','Rename use sys','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00135','Upgrade Blocker - Check for user name sys in a database','Upgrade Blocker - Check for user name sys in a database','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00303','Database options ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON','ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON regardless of the ALTER DATABASE option turning it off.','There is no remedial action other than awareness. If this change impacts code, you will need to handle that accordingly.','http://msdn.microsoft.com/en-us/library/ms143729(v=sql.110).aspx http://technet.microsoft.com/en-us/library/ms188048.aspx http://technet.microsoft.com/en-us/library/ms187403.aspx http://technet.microsoft.com/en-us/library/ms176056.aspx http://msdn.microsoft.com/en-us/library/bb522682.aspx ','Error','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00323','Numbered Procedures are deprecated','Numbered procedures are deprecated in SQL Server 2005 and above. Use of numbered procedures is discouraged.','Do not use numbered stored procedures.','http://msdn.microsoft.com/en-us/library/ms179865(v=SQL.90).aspx','Error','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00309','SET options ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON','ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON regardless of the SET option turning it off.','There is no remedial action other than awareness. If this change impacts code, you will need to handle that accordingly.','http://msdn.microsoft.com/en-us/library/ms143729(v=sql.110).aspx http://technet.microsoft.com/en-us/library/ms188048.aspx http://technet.microsoft.com/en-us/library/ms187403.aspx http://technet.microsoft.com/en-us/library/ms176056.aspx','Not Provided','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00310','SETUSER statement usage','SETUSER is included for backward compatibility only. SETUSER may not be supported in a future release of SQL Server.','We recommend that you use EXECUTE AS instead.','https://msdn.microsoft.com/en-us/library/ms186297.aspx','Info','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00330','Statements without semicolon','Although the semicolon is not required for most statements in this version of SQL Server, it will be required in a future version.','For future compatibility please terminate all T-SQL statements with a semicolon.','http://msdn.microsoft.com/en-us/library/ms177563.aspx','Info','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00313','Deprecated functions READTEXT, WRITETEXT or UPDATETEXT','These functions are marked as deprecated. In some cases, using READTEXT, WRITETEXT or UPDATETEXT could harm the performance.','Deprecated functions are marked to be discontinued on next versions of SQL Server, should avoid their uses.','http://msdn.microsoft.com/pt-br/library/ms187365.aspx http://msdn.microsoft.com/pt-br/library/ms186838.aspx http://msdn.microsoft.com/pt-br/library/ms189466.aspx','Warning','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00314','TORN_PAGE_DETECTION option for ALTER DATABASE is deprecated','The syntax structure TORN_PAGE_DETECTION ON | OFF will be removed in a future version of SQL Server.','Avoid using this syntax structure in new development work, and plan to modify applications that currently use the syntax structure. Use the PAGE_VERIFY option instead.','http://technet.microsoft.com/en-us/library/bb402873.aspx http://msdn.microsoft.com/en-us/library/ms143729.aspx ','Warning','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00315','Ability to return result sets from triggers is deprecated','The ability to return results from triggers will be removed in a future version of SQL Server. Triggers that return result sets may cause unexpected behavior in applications that are not designed to work with them.','Avoid returning result sets from triggers in new development work, and plan to modify applications that currently do this.','http://technet.microsoft.com/en-us/library/ms189799.aspx http://msdn.microsoft.com/en-us/library/ms143729(v=sql.110).aspx ','Warning','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00329','VARCHAR / NVARCHAR declared without size specification','When you use data types of variable length such as VARCHAR, NVARCHAR, it is always recommended to explicitly specify the size. Failure to do so means that SQL will select the size for you, either 1 (when declaring parameters) or 30 (when converting) characters.','Explicitly specify the size in all conditions.','http://connect.microsoft.com/SQL/feedback/ViewFeedback.aspx?FeedbackID=244395 http://connect.microsoft.com/SQL/feedback/ViewFeedback.aspx?FeedbackID=267605','Warning','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00316','Use data compression instead of the vardecimal compression feature','The vardecimal storage format is deprecated and will be removed in a future version of Microsoft SQL Server.','We recommend that you use SQL Server 2012 data compression instead of the vardecimal storage format. SQL Server 2012 data compression, compresses decimal values as well as other data types.   Avoid using the vardecimal storage format feature in new development work, and plan to modify applications that currently use this feature. ','http://technet.microsoft.com/en-us/library/ms143729.aspx','Warning','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00074','Upgrading will change the SQL Server Agent User Proxy Account to the temporary UpgradedProxyAccount','Upgrading will change the SQL Server Agent User Proxy Account to the temporary UpgradedProxyAccount','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00129','Winsock Proxy configuration not supported','Winsock Proxy configuration not supported','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00304','The :: prefix is no longer required for table valued functions','In SQL 2000, a double colon prefix was necessary to invoke table-valued functions. In SQL 2005 and above, the same is no longer required.','For system table-valued functions, you can use the sys schema prefix, or many times no prefix is needed. For user-defined TVFs, no prefix is needed.','http://msdn.microsoft.com/en-US/library/ms143729(v=sql.100).aspx http://sqlblog.com/blogs/kalen_delaney/archive/2006/09/06/186.aspx http://social.msdn.microsoft.com/Forums/sqlserver/en-US/ba6f31bb-3a2e-4cb7-abda-078d3ea87e92/what-is-the-function-or-purpose-of-the-colons-in-fntracegettable?forum=transactsql','Warning','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00334','Objects have been identified that XML FOR EXPLICIT clause','Avoid using FOR XML EXPLICIT in Microsoft SQL Server 2005 or SQL Server 2008. Using FOR XML TYPE, PATH will generally provide more compact and maintainable code. In addition, it will typically perform better.   In SQL Server 2000, there is no alternative to FOR XML EXPLICIT.','SQL Server 2005 XML generation should be coded using FOR XML TYPE, PATH. However, FOR XML EXPLICIT should be used only in rare situations when it provides better performance and more compact code.','Not Provided','Info','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00001','ActiveX Subsystem is not supported anymore.','Not Provided','ActiveX Subsystem is not supported anymore.','Not Provided','Medium','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00003','Set autogrow is turned on for all data and log files after the migration is completed on the target server.','Not Provided','Our assessment detected data or log files that are not set to autogrow on your source SQL Server. New and enhanced features require additional disk space for user databases and the tempdb system database.  Consider enabling the auto grow setting for all data and log files but at the same time, for a managed production system, you must consider autogrow to be merely a contingency for unexpected growth. Do not manage your data and log growth on a day-to-day basis with autogrow.','https://msdn.microsoft.com/en-us/library/ee240689(v=sql.120).aspx https://support.microsoft.com/en-us/kb/315512','Medium','BehaviorChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00004','Auto Update of Statistics','Not Provided','Set AUTO_UPDATE_STATISTICS ON','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00005','Large backup or restore history tables make upgrade appear to not respond','Large backup or restore history tables make upgrade appear to not respond.','Not Provided','Not Provided','Not Provided','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00006','BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements are not supported','Database Migration Assistant detected BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements.  These backup/restore options are not supported anymore.','Remove BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements from scripts and instead use the new options provided in Additional readings section.','BACKUP (Transact-SQL) - http://go.microsoft.com/fwlink/?LinkID=698472 Discontinued Database Engine Functionality in SQL Server 2008 - https://msdn.microsoft.com/en-us/library/ms144262(v=sql.100).aspx ','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00007','BACKUP/RESTORE TRANSACTION statements are deprecated or discontinued','Not Provided','Remove BACKUP/RESTORE TRANSACTION statements from scripts and use the  new supported options.','Discontinued Database Engine Functionality in SQL Server 2008 - https://msdn.microsoft.com/en-us/library/ms144262(v=sql.100).aspx ','Warning','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00009','Identify user defined CLR objects.','Not Provided','Identify user defined CLR objects.','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00011','Remove colon following reserved keyword','Not Provided','Remove colon following reserved keyword','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00013','COMPUTE clause is not allowed in database compatibility 110','The COMPUTE clause generates totals that appear as additional summary columns at the end of the result set. However, this clause is no longer supported in SQL Server 2012.','The TSQL module needs to be re-written using the ROLLUP operator instead.','Not Provided','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00014','Verify that no database files are on compressed drives during the upgrade process','Not Provided','Verify that no database files are on compressed drives during the upgrade process','Not Provided','High','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00017','Database mirroring deprecation announcement.','The database mirroring feature is deprecated and will be removed in a future version of SQL Server.','Avoid using this feature in new development work, and plan to modify applications that currently use this feature.','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00019','After upgrade, compatibility levels 60, 65, 70 and 80 will be set to 90','After upgrade, compatibility levels 60, 65, 70 and 80 will be set to 90','Not Provided','Not Provided','High','BehaviorChange','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00020','Read-only databases cannot be upgraded','Read-only databases cannot be upgraded','Read-only databases cannot be upgraded - https://msdn.microsoft.com/en-us/library/ee210493(v=sql.120).aspx','Not Provided','High','BreakingChange','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00021','Verify all filegroups are writeable during the upgrade process','Not Provided','Verify all filegroups are writeable during the upgrade process','Verify all filegroups are writeable during the upgrade process - https://msdn.microsoft.com/en-us/library/ee210494(v=sql.120).aspx','High','BreakingChange','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00023','SQL Server native SOAP support is discontinued in this version of SQL Server.','SQL Server native SOAP support is discontinued in SQL Server 2014 and above.','Native XML Web Services: Deprecated in SQL Server 2008 - https://msdn.microsoft.com/en-us/library/cc280436(v=sql.105).aspx','SQL Server native SOAP support is discontinued in this version of SQL Server - https://msdn.microsoft.com/en-us/library/ee240649(v=sql.120).aspx','Error','BreakingChange','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00024','DESX encryption algorithm is now deprecated and will be removed in a future version of SQL Server.','Not Provided','The DESX keyword is now deprecated and will be removed in a future version of SQL Server.  Avoid using it in new development work, and plan to modify applications that currently use it.','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00026','Dormant SQL Server 6.5 logins cannot be upgraded','Dormant SQL Server 6.5 logins cannot be upgraded','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00027','Identifies distributed partitioned views with datetime columns','The distributed partition views (DPVs) that are listed in the report contain potential remote references to smalldatetime columns. Under compatibility level 110, remote smalldatetime columns are now returned to local servers as smalldatetime columns instead of as datetime columns.  This behavior change may make the DPV unable to accept updates. ','You may need to modify the data type on the remote column to datetime to adjust for this change.','Not Provided','Warning','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00029','DUMP/LOAD statements are deprecated','DUMP/LOAD statements are deprecated','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00031','Upgrade Blocker to detect duplicate indexes on system databases','Not Provided','Use sp_rename to rename duplicate index name','Not Provided','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00034','.NET Framework assemblies in the GAC must match the assemblies in the database','When .NET is upgraded, the version of assemblies in the database must match the version of .NET SQL Server is using.  This is not done automatically since persistent data may be relying upon those assemblies.  This is only an issue for those assemblies not approved for use in SAFE assemblies.  Please refer to Microsoft Knowledge Base Article 949080.','After upgrading SQL Server, you will also need to update (using Alter Assembly) any .NET Framework assemblies which are not on the approved list but have been cataloged in the database.','https://support.microsoft.com/en-us/kb/949080/','Warning','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00036','FullText:Itemcount changed for Fulltext Catalog','FULLTEXTCATALOGPROPERTY ItemCount property returns fewer items','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00037','Upgrading will cause Full-Text Search to use instance-level, not global, word breakers and filters by default','SQL Server allows the instance-level registration of new word breakers and filters. This instance-level registration provides functional and security isolation between instances.','After upgrading, use the sp_fulltext_service to set the service property and load_os_resources, which allows the components to be loaded. You must run the following:  sp_fulltext_service load_os_resources, 1 ','Not Provided','Warning','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00039','Modify stored procedures that use discontinued Full-Text Search properties','Not Provided','Modify stored procedures that use discontinued Full-Text Search properties','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00040','Full-Text Search has changed since SQL Server 2008','Full-Text Search has changed since SQL Server 2008','Not Provided','Breaking Changes to Full-Text Search - https://technet.microsoft.com/en-us/library/ms143709(v=sql.110).aspx','Warning','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00041','Full-text indexes on master, tempdb and model databases are not supported','Full-text indexes on master, tempdb and model databases are not supported','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00043','Full-Text Search word breakers and filters significantly improved in SQL Server 2005 and SQL Server 2008','Full-Text Search word breakers and filters significantly improved in SQL Server 2005 and SQL Server 2008','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00044','Remove UDTs named after the reserved GEOMETRY and GEOGRAPHY data types.','The terms used for spatial data types should not be used as names for either common language runtime (CLR) or alias UDTs.','Remove UDTs named after the reserved GEOMETRY and GEOGRAPHY data types.','Remove UDTs named after the reserved GEOMETRY and GEOGRAPHY data types - http://go.microsoft.com/fwlink/?LinkID=724415&clcid=0x409','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00047','INFORMATION_SCHEMA.SCHEMATA returns schema names in a database, not databases in an instance','INFORMATION_SCHEMA.SCHEMATA returns schema names in a database, not databases in an instance','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00049','Invalid named pipe name can block upgrade','Invalid named pipe name can block upgrade','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00050','Table hints in indexed view definitions are ignored in 80 compatibility mode and are not allowed in 90 mode or later','Table hints in indexed view definitions are ignored in 80 compatibility mode and are not allowed in 90 mode or later','Table hints must be removed from the definitions of indexed views. Regardless of which compatibility mode is used, we recommend that you test the application. By testing the application, you can make sure it performs as expected when indexed views are created, updated, and accessed, including when indexed views are matched to queries.','Table hints in indexed view definitions are ignored in 80 compatibility mode and are not allowed in 90 mode or late - http://go.microsoft.com/fwlink/?LinkID=733249&clcid=0x409','Warning','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00053','Changes to CPU and memory limits for SQL Server Standard and Enterprise','Changes to CPU and memory limits for SQL Server Standard and Enterprise','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00054','Rename logins matching fixed server role names','Not Provided','Rename logins matching fixed server role names','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00056','Maintenance Plans:Log shipping maintenance plans wont upgrade','Upgrading will disable SQL Server Agent jobs that perform log shipping','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00057','Database maintenance plans superseded','Database maintenance plans superseded','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00058','After upgrade, new reserved keywords cannot be used as identifiers','After upgrade, new reserved keywords cannot be used as identifiers','After upgrade, new reserved keywords cannot be used as identifiers - https://msdn.microsoft.com/en-us/library/ee240722(v=sql.120).aspx','Not Provided','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00060','Deprecated client server connectivity network protocols','Detected client server connectivity protocols that are not supported in SQL Server 2008.','Client applications that use Banyan VINES Sequenced Packet Protocol (SPP), Multiprotocol (RPC), AppleTalk, or NWLink IPX/SPX network protocols must connect using a supported protocol.','Not Provided','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00062','Tables and Columns named NEXT may lead to an error using compatibility Level 110 and above','Tables or columns named NEXT were detected. Sequences, introduced in Microsoft SQL Server 2012, use the ANSI standard NEXT VALUE FOR function. If a table or a column is named NEXT and the column is aliased as VALUE, and if the ANSI standard AS is omitted, the resulting statement can cause an error.','Rewrite statements to include the ANSI standard AS keyword when aliasing a table or column. For example, when a column is named NEXT and that column is aliased as VALUE, the query SELECT NEXT VALUE FROM Table will cause an error and should be rewritten as SELECT NEXT AS VALUE FROM Table. Similarly, when a table is named NEXT and that table is aliased as VALUE, the query SELECT Col1 FROM NEXT VALUE will cause an error and should be rewritten as SELECT Col1 FROM NEXT AS VALUE.','Not Provided','BreakingChange','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00065','Remove references to undocumented system tables','Not Provided','Remove references to undocumented system tables','Not Provided','Not Provided','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00069','Remove UDTs named after the reserved ORDPATH data type','Not Provided','Remove UDTs named after the reserved ORDPATH data type','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00071','After upgrade, Full-Text Search will not allow predicates in OUTPUT INTO expression','After upgrade, Full-Text Search will not allow predicates in OUTPUT INTO expression','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00073','Costing changes may make some queries not run in SQL Server 2008 when they did run in earlier versions due to QUERY_GOVERNOR_COST_LIMIT','Costing changes may make some queries not run in SQL Server 2008 when they did run in earlier versions due to QUERY_GOVERNOR_COST_LIMIT','Not Provided','Not Provided','Not Provided','Not Provided','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00075','Merge conflict tables','Upgrading will make the DBO user the owner of all merge replication conflict tables','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00077','SQL Express publications','Upgrading to SQL Server Express Edition will drop merge publications','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00079','Merge  Publisher and Subscriber identity ranges','Upgrading might assign new identity ranges for merge replication','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00081','Local  agent connections','Upgrading will modify replication agents to use Windows Authentication for local connections','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00083','Snapshot after upgrading a merge publication','Not Provided','Update merge replication metadata by running agents after upgrade','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00085','Detach database ID 32767','Detach database ID 32767','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00086','Type named xml is now a reserved system type name','Type named xml is now a reserved system type name','Remove UDTs named after XML','Not Provided','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00109','Remove statements that modify system objects','Not Provided','Remove statements that modify system objects','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00110','New column in output of sp_helptrigger may impact applications','New column trigger_schema has been added to the output of sp_helptrigger. This may impact applications.','Review the use of sp_helptrigger in applications. You may need to modify your applications to accommodate the additional column. Alternatively, you can use the sys.triggers catalog view instead.','New column in output of sp_helptrigger may impact applications - https://msdn.microsoft.com/en-us/library/ee240703(v=sql.120).aspx','Warning','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00112','Update token syntax in SQL Server Agent job steps','Not Provided','Update token syntax in SQL Server Agent job steps','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00113','SQL Mail Has Been Discontinued','SQL Mail Has Been Discontinued','Use Database Mail Instead of SQL Mai - https://msdn.microsoft.com/en-us/library/bb402904(v=sql.110)','SQL Mai - https://technet.microsoft.com/en-us/library/ms177418(v=sql.105).aspx','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00115','Changes to behavior in syslockinfo and sp_lock','Changes to behavior in syslockinfo and sp_lock','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00118','Changes to behavior of trace flags','Changes to behavior of trace flags','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00120','Nested AFTER trigger fires even when trigger nesting is OFF','The first AFTER trigger nested inside an INSTEAD OF trigger fires even if the nested triggers server configuration option is set to 0. However, under this setting, subsequent AFTER triggers do not fire.','Review your applications for nested triggers to determine whether the applications still comply with your business rules with regard to this new behavior when the nested triggers server configuration option is set to 0, and then make appropriate modifications.','Not Provided','Not Provided','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00122','Other Database Engine upgrade issues','Other Database Engine upgrade issues','Not Provided','Not Provided','Not Provided','Not Provided','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00124','Changes to behavior of string-length and substring','Changes to behavior of string-length and substring','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00128','Web Assistant stored procedures have been removed','Web Assistant stored procedures have been removed','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00130','Specify the WITH keyword when using table hints in 90 compatibility mode','Not Provided','Specify the WITH keyword when using table hints in 90 compatibility mode','Not Provided','Not Provided','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00132','Changes to the storage format for types xs:dateTime, xs:date, and xs:time','Changes to the storage format for types xs:dateTime, xs:date, and xs:time','Not Provided','Not Provided','Not Provided','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00134','Rename use sys','Rename use sys','Not Provided','Not Provided','Error','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00135','Upgrade Blocker - Check for user name sys in a database','Upgrade Blocker - Check for user name sys in a database','Not Provided','Not Provided','High','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00300','Remove the Use of PASSWORD in BACKUP command','The use of BACKUP commands were detected which are deprecated. BACKUP { DATABASE | LOG } WITH PASSWORD and BACKUP { DATABASE | LOG } WITH MEDIAPASSWORD is a deprecated feature.  BACKUP { DATABASE | LOG } WITH PASSWORD and BACKUP { DATABASE | LOG } WITH MEDIAPASSWORD are discontinued in SQL Server 2012.','Remove the use of BACKUP { DATABASE | LOG } WITH PASSWORD and BACKUP { DATABASE | LOG } WITH MEDIAPASSWORD commands. Replace them with the currently supported BACKUP command syntax. This syntax should not be used for creating future restore scripts.','BACKUP (Transact-SQL) - http://msdn.microsoft.com/en-us/library/ms186865.aspx Deprecated Database Engine Features for SQL Server - http://msdn.microsoft.com/en-us/library/ms143729.aspx ','Warning','Deprecated','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00301','WITH CHECK OPTION is not supported in views that contain TOP in 90 or later compatibility modes','We detected a view that uses the WITH CHECK OPTION and a TOP clause in the SELECT statement of the view or in a referenced view. Views defined this way incorrectly allow data to be modified through the view and may produce inaccurate results when the database compatibility mode is set to 80 and earlier. Data cannot be inserted or updated through a view that uses WITH CHECK OPTION when the view or a referenced view uses the TOP clause and the database compatibility mode is set to 90 or later.','Modify views that use both WITH CHECK OPTION and TOP if data modification through the view is required.','Not Provided','Warning','BehaviorChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00302','Deprecated DBCC commands referenced in your T-SQL objects','Many DBCC commands that were available in prior releases have been replaced with DMVs and DMFs, or no longer exist; therefore, using these commands may cause errors and unforeseen effects after upgrading SQL Server.','SQL Server books online may have new options  equivalent DMVs and DMFs that you may want to use instead of deprecated and discontinued DBCC commands.  ','SQL Server, Deprecated Features Object - http://go.microsoft.com/fwlink/?LinkID=698477 Discontinued Database Engine Functionality in SQL Server 2016 - http://go.microsoft.com/fwlink/?LinkID=698744 Breaking Changes to Full-Text Search - http://go.microsoft.com/fwlink/?LinkID=698745','High','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00303','Database options ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON','ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON regardless of the ALTER DATABASE option turning it off.','There is no remedial action other than awareness. If this change impacts code, you will need to handle that accordingly.','http://msdn.microsoft.com/en-us/library/ms143729(v=sql.110).aspx http://technet.microsoft.com/en-us/library/ms188048.aspx http://technet.microsoft.com/en-us/library/ms187403.aspx http://technet.microsoft.com/en-us/library/ms176056.aspx http://msdn.microsoft.com/en-us/library/bb522682.aspx','Error','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00304','The :: prefix is no longer required for table valued functions','In SQL 2000, a double colon prefix was necessary to invoke table-valued functions. In SQL 2005 and above, the same is no longer required.','For system table-valued functions, you can use the sys schema prefix, or many times no prefix is needed. For user-defined TVFs, no prefix is needed.','http://msdn.microsoft.com/en-US/library/ms143729(v=sql.100).aspx http://sqlblog.com/blogs/kalen_delaney/archive/2006/09/06/186.aspx http://social.msdn.microsoft.com/Forums/sqlserver/en-US/ba6f31bb-3a2e-4cb7-abda-078d3ea87e92/what-is-the-function-or-purpose-of-the-colons-in-fntracegettable?forum=transactsql  NOTE: Please note third party links are provided as-is and Microsoft does not offer any guarantees or warranties regarding the content on the third party site.','Warning','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00305','Encryption using RC4 or RC4_128 is not supported','We detected a symmetric key which uses a not supported encryption algorithm. Repeated use of the same RC4 or RC4_128 KEY_GUID on different blocks of data will result in the same RC4 key because SQL Server does not provide a salt automatically. Using the same RC4 key repeatedly is a well-known error that will result in very weak encryption. Therefore, the RC4 and RC4_128 keywords are not supported in database compatibility Level 110 onwards.','Do not use this feature in new development work, and modify applications that currently use this feature as soon as possible. Use another encryption algorithm such as AES.','Choose an ecryption algorithm - http://technet.microsoft.com/en-us/library/ms345262.aspx','Deprecated ','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00306','Deprecated data types TEXT, IMAGE or NTEXT','These data types are checked as deprecated. In some cases, using TEXT, IMAGE or NTEXT might harm performance.','Deprecated data types are marked to be discontinued on next versions of SQL Server, should use new data types such as: (varchar(max), nvarchar(max), varbinary(max) and etc.)','https://msdn.microsoft.com/en-us/library/ms187993.aspx','Warning','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00307','Identical table names in the same FROM clause should be prefixed by table alias.','In SQL Server 2005 or later, duplicate table names (even if they are fully qualified using the DBname.schema.tablename convention) are only allowed in a FROM clause if they have unique aliases. In SQL 2000 these would have been allowed even without the alias.','Not Provided','http://blogs.msdn.com/ialonso/archive/2007/12/21/msg-1013-the-object-s-and-s-in-the-from-clause-have-the-same-exposed-names-use-correlation-names-to-distinguish-them.aspx http://social.msdn.microsoft.com/Forums/en/transactsql/thread/d9b8e6d0-430f-42f2-9c94-d78ceebad919 http://stackoverflow.com/questions/8956577/how-can-i-correct-the-correlation-names-on-this-sql-join  DISCLAIMER: Third-party link provided as-is and Microsoft does not offer any guarantees or warranties regarding the content on the third party site.','Info','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00308','Legacy style RAISERROR calls should be replaced with modern equivalents','RAISERROR calls like the below example are termed as legacy-style because they do not include the commas and the parenthesis.   RAISERROR 50001 this is a test   This method of calling RAISERROR is deprecated in SQL Server 2008 and removed in SQL Server 2012 regardless of the database compatibility level. ','Rewrite the statement using the current RAISERROR syntax, or evaluate if the modern approach of TRY...CATCH...THROW is feasible if you are using SQL Server 2012 or above.','Deprecated Database Engine Features in SQL Server 2008 - http://msdn.microsoft.com/en-us/library/ms143729(v=sql.100).aspx Please clarify which RAISERROR variation is on the deprecation list - http://social.msdn.microsoft.com/Forums/sqlserver/en-US/81ef8f38-7ddc-486b-983c-18dbf7be412d/please-clarify-which-raiserror-variation-is-on-the-deprecation-list?forum=transactsql','BreakingChange','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00309','SET options ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON','ANSI_NULLS, ANSI_PADDING and CONCAT_NULLS_YIELDS_NULL will always be set to ON regardless of the SET option turning it off.','There is no remedial action other than awareness. If this change impacts code, you will need to handle that accordingly.','http://msdn.microsoft.com/en-us/library/ms143729(v=sql.110).aspx http://technet.microsoft.com/en-us/library/ms188048.aspx http://technet.microsoft.com/en-us/library/ms187403.aspx http://technet.microsoft.com/en-us/library/ms176056.aspx','High','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00310','SETUSER statement usage','SETUSER is included for backward compatibility only. SETUSER may not be supported in a future release of SQL Server.','We recommend that you use EXECUTE AS instead.','https://msdn.microsoft.com/en-us/library/ms186297.aspx','Info','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00311','Detected statements that reference removed system stored procedures and extended stored procedures that are not available in database compatibility level 100 and higher. Statements that reference these objects will fail.','Removed procedure cannot be used in database compatibility level 100','Remove all unsupported system procedures before upgrading to database compatibility level 100.','Not Provided','BreakingChange','Not Provided','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00312','Remove references to undocumented system tables','Many system tables that were undocumented in prior releases have changed or no longer exist; therefore, using these tables may cause errors after upgrading to SQL Server 2008.','SQL Server Upgrade Advisor and SQL Books Online may contain documentation for equivalent tables.','NamedTableReference Class - http://go.microsoft.com/fwlink/?LinkID=703911 SchemaObjectFunctionTableReference Class - http://go.microsoft.com/fwlink/?LinkID=703927 SQL Server 2014 Upgrade Advisor - http://go.microsoft.com/fwlink/?LinkID=708252 Remove references to undocumented system tables - http://go.microsoft.com/fwlink/?LinkID=708254','BreakingChange','Not Provided','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00313','Deprecated functions READTEXT, WRITETEXT or UPDATETEXT','These functions are marked as deprecated. In some cases, using READTEXT, WRITETEXT or UPDATETEXT could harm the performance.','Deprecated functions are marked to be discontinued on next versions of SQL Server, should avoid their uses.','http://msdn.microsoft.com/pt-br/library/ms187365.aspx http://msdn.microsoft.com/pt-br/library/ms186838.aspx http://msdn.microsoft.com/pt-br/library/ms189466.aspx ','Warning','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00314','TORN_PAGE_DETECTION option for ALTER DATABASE is deprecated','The syntax structure TORN_PAGE_DETECTION ON | OFF will be removed in a future version of SQL Server.','Avoid using this syntax structure in new development work, and plan to modify applications that currently use the syntax structure. Use the PAGE_VERIFY option instead.','http://technet.microsoft.com/en-us/library/bb402873.aspx http://msdn.microsoft.com/en-us/library/ms143729.aspx','Warning','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00315','The ability to return results from triggers will be removed in a future version of SQL Server. Triggers that return result sets may cause unexpected behavior in applications that are not designed to work with them.','The ability to return results from triggers will be removed in a future version of SQL Server. Triggers that return result sets may cause unexpected behavior in applications that are not designed to work with them.','Avoid returning result sets from triggers in new development work, and plan to modify applications that currently do this.','http://technet.microsoft.com/en-us/library/ms189799.aspx http://msdn.microsoft.com/en-us/library/ms143729(v=sql.110).aspx','Warning','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00316','Use data compression instead of the vardecimal compression feature','The vardecimal storage format is deprecated and will be removed in a future version of Microsoft SQL Server.','We recommend that you use SQL Server 2012 data compression instead of the vardecimal storage format. SQL Server 2012 data compression, compresses decimal values as well as other data types.   Avoid using the vardecimal storage format feature in new development work, and plan to modify applications that currently use this feature. ','http://technet.microsoft.com/en-us/library/ms143729.aspx','Warning','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00317','Inline XDR Schema Generation is deprecated','The XMLDATA directive to the FOR XML option is deprecated. The XMLDATA directive in FOR XML returns an inline XDR schema together with the query result. However, the XDR schema does not support all the new data types and other enhancements introduced in SQL Server 2005.','Use XSD generation in the case of RAW and AUTO modes. There is no replacement for the XMLDATA directive in EXPLICIT mode. You can also request an inline XSD schema by using the XMLSCHEMA directive.','Inline XDR Schema Generation - http://msdn.microsoft.com/en-us/library/ms178035(v=SQL.105).aspx','Not Provided','Not Provided','100')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00318','FOR BROWSE is not allowed in views in 90 or later compatibility modes','The FOR BROWSE clause is allowed (and ignored) in views when the database compatibility mode is set to 80. The FOR BROWSE clause is not allowed in views when the database compatibility mode is set to 90 or later.','Before you change the database compatibility mode to 90 or later, remove the FOR BROWSE clause from view definitions.','Not Provided','Not Provided','BreakingChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00319','SERVERPROPERTY(''LCID'') result differs from SQL 2000','In SQL Server 2000, when SERVERPROPERTY(LCID) is run on binary collation servers, the function always returns a value of 33280, regardless of the actual collation of the server. In SQL Server 2005 or later versions, SERVERPROPERTY(LCID) returns the Windows locale identifier (LCID) that corresponds to the collation of the server.','This can be a consideration when upgrading from SQL Server 2000 to higher versions.','International Features in Microsoft SQL Server 2000 - http://technet.microsoft.com/en-us/library/aa902644.aspx','Not Provided','BehaviorChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00321','Non ANSI style left outer join usage','Will not work in compatibility levels 90+','Refactor to use ANSI syntax (LEFT OUTER JOIN).','Not Provided','BreakingChange','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00322','Non ANSI style right outer join usage','Will not work in compatibility levels 90+','Refactor to use ANSI syntax (RIGHT OUTER JOIN).','Not Provided','BreakingChange','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00323','Numbered Procedures are deprecated','Numbered procedures are deprecated in SQL Server 2005 and above. Use of numbered procedures is discouraged.','Do not use numbered stored procedures.','http://msdn.microsoft.com/en-us/library/ms179865(v=SQL.90).aspx','Error','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00325','ORDER BY specifies integer ordinal','This rule checks stored procedures, functions, views and triggers for use of ORDER BY clause specifying ordinal column numbers as sort columns. A sort column can be specified as a nonnegative integer representing the position of the name or alias in the select list, but this is not recommended. An integer cannot be specified when the order_by_expression appears in a ranking function. A sort column can include an expression, but when the database is in SQL 90 compatibility mode or higher, the expression cannot resolve to a constant.','Specify the sort column as a name or column alias rather than hard coding the ordinal.','Bad habits to kick : ORDER BY ordinal - http://sqlblog.com/blogs/aaron_bertrand/archive/2009/10/06/bad-habits-to-kick-order-by-ordinal.aspx  DISCLAIMER: Third-party link provided as-is and Microsoft does not offer any guarantees or warranties regarding the content on the third party site.','BehaviorChange','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00326','Constant expressions are not allowed in the ORDER BY clause in 90 or later compatibility modes','Constant expressions are allowed (and ignored) in the ORDER BY clause when the database compatibility mode is set to 80 and earlier. However, these expressions in the ORDER BY clause will cause the statement to fail when the database compatibility mode is set to 90 or later.  Here is an example of such problematic statements:  SELECT * FROM Production.Product ORDER BY CASE WHEN  1=2 THEN 3 ELSE 2 END','Before you change the database compatibility mode to 90 or later, modify statements that use constant expressions in the ORDER BY clause to use a column name or column alias, or a nonnegative integer representing the position of the name or alias in the select list.','Not Provided','BreakingChange','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00327','ORDER BY clauses in view','The ORDER BY clause is not valid in views, inline functions, derived tables, and subqueries, unless the TOP or OFFSET and FETCH clauses are also specified. When ORDER BY is used in these objects, the clause is used only to determine the rows returned by the TOP clause or OFFSET and FETCH clauses. The ORDER BY clause does not guarantee ordered results when these constructs are queried, unless ORDER BY is also specified in the query itself.','Specify the ORDER BY clause only in the outermost query and not inside views.','http://support.microsoft.com/kb/926292 http://blogs.msdn.com/b/queryoptteam/archive/2006/03/24/560396.aspx http://connect.microsoft.com/SQLServer/feedback/details/249248/management-studio-generates-invalid-top-100-percent-order-by-in-views','Error','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00328','SET ROWCOUNT used in context of an INSERT / UPDATE / DELETE','Using SET ROWCOUNT will not affect DELETE, INSERT, and UPDATE statements in the next release of SQL Server. Avoid using SET ROWCOUNT with DELETE, INSERT, and UPDATE statements in new development work, and plan to modify applications that currently use it.','Use the TOP clause instead.','SET ROWCOUNT (Transact-SQL) - http://msdn.microsoft.com/en-us/library/ms188774.aspx','BehaviorChange','Not Provided','130')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00329','VARCHAR / NVARCHAR declared without size specification','When you use data types of variable length such as VARCHAR, NVARCHAR, it is always recommended to explicitly specify the size. Failure to do so means that SQL will select the size for you, either 1 (when declaring parameters) or 30 (when converting) characters. ','Explicitly specify the size in all conditions.','http://connect.microsoft.com/SQL/feedback/ViewFeedback.aspx?FeedbackID=244395 http://connect.microsoft.com/SQL/feedback/ViewFeedback.aspx?FeedbackID=267605','Warning','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00330','Statements without semicolon','Although the semicolon is not required for most statements in this version of SQL Server, it will be required in a future version.','For future compatibility please terminate all T-SQL statements with a semicolon.','http://msdn.microsoft.com/en-us/library/ms177563.aspx','Info','Not Provided','Future')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00332','FASTFIRSTROW table hint usage','The usage of FASTFIRSTROW as a table hint has been disallowed in SQL 2012.','We recommend that hints be used only as a last resort by experienced developers and database administrators. Specifically for FASTFIRSTROW hint, you can evaluate the query hint OPTION (FAST 1) instead.','Discontinued Database Engine Functionality in SQL Server 2016 - http://technet.microsoft.com/en-us/library/ms144262.aspx Table Hints - https://technet.microsoft.com/en-us/library/ms187373(v=sql.105).aspx','BreakingChange','Not Provided','110')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00333','Unqualified Joins','Starting with database compatibility level 90 and higher, in rare occasions, the unqualified join syntax can cause missing join predicate warnings, leading to long running queries.','The usage of explicit JOIN syntax is recommended in all cases.','Missing join Predicate Event Class - http://msdn.microsoft.com/en-us/library/ms175146.aspx Deprecation of Old Style JOIN Syntax: Only A Partial Thing - http://blogs.technet.com/b/wardpond/archive/2008/09/13/deprecation-of-old-style-join-syntax-only-a-partial-thing.aspx DOC : Please strive to use ANSI-style joins instead of deprecated syntax  - https://connect.microsoft.com/SQLServer/feedback/details/496012/doc-please-strive-to-use-ansi-style-joins-instead-of-deprecated-syntax Missing join predicate icon should be red - https://connect.microsoft.com/SQLServer/feedback/details/543235/missing-join-predicate-icon-should-be-red ','BehaviorChange','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00334','Objects have been identified that XML FOR EXPLICIT clause','Avoid using FOR XML EXPLICIT in Microsoft SQL Server 2005 or SQL Server 2008. Using FOR XML TYPE, PATH will generally provide more compact and maintainable code. In addition, it will typically perform better.   In SQL Server 2000, there is no alternative to FOR XML EXPLICIT.','SQL Server 2005 XML generation should be coded using FOR XML TYPE, PATH. However, FOR XML EXPLICIT should be used only in rare situations when it provides better performance and more compact code. ','Not Provided','Info','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00335','FOR XML AUTO queries return derived table references in 90 or later compatibility modes','When the database compatibility level is set to 90 or later, FOR XML queries that execute in AUTO mode return references to derived table aliases. When the compatibility level is set to 80, FOR XML AUTO queries return references to the base tables that define a derived table. For example, the following query, which includes a derived table, produces different results under compatibility levels 80, 90, or later:  SELECT * FROM     (SELECT a.id AS a, b.id AS b      FROM Test a JOIN Test b ON a.id=b.id) AS DerivedTest FOR XML AUTO;  Under compatibility level 80, the query returns the following results. The results reference the base table aliases a and b of the derived table instead of the derived table alias.  a=1 b=1 a=2 b=2  Under compatibility level 90 or later, the query returns references to the derived table alias DerivedTest instead of to the derived tables base tables.  DerivedTest a=1 b=1 DerivedTest a=2 b=2','Modify your application as required to account for the changes in results of FOR XML AUTO queries that include derived tables and that run under compatibility level 90 or later.','Not Provided','Not Provided','BehaviorChange','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00336','Certain XPath functions are not allowed in OPENXML queries','MSXML 3.0 is now the underlying engine used to process XPath expressions that are used within OPENXML queries. MSXML 3.0 has a stricter XPath 1.0 engine in which support for the following functions has been removed:  format-number()  formatNumber()  current() element-available() function-available() system-property() ','In the case of format-number() and formatNumber(), you can use Transact-SQL. For the other unsupported functions listed earlier, there is no direct workaround.','NamedTableReference Class - http://go.microsoft.com/fwlink/?LinkID=703890','BreakingChange','Not Provided','90')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('Microsoft.Rules.Data.Upgrade.UR00337','Upgrade for memory optimized tables requires extra disk space when upgrading from SQL Server 2014 to SQL Server 2016.','The format of the data files for memory-optimized tables changes between SQL Server 2014 and SQL Server 2016. This impacts in-place upgrade, as well as attach/restore of a database from SQL Server 2014 DB to SQL Server 2016. When upgrading or attaching a SQL Server 2014 database that uses in-memory optimized tables, SQL Server will temporary require extra disk equal to the size of all the durable memory optimized tables in this database.','Ensure there is sufficient space on disk to store the existing database plus additional storage equal to the current size of the containers in the MEMORY_OPTIMIZED_DATA filegroup in the database to perform an in-place upgrade, or when attaching or restoring a SQL Server 2014 database to a SQL Server 2016 instance. Use the following query to determine the disk space currently required for the MEMORY_OPTIMIZED_DATA filegroup, and consequently also the amount of free disk space required for upgrade to succeed:  select cast(sum(size) as float)*8/1024/1024 size in GB from sys.database_files where data_space_id in (select data_space_id from sys.filegroups where type=NFX)','Memory-Optimized Tables - http://go.microsoft.com/fwlink/?LinkID=717919&clcid=0x409 Creating and Managing Storage for Memory-Optimized Objects - http://go.microsoft.com/fwlink/?LinkID=717927&clcid=0x409','BehaviorChange','Not Provided','120')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('46010','One or more objects contain statements that are not supported in Azure SQL Database','While assessing the schema on the source database, one or more syntax issues were found. Syntax issues on the source database indicate that some objects contain syntax that is unsupported in Azure SQL Database.','Note that some of these syntax issues may be reported in more detail as separate issues in this assessment.  Review the list of objects and issues reported, fix the syntax errors, and re-run assessment before migrating this database.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('46022','FASTFIRSTROW is not a recognized table or a view hint','Not Provided','Not Provided','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('70504','References to only one-part or two-part objects are supported in Azure SQL Database','Queries or references using three or four part names are not supported in Azure SQL Database.  Three part name format, [database_name].[schema_name].[object_name], is supported only when the database_name is the current database or the database_name is tempdb and the object_name starts with #.','Move the dependent datasets from other databases into the database that is being migrated.  Migrate the dependent database(s) to Azure and use "Elastic Database Query" functionality to query across Azure SQL databases.','Azure SQL Database elastic database query overview - https://go.microsoft.com/fwlink/?linkid=838297','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('70527','One or more users are pointing to wrong Windows logins','The assessment detected users with user names that do not match their login names.','Ensure that the user and login names match for the users reported in the "Impacted objects" section.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('70557','Failed to load the assembly','The assembly is either corrupt or not valid, which may block you from migrating to Azure SQL Database.','The assembly is either corrupt or not valid.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('70590','Undeclared variables or parameters found','Objects were found that have statements referencing undeclared variables or parameters. These objects may block you from migrating to Azure SQL Database.','The "Impacted objects" and "Object details" sections provide the specific object names and references where the undeclared variables or parameters are used.  Declare those variables and parameters and re-execute the assessment for any further issues.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('70593','REVOKE object permissions statement is not supported in Azure SQL Database','The REVOKE statement helps to revoke permissions on a table, view, table-valued function, stored procedure, extended stored procedure, scalar function, aggregate function, service queue, or synonym.  Revoking some of these object permissions may not supported in Azure SQL Database.','The specific object names and associated REVOKE statements are provided in the "Impacted objects" and "Object details" sections.  Please review and fix those objects before migrating to Azure SQL Database.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71501','Unresolved references found','One or more objects were found that contain unresolved references, which may block migration to Azure SQL Database.','Address the unresolved references reported in "Object details" section.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71501','One or more database options set on this database are not supported in Azure SQL Database','Database options that have unresolved references may block database migration to Azure SQL Database.','Address the unresolved reference that the database options contain, reported in the "Object details" section.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71501','Logins mapped to either certificate or asymmetric key are not supported in Azure SQL Database','Azure SQL Database supports two types of authentication: SQL Authentication, which uses a username and password. Azure Active Directory Authentication, which uses identities managed by Azure Active Directory and is supported for managed and integrated domains','Windows authentication (integrated security) is not supported in Azure SQL Database.  Database users mapped to Windows logins not supported.  Remove the reported unsupported users before migration and start using either SQL Authentication or Azure Active Directory Authentication after migrating to Azure SQL Database.  Logins mapped to either certificate or asymmetric key are also not supported.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71561','Objects found containining references to unresolved objects, which are not supported in Azure SQL Database','Queries or references using three-or four-part names not supported in Azure SQL Database.  Three-part name format, [database_name].[schema_name].[object_name], is supported only when the database_name is the current database or the database_name is tempdb and the object_name starts with #.','Move the dependent datasets from other databases into the database that is being migrated.  Migrate the dependent database(s) to Azure and use "Elastic Database Query" functionality to query across Azure SQL databases.','Azure SQL Database elastic database query overview - https://go.microsoft.com/fwlink/?linkid=838297','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71562','Cross database queries using three- or four-part names not supported in Azure SQL Database','Queries or references using three- or four-part names not supported in Azure SQL Database.  Three-part name format, [database_name].[schema_name].[object_name], is supported only when the database_name is the current database or the database_name is tempdb and the object_name starts with #.','Move the dependent datasets from other databases into the database that is being migrated.  Migrate the dependent database(s) to Azure and use "Elastic Database Query" functionality to query across Azure SQL databases.','Azure SQL Database elastic database query overview - https://go.microsoft.com/fwlink/?linkid=838297','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71624','Granting CONNECT permission to the guest user in Azure SQL Database is not permitted','In SQL Server, a special user, guest, exists to permit access to a database for logins that are not mapped to a specific database user. When guest user is enabled and connect permissions granted, any login can use the database through the guest user.','Granting CONNECT permission to the guest user in Azure SQL Database is not permitted.  Revoke CONNECT permission from GUEST user by executing "REVOKE CONNECT FROM GUEST" before migrating to Azure SQL Database.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71626','One or more SQL Server or database features are not supported in Azure SQL Database','These unsupported features may block migration to Azure SQL Database.','These unsupported features may block migration to Azure SQL Database platform.  Review the "Impacted Objects" and "Object Details" sections for the specific object type, object and error details, fix the object and re-execute the assessment.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71626','Service Broker feature is not supported in Azure SQL Database','SQL Server Service Broker provides native support for messaging and queuing applications in the SQL Server Database Engine.','Service Broker feature is not supported in Azure SQL DB. You need to disable the Service Broker feature using the following command before migrating this database to Azure: ALTER DATABASE [database_name] SET DISABLE_BROKER; In addition, you may also need to remove or stop the Service Broker endpoint in order to prevent messages from arriving in the SQL instance.  Once the database has been migrated to Azure, you can look into Azure Service Bus functionality to implement a generic, cloud-based messaging system instead of Service Broker.','Service Bus - https://go.microsoft.com/fwlink/?linkid=838769','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71627','Detected one or more features unsupported or partially-supported by Azure SQL Database','These unsupported features may block migration to Azure SQL Database.','Review the "Impact Object" and "Object Details" sections for the specific object type, object and error details, fix the object and re-execute the assessment.','Not Provided','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71627','CLR Assemblies not supported in Azure SQL Database','CLR integration lets you create a user-defined function in SQL Server. A user-defined function is a Transact-SQL or common language runtime (CLR) routine that accepts parameters, performs an action, such as a complex calculation, and returns the result of that action as a value.','Azure SQL Database does not allow creation of a managed application module that contains class metadata and managed code as an object in an instance of SQL Server. If you are relying on this feature, you will need to bring the functional logic used in CLR either to application layer or into stored procedures which will require re-engineering.','Securing your SQL Database - https://go.microsoft.com/fwlink/?linkid=838287','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71627','Database users mapped with Windows authentication (integrated security) not supported in Azure SQL Database','Azure SQL Database supports two types of authentication: SQL Authentication, which uses a username and password. Azure Active Directory Authentication, which uses identities managed by Azure Active Directory and is supported for managed and integrated domains.','Windows authentication (integrated security) is not supported in Azure SQL Database.  Database users mapped to Windows logins not supported.  Remove the reported unsupported users before migration and start using either SQL Authentication or Azure Active Directory Authentication after migrating to Azure SQL Database.  Logins mapped to either certificate or asymmetric key are also not supported.','Securing your SQL Database - https://go.microsoft.com/fwlink/?linkid=838293','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71630','FILESTREAM not supported in Azure SQL Database','The FILESTREAM feature, which allows you to store unstructured data such as text documents, images, and videos in NTFS file system, is not supported in Azure SQL Database.','Upload the unstructured files to Azure Blob storage and store metadata related to these files (name, type, URL location, storage key etc.) in Azure SQL DB.  You may have re-engineer your application to enable streaming blobs to and from Azure SQL Database.','Streaming Blobs To and From SQL Azure - https://go.microsoft.com/fwlink/?linkid=838302','High','MigrationBlocker','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('ec6216d1-a7cc-410c-b32a-257435d8428b','Failover clustering is not supported for Azure SQL Database; instead use Active Geo-Replication','Azure SQL Database provides "Active Geo-Replication" for business continuity. Failover clustering is not supported and not needed.','Configure "Active Geo-Replication", which enables you to configure up to four readable secondary databases in the same or different data center locations (regions).','Overview: SQL Database Active Geo-Replication - https://go.microsoft.com/fwlink/?linkid=838270','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('2115f3b7-ac26-444e-818c-c98f00cf8688','Buffer pool extension is not supported in Azure SQL Database','The buffer pool extension feature can be used to significantly improve I/O throughput of your on-premises SQL Server.  Buffer pool extension is not supported in Azure SQL Database','When migrating your database from an on-premises solution to Azure SQL Database, one important factor is to consider the performance, which takes into account CPU utilization, disk I/O and memory constraints.  Consider "Premium service" tier to support database workloads with higher-end throughput needs.  Scale out Azure SQL databases using the Elastic database pools.','SQL Database service tiers for single databases and elastic database pools - https://go.microsoft.com/fwlink/?linkid=838282','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('be3c796a-a13f-40ad-94e1-8d9b44132268','Database Mail feature not available in Azure SQL Database','This server uses the Database Mail feature, which is not supported in Azure SQL Database.','The following workaround can be used:  Make sure the existing code using Database Mail is compatible with Azure SQL Database. Change the system stored procedures to make them run on Azure SQL DB. Consider only the most common stored procedures. All others, if necessary, may be ported in the same way.  Mail feature may be used at the database monitoring level for: availability, mirroring, replication, throttling, size, user a/c, usage, read/write IOPS, CPV utilization, memory utilization, or session and work content.  It may be used at the table level for monitoring updates, inserts, deletes, etc.','Not Provided','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('42a9d3c2-6db2-455d-adb2-9cdfa1838550','Server scoped credentials not supported in Azure SQL Database; convert to database credential','A credential is a record that contains the authentication information (credentials) required to connect to a resource outside SQL Server.  Azure SQL Database supports database credentials, but not the ones created at the SQL server scope.','Azure SQL Database supports database credentials. Convert server scoped credentials to database credentials.','CREATE DATABASE SCOPED CREDENTIAL (Transact-SQL) - https://go.microsoft.com/fwlink/?linkid=838290','Medium','PartiallySupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('40854749-5ee4-4b2f-9b67-150b945d67bb','Use Azure SQL Database audit features to replace Server Audits','Auditing an instance of the SQL Server Database Engine or an individual database involves tracking and logging events that occur on the Database Engine. SQL Server audit lets you create server audits, which can contain server audit specifications for server level events, and database audit specifications for database level events.','Consider Azure SQL Database audit features to replace Server Audits.  Azure SQL supports audit and the features are richer than SQL Server.  Azure SQL can audit various database actions and events, including:  Access to data Schema changes (DDL)  Data changes (DML) Accounts, roles, and permissions (DCL)  Security exceptions SQL Database Auditing increases an organizations ability to gain deep insight into events and changes that occur within their SQL database, including updates and queries against the data.    ','Get started with SQL database auditing - https://go.microsoft.com/fwlink/?linkid=838299','Medium','PartiallySupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('133db418-a085-4566-9eb8-4dd73f3627ce','Review the maintenance plans still required after migrating to Azure SQL Database','SQL Server maintenance plans are used to automate various database administration tasks, including backups, database integrity checks, or database statistics updates, at specified intervals.','Maintenance plans are not supported in Azure SQL Database. However, most of the key maintenance activities are automatically taken care of by the Azure platform (like backup, etc).  Any maintenance activities not covered as part of the Azure platform can be achieved through the Azure Automation service or elastic jobs.','Microsoft Azure Automation - https://go.microsoft.com/fwlink/?linkid=838279,   Elastic Database jobs - https://go.microsoft.com/fwlink/?linkid=838284      ','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('b6d2746e-7de3-4c80-b632-e427e33f45f7','SSIS is not supported in Azure SQL Database; leverage Azure Data Factory for ETL solutions','Microsoft Integration Services is a platform for building enterprise-level data integration and data transformation solutions.  SSIS is not supported by the Azure SQL Database platform.','Use Azure Data Factory, a cloud-based data integration service that automates the movement and transformation of data. The Data Factory service creates data integration solutions that can ingest data from various stores, transform and process the data, and publish the result data back to the data stores.','Azure Data Factory Documentation - https://go.microsoft.com/fwlink/?linkid=838291','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('d6fadcc4-9a72-4846-bda8-621882abb98e','Azure SQL Database doesnt support Analysis Services; migrate to Azure Analysis Services','Microsoft SQL Server Analysis Services (SSAS) is an online analytical processing (OLAP), data mining and reporting tool in Microsoft SQL Server. SSAS is used as a tool by organizations to analyze and make sense of information that might be spread out across multiple databases or in disparate tables.','Migrate to Azure Analysis Services, which is compatible with the SQL Server 2016 Analysis Services Enterprise Edition. Azure Analysis Services supports tabular models at the 120 compatibility level. DirectQuery, partitions, row-level security, bi-directional relationships, and translations are all supported.','What is Azure Analysis Services? - https://go.microsoft.com/fwlink/?linkid=838298','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('e37e2d14-3a15-4968-9d38-6a422ccc92a7','SQL Server Reporting Services is not supported in Azure SQL Database','SQL Server Reporting Services is a solution that customers deploy on their own premises for creating, publishing, and managing reports, then delivering them to the right users in different ways, whether thats viewing them in web browser, on their mobile device, or as an email in their inbox.','Install Reporting Services and Reporting services databases on an Azure virtual machine.  Use Azure SQL Database as the data source.','SQL Azure Connection Type (SSRS) - https://go.microsoft.com/fwlink/?linkid=838277','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('42e80fd0-658e-4fa5-9c48-0ee780953068','Azure SQL Database does not support trace flags','Trace flags are used to temporarily set specific server characteristics or to switch off a particular behavior.  Trace flags are frequently used to diagnose performance issues or to debug stored procedures or complex computer systems','Choose the right SQL Database service tiers and performance level for single databases and elastic databases that match your workloads.','Not Provided','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('841d0408-a361-4a3f-833e-ce8ce3aada1b','Server-scoped or logon triggers not supported in Azure SQL Database','A trigger is a special kind of stored procedure that executes in response to certain action on a table like insertion, deletion or updating of data.  Server-scoped or logon triggers are not supported in Azure SQL Database.  Azure does not support the following options for triggers:  ENCRYPTION WITH APPEND NOT FOR REPLICATION EXTERNAL NAME option (there is no external method support) ALL SERVER Option (DDL Trigger) Trigger on a LOGON event (Logon Trigger) Azure does not support CLR-triggers. ','If you already have a Worker Role or VM running in Azure, you can implement the trigger logic to be run using the machines task scheduler.','Not Provided','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('e3b10fc1-125f-4ce7-8cfb-aefe89427f8b','Policy-Based Management is not available in Azure SQL Database','Policy-Based Management is a policy-based system for managing one or more instances of SQL Server. It is used to create conditions that contain condition expressions and then create policies that apply the conditions to database target objects.','Use PowerShell automation to implement the policy-based database management. Due to the Azure cloud environment, the Custom implementation is only available at the database level, not the server level.','PowerShell - Azure Automation - https://go.microsoft.com/fwlink/?linkid=838285','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('1e9ccd7a-e148-4810-864f-37dcb5c7ae71','Adding user-defined error messages is not supported in Azure SQL Database','The sp_addmessage system stored procedure lets you add error messages to SQL Server that can be referenced in code. This is helpful for standardized error messages that will be used throughout your application, especially if they need to be able to support multiple languages, but not so much for ad-hoc error messages.  But this feature is not supported in Azure SQL Database.','USE RAISEERROR statement to build a message dynamically.','RAISERROR (Transact-SQL) - https://go.microsoft.com/fwlink/?linkid=838295','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('230121ee-a864-4c87-bf9e-6914d928d358','Data Collection not supported in Azure SQL','The data collector is a component of SQL Server that collects different sets of data. Data collection either runs constantly or on a user-defined schedule. The data collector stores the collected data in a relational database known as the management data warehouse.','Use query store to check and collect the performance level details.','Monitoring Performance By Using the Query Store - https://go.microsoft.com/fwlink/?linkid=838301','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('bce58720-8f42-4bea-9483-a60c555dd484','Windows authentication not supported in Azure SQL Database','This server is in Windows authentication mode, and Windows authentication is not supported in SQL Azure.','Due to Azure SQL Databases cloud architecture, any Windows authentication used in a source database should be handled using SQL Azure.  Azure SQL Database supports Azure Active Directory or SQL Azure authentication.  If considering using Azure Active Directory, make sure Azure Active Directory is well configured, or else use SQL Azure authentication.','SQL Database Authentication and Authorization: Granting Access - https://go.microsoft.com/fwlink/?linkid=838280','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('1f6e088b-1e9b-4ff6-b43e-a5f2c01fe486','Azure SQL Database does not support EKM and Azure Key Vault integration','SQL Server provides several types of encryption that help protect sensitive data, including Transparent Data Encryption (TDE), Column Level Encryption (CLE), and Backup Encryption. In all of these cases, in this traditional key hierarchy, the data is encrypted using a symmetric data encryption key (DEK). The symmetric data encryption key is further protected by encrypting it with a hierarchy of keys stored in SQL Server. Instead of this model, the alternative is the EKM Provider Model. Using the EKM provider architecture enables SQL Server to protect the data encryption keys by using an asymmetric key stored outside of SQL Server in an external cryptographic provider. This model adds an additional layer of security and separates the management of keys and data.','Azure SQL Database does not support Azure Key Vault integration with TDE. SQL Server running on an Azure virtual machine can use an asymmetric key from the Key Vault.','Not Provided','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('71715af6-45d8-4ebd-bf28-508644f4fc2b','SQL Server Agent jobs are not available in Azure SQL Database','SQL Server Agent is a Microsoft Windows service that executes scheduled administrative tasks, which are called jobs in SQL Server.','Use elastic jobs, which are the replacement for SQL Server Agent jobs in Azure SQL Database.  Elastic Database jobs for Azure SQL Database allows you to reliably execute T-SQL scripts that span multiple databases while automatically retrying and providing eventual completion guarantees.','Getting started with Elastic Database jobs - https://go.microsoft.com/fwlink/?linkid=838286','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('6c20cbe5-67c5-4951-a318-624292da8d75','Always On Availability group configuration is not supported for Azure SQL databases','Azure SQL Database provides "Active Geo-Replication" for business continuity. Always On Availability groups not supported and not needed.','Configure "Active Geo-Replication", which enables you to configure up to four readable secondary databases in the same or different data center locations (regions).','Overview: SQL Database Active Geo-Replication - https://go.microsoft.com/fwlink/?linkid=838294','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('675d900d-739a-4f79-909b-115d028e3e45','FILESTREAM not supported in Azure SQL Database','The FILESTREAM feature, which allows you to store unstructured data such as text documents, images, and videos in NTFS file system, is not supported in Azure SQL Database.','Upload the unstructured files to Azure Blob storage and store metadata related to these files (name, type, URL location, storage key etc.) in Azure SQL DB.  You may have re-engineer your application to enable streaming blobs to and from Azure SQL Database.       ','Streaming Blobs To and From SQL Azure - https://go.microsoft.com/fwlink/?linkid=838300','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('80621881-ed14-44fa-a770-46e29b03d803','Full-text search partially supported in Azure SQL Database','Text Search lets users and applications run full-text queries against character-based data in SQL Server tables.','Azure SQL Database supports full-text search with the following limitations. Any of the below used in a source database should be handled separately.  1. No support for installation or use of third party filters, including Office and .pdf.  2. Customers cannot manage service settings for dots; all configurations are managed by the service.  3. Semantic search, thesaurus and search property lists syntax is not yet enabled.','Full-Text Search is now available in Azure SQL Database (GA) - https://go.microsoft.com/fwlink/?linkid=838278','Medium','PartiallySupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('4335a2eb-3164-438f-aaa0-588a04057854','Change Data Capture (CDC) is not supported in Azure SQL Database','Change data capture is designed to capture insert, update, and delete activity applied to SQL Server tables, and to make the details of the changes available in an easily consumed relational format.','Change Data Capture (CDC) is not supported in Azure SQL Database.  Evaluate if Change Tracking can be used in place of CDC as explained in the article below.','How to Enable SQL Azure Change Tracking - https://go.microsoft.com/fwlink/?linkid=838289','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('7c49ee7a-ebbb-4f79-bb1c-1eb0ac249ecd','Log shipping is not available in Azure SQL Database; instead, configure Active Geo-Replication','Log shipping provides a disaster-recovery solution for a single primary database and one or more secondary databases, each on a separate instance of SQL Server.','Configure Active Geo-Replication, which enables you to configure up to four readable secondary databases in the same or different data center locations (regions). Secondary databases are available for querying and for failover in the case of a data center outage or the inability to connect to the primary database. Active Geo-Replication must be between databases within the same subscription.','Overview: SQL Database Active Geo-Replication - https://go.microsoft.com/fwlink/?linkid=838296','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('c99f9cfa-2766-4096-aa50-1553033b67ce','Database mirroring is not available in SQL Azure database; instead, configure Active Geo-Replication','Database mirroring is a solution for increasing the availability of a SQL Server database. Mirroring is implemented on a per-database basis and works only with databases that use the full recovery model.','Configure Active Geo-Replication, which enables you to configure up to four readable secondary databases in the same or different data center locations (regions). Secondary databases are available for querying and for failover in the case of a data center outage or the inability to connect to the primary database. Active Geo-Replication must be between databases within the same subscription.','Overview: SQL Database Active Geo-Replication - https://go.microsoft.com/fwlink/?linkid=838281','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('373e516d-5b36-4e83-ba42-0358990b973d','Transactional replication to Azure SQL Database subscriber is supported','Replication is a set of technologies for copying and distributing data and database objects from one database to another and then synchronizing between databases to maintain consistency. Using replication, you can distribute data to different locations and to remote or mobile users over local and wide area networks, dial-up connections, wireless connections, and the Internet','Your database is identified to be part of a replication topology. Publishers and Distributors of a replication topology are not supported in Azure SQL DB. However, if your database is serving as a Subscriber, you can configure Azure SQL DB as a Subscriber of an on-prem SQL Server Transactional Replication topology.','Transactional Replication to Azure SQL DB now in public preview - https://go.microsoft.com/fwlink/?linkid=838288','Medium','PartiallySupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('3946bb88-cf72-45b2-a690-e433b3848968','Service Broker feature is not supported in Azure SQL Database','SQL Server Service Broker provides native support for messaging and queuing applications in the SQL Server Database Engine.','Service Broker feature is not supported in Azure SQL DB. You need to disable Service Broker using the following command before migrating this database to Azure:  ALTER DATABASE [database_name] SET DISABLE_BROKER;  In addition, you may also need to remove or stop the Service Broker endpoint in order to prevent messages from arriving in the SQL instance.  Once the database has been migrated to Azure, you can look into Azure Service Bus functionality to implement a generic, cloud-based messaging system instead of Service Broker.','Service Bus - https://go.microsoft.com/fwlink/?linkid=838769','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('2292dd65-0a5d-40e0-abc9-d08f06300fb0','Cross-database references not supported in Azure SQL Database','Some selected databases on this server use cross-database queries, which are not supported in Azure SQL Database.','Azure SQL Database does not support cross-database queries. The following actions are recommended:  Move the dependent datasets from other databases into the database that is being migrated.  Migrate the dependent database(s) to Azure and use "Elastic Database Query" functionality to query across Azure SQL databases.','Azure SQL Database elastic database query overview - https://go.microsoft.com/fwlink/?linkid=838297','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('2655f11e-1686-476a-8274-3ccfd59ec0ff','Linked server functionality not supported in Azure SQL Database','Linked servers enable the SQL Server Database Engine to execute commands against OLE DB data sources outside of the instance of SQL Server.','Azure SQL DB does not support linked server functionality. The following actions are recommended to eliminate the need for linked servers:  1. Identify the dependent datasets from remote SQL servers and consider moving these into the database being migrated.  2. Migrate the dependent database(s) to Azure and use "Elastic Database Query" functionality to query across Azure SQL databases.','Cross-Database Queries in Azure SQL Database - https://go.microsoft.com/fwlink/?linkid=838276','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('8c0d645d-0390-42e5-bff6-faebaefada2f','Unsupported object types detected','Unsupported object types in the schema may prevent you migrating to Azure SQL Database.','Objects of types "Replication filter stored procedure", "Service queue", "Extended stored procedure", etc., are not supported in Azure SQL Database.  For a complete list, please refer to the link provided in the "More info" section.','sys.objects (Transact-SQL) - https://go.microsoft.com/fwlink/?linkid=838938','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('59cb6f5e-c3db-4a2c-9cda-125c92779f56','Server and database level collations are not configurable in Azure SQL Database','Collations in SQL Server provide sorting rules, case, and accent sensitivity properties for your data. Collations that are used with character data types such as char and varchar dictate the code page and corresponding characters that can be represented for that data type.','Server and database level collations are not configurable in Azure SQL Database. However, you can use a collation of your choice at the column and expression level.  The default collation for character data in Azure SQL databases is SQL_Latin1_General_CP1_CI_AS. Azure SQL Database does not support the Collate option with the Alter Database command. Azure SQL Database does not allow setting the collation at the server level.  To use the non-default collation with Azure SQL Database, set the collation with the Create Database Collate option, or at the column level or the expression level.  For example, you can recreate an Azure SQL Database with the Latin1_General_CI_AS collation. Or you can set the special collation at the column level to build requires for character data. For more information, you can review the following blog.','Working With Collations In SQL Azure - https://go.microsoft.com/fwlink/?linkid=838283','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('fd5a6a79-8c37-4e69-b04f-ef12e9855c19','TRUSTWORTHY database property not supported in Azure SQL Database','The TRUSTWORTHY database property is used to indicate whether the instance of SQL Server trusts the database and the contents within it. By default, this setting is OFF, but can be set to ON by using the ALTER DATABASE statement.','The TRUSTWORTHY database property is not supported in Azure SQL Database.','Not Provided','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('01cbf83f-c83b-42b3-86e1-2558e329142f','DB_CHAINING property not supported in Azure SQL Database','SQL Server can be configured to allow ownership chaining between specific databases or across all databases inside a single instance of SQL Server. Cross-database ownership chaining is disabled by default, and should not be enabled unless it is specifically required.','The DB_CHAINING property is not supported in Azure SQL Database.','Not Provided','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('1ff71a3d-9ede-415b-88aa-ff136020abba','In-memory tables only supported in preview for Premium Azure SQL databases','Some selected databases on this server have in-memory tables.','Azure SQL Database only supports in-memory tables in preview for Premium Azure SQL databases. It is not supported in Basic and Standard tiers.','Not Provided','Medium','PartiallySupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('63544257-802a-433c-914e-b2ef58157898','Table partitioning considerations in Azure SQL Database','The data in partitioned tables and indexes is horizontally divided into units that can be spread across more than one filegroup in a database. Partitioning can make large tables and indexes more manageable and scalable.','Table partitioning exists in Azure SQL Database, but does not scale out across disks (horizontal partitioning of table/index data across multiple file groups to improve performance on large datasets). However, consider premium storage to eliminate the need.','Not Provided','Medium','PartiallySupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('a9ca04ba-9fb5-480f-b351-afc437e4f3e6','File groups not supported in Azure SQL Database','Some selected databases use file groups, which are not supported in Azure SQL Database.','Azure SQL Database doesn"t allow the use of file groups simply because there"s no direct way to replicate their behavior in a cloud environment, where everything is virtualized anyway. If you relied on file groups for physical partitioning of data to gain performance, consider premium storage to eliminate the need.','Not Provided','Medium','UnsupportedFeature','Not Provided')
INSERT INTO dimRules(RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('3dbac490-cdf4-4a12-af2d-671e0f622e12','Not Provided','Not Provided','Not Provided','Not Provided','Medium','UnsupportedFeature','Not Provided')

INSERT INTO dimRules (RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('0eec636c-0620-46df-bdb8-4f1de9954363','Security Advisor AE and DDM','SQL Server 2016 offers new features to help protect columns containing sensitive data.  Always Encrypted (AE) transparently encrypts values client-side, which helps protect sensitive data from unauthorized access by high-privileged database users (such as a DBA). Use Always Encrypted for your highly sensitive data that must be protected with encryption.  Dynamic Data Masking (DDM) transparently masks query results before they are returned by the server, which helps protect sensitive data from unauthorized disclosure to application users. Use Dynamic Data Masking to obfuscate data in your application using a centralized rule within the database itself.  ','You can enable DDM on a column by using the following T-SQL (make sure to substitute in your own values for the table and column names):
ALTER TABLE MyTable
ALTER COLUMN MyColumn
ADD MASKED WITH FUNCTION = ''default()''
GO
Note that additional masking functions are available, including ''email()'', ''random()'' and ''partial()''.  Please see the documentation for more details. 
You can enable AE on a column by using the Always Encrypted Wizard in SQL Server Management Studio:  1. Connect to your database using the Object Explorer of SQL Server Management Studio. 2. Right-click your database, point to Tasks, and then click Encrypt Columns to open the Always Encrypted Wizard.  3. Review the Introduction page, and then click Next.  4. On the Column Selection page, expand the tables, and select the columns that you want to encrypt.  5. For each column selected for encryption, set the Encryption Type to either Deterministic or Randomized. 6. For each column selected for encryption, select an Encryption Key. If you have not previously created an encryption keys for this database, select the default choice of a new auto-generated key, and then click Next. 7. On the Master Key Configuration page, select a location to store the new key. and select a master key source, and then click Next. 8. On the Validation page, choose whether to run the script immediately or create a PowerShell script, and then click Next. 9. On the Summary page, review the options you have selected, and then click Finish. Close the wizard when completed.','To learn more about AE and DDM, please refer to the following articles:  
Always Encrypted - https://go.microsoft.com/fwlink/?LinkId=798974  
Dynamic Data Masking - https://go.microsoft.com/fwlink/?LinkId=798975','Warning','NotDefined','NotDefined')
INSERT INTO dimRules (RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('30120fc5-f00e-4246-a91d-b78fa5461a83','Security Advisor TDE','SQL Server 2016 improves the performance of Transparent Data Encryption (TDE) by up to 70% through hardware acceleration on machines that support the AES-NI instruction set. Consider enabling TDE to encrypt your data at rest.','You can enable TDE on your database by executing the following T-SQL (make sure to substitute in your own values for the master key password, certificate name, and database name):
Create a master key if you don''t have one already
USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD
GO
CREATE CERTIFICATE
WITH SUBJECT ''My DEK Certificate''
GO
Enable TDE in your database
USE MyDatabase
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM AES_256
ENCRYPTION BY SERVER CERTIFICATE MyServerCert 
GO
ALTER DATABASE
MyDatabase
SET ENCRYPTION ON
GO','To learn more about TDE, please refer to the following articles.  
Transparent Data Encryption - https://go.microsoft.com/fwlink/?LinkId=798936','Warning','NotDefined','NotDefined')
INSERT INTO dimRules (RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('StretchDB-High','Stretch database to minimize storage costs','Provides cost-effective availability for cold data.  Stretch warm and cold transactional data dynamically from SQL Server to Microsoft Azure with SQL Server Stretch Database. Unlike typical cold data storage, your data is always online and available to query. You can provide longer data retention timelines without breaking the bank for large tables. Benefit from the low cost of Azure rather than scaling expensive, on-premises storage.','Select each table in the Objects section, look if there are any blocking issues that you need to implement the suggested migration steps to be able to enable the selected table for stretch. If no blocking issues reported, the table is ready to stretch now.  Review the steps in the following article to configure the table for stretch database. https://go.microsoft.com/fwlink/?LinkId=800654','Stretch Database - https://go.microsoft.com/fwlink/?LinkId=800655','Error','NotDefined','NotDefined')
INSERT INTO dimRules (RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('StretchDB-Low','Stretch database for storage savings','Provides cost-effective availability for cold data.  Stretch warm and cold transactional data dynamically from SQL Server to Microsoft Azure with SQL Server Stretch Database. Unlike typical cold data storage, your data is always online and available to query. You can provide longer data retention timelines without breaking the bank for large tables. Benefit from the low cost of Azure rather than scaling expensive, on-premises storage.','Select each table in the Objects section, look if there are any blocking issues that you need to implement the suggested migration steps to be able to enable the selected table for stretch. If no blocking issues reported, the table is ready to stretch now.  Review the steps in the following article to configure the table for stretch database. https://go.microsoft.com/fwlink/?LinkId=800654','Stretch Database - https://go.microsoft.com/fwlink/?LinkId=800655','Information','NotDefined','NotDefined')
INSERT INTO dimRules (RuleID, Title, Impact, Recommendation, MoreInfo, Severity, ChangeCategory, DatabaseCompatibilityLevel) VALUES ('StretchDB-Medium','Stretch database to optimize storage costs','Provides cost-effective availability for cold data.  Stretch warm and cold transactional data dynamically from SQL Server to Microsoft Azure with SQL Server Stretch Database. Unlike typical cold data storage, your data is always online and available to query. You can provide longer data retention timelines without breaking the bank for large tables. Benefit from the low cost of Azure rather than scaling expensive, on-premises storage.','Select each table in the Objects section, look if there are any blocking issues that you need to implement the suggested migration steps to be able to enable the selected table for stretch. If no blocking issues reported, the table is ready to stretch now.  Review the steps in the following article to configure the table for stretch database. https://go.microsoft.com/fwlink/?LinkId=800654','Stretch Database - https://go.microsoft.com/fwlink/?LinkId=800655','Warning','NotDefined','NotDefined')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimRules_RulesKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimRules already exists") -ForegroundColor Yellow
    }

    
    #create dimSeverity
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimSeverity"}
    if(!$tableCheck)
    {            
        $dimSeveritytbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimSeverity")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimSeveritytbl, "Severitykey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimSeveritytbl, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
              
        $dimSeveritytbl.Columns.Add($col1)
        $dimSeveritytbl.Columns.Add($col2)
        
        try
        {        
            $dimSeveritytbl.Create()
            Write-Host ("Table dimSeverity created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table dimSeverity") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimSeveritytbl,"PK_dimSeverity_Severitykey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimSeverity_SeverityKey created successfully") -ForegroundColor Green

            $CommandText = @'
insert into dimSeverity (Severity) VALUES ('NA')
insert into dimSeverity (Severity) VALUES ('Warning')
insert into dimSeverity (Severity) VALUES ('Information')
insert into dimSeverity (Severity) VALUES ('Error')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimSeverity_SeverityKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimSeverity already exists") -ForegroundColor Yellow
    }


    #create dimSourceCompatibility
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimSourceCompatibility"}
    if(!$tableCheck)
    {            
        $dimSourceCompatibilitytbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimSourceCompatibility")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimSourceCompatibilitytbl, "SourceCompatKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimSourceCompatibilitytbl, "SourceCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
               
        $dimSourceCompatibilitytbl.Columns.Add($col1)
        $dimSourceCompatibilitytbl.Columns.Add($col2)
        
        try
        {        
            $dimSourceCompatibilitytbl.Create()
            Write-Host ("Table dimSourceCompatibility created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table dimSourceCompatibility") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimSourceCompatibilitytbl,"PK_dimSourceCompatibility_SourceCompatkey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary key PK_dimSourceCompatibility_SourceCompatKey created successfully") -ForegroundColor Green

            $CommandText = @'
insert into dimSourceCompatibility (SourceCompatibilityLevel) VALUES ('NA')
insert into dimSourceCompatibility (SourceCompatibilityLevel) VALUES ('CompatLevel90')
insert into dimSourceCompatibility (SourceCompatibilityLevel) VALUES ('CompatLevel100')
insert into dimSourceCompatibility (SourceCompatibilityLevel) VALUES ('CompatLevel110')
insert into dimSourceCompatibility (SourceCompatibilityLevel) VALUES ('CompatLevel120')
insert into dimSourceCompatibility (SourceCompatibilityLevel) VALUES ('CompatLevel130')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimSourceCompatibility_SourceCompatKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimSourceCompatibility already exists") -ForegroundColor Yellow
    }


    #create dimStatus
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimStatus"}
    if(!$tableCheck)
    {            
        $dimStatustbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimStatus")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimStatustbl, "StatusKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimStatustbl, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(20))
               
        $dimStatustbl.Columns.Add($col1)
        $dimStatustbl.Columns.Add($col2)
        
        try
        {        
            $dimStatustbl.Create()
            Write-Host ("Table dimStatus created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table dimStatus") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimStatustbl,"PK_dimStatus_Statuskey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimStatus_StatusKey created successfully") -ForegroundColor Green

            $CommandText = @'
insert into dimStatus (Status) VALUES ('NA')
insert into dimStatus (Status) VALUES ('Error')
insert into dimStatus (Status) VALUES ('Completed')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimStatus_StatusKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimStatus already exists") -ForegroundColor Yellow
    }


    #create dimTargetCompatibility
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimTargetCompatibility"}
    if(!$tableCheck)
    {            
        $dimTargetCompatibilitytbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimTargetCompatibility")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimTargetCompatibilitytbl, "TargetCompatKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimTargetCompatibilitytbl, "TargetCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
               
        $dimTargetCompatibilitytbl.Columns.Add($col1)
        $dimTargetCompatibilitytbl.Columns.Add($col2)
        
        try
        {        
            $dimTargetCompatibilitytbl.Create()
            Write-Host ("Table dimTargetCompatibility created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table dimTargetCompatibility") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimTargetCompatibilitytbl,"PK_dimTargetCompatibility_TargetCompatkey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimTargetCompatibility_TargetCompatKey created successfully") -ForegroundColor Green

            $CommandText = @'
insert into dimTargetCompatibility (TargetCompatibilityLevel) VALUES ('NA')
insert into dimTargetCompatibility (TargetCompatibilityLevel) VALUES ('CompatLevel100')
insert into dimTargetCompatibility (TargetCompatibilityLevel) VALUES ('CompatLevel110')
insert into dimTargetCompatibility (TargetCompatibilityLevel) VALUES ('CompatLevel120')
insert into dimTargetCompatibility (TargetCompatibilityLevel) VALUES ('CompatLevel130')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimTargetCompatibility_TargetCompatKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimTargetCompatibility already exists") -ForegroundColor Yellow
    }


    #create dimAssessmentTarget
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimAssessmentTarget"}
    if(!$tableCheck)
    {
        $dimAssessmentTargettbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimAssessmentTarget")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimAssessmentTargettbl, "AssessmentTargetKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimAssessmentTargettbl, "AssessmentTarget", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))

        $dimAssessmentTargettbl.Columns.Add($col1)
        $dimAssessmentTargettbl.Columns.Add($col2)
        
        try
        {
            $dimAssessmentTargettbl.Create()
            Write-Host ("Table dimAssessmentTarget created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host ("Failed to create table dimAssessmentTarget") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimAssessmentTargettbl,"PK_dimAssessmentTarget_AssessmentTargetkey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimAssessmentTarget_AssessmentTargetKey") -ForegroundColor Green

            $CommandText = @'
insert into dimAssessmentTarget (AssessmentTarget) VALUES ('NA')
insert into dimAssessmentTarget (AssessmentTarget) VALUES ('AzureSqlDatabaseV12')
insert into dimAssessmentTarget (AssessmentTarget) VALUES ('SqlServer2012')
insert into dimAssessmentTarget (AssessmentTarget) VALUES ('SqlServer2014')
insert into dimAssessmentTarget (AssessmentTarget) VALUES ('SqlServer2016')
'@
            
            $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
            $conn.Open() | Out-Null

            $cmd = New-Object System.Data.SqlClient.SqlCommand 
            $cmd.Connection = $conn
            $cmd.CommandType = [System.Data.CommandType]"Text"
            $cmd.CommandText= $CommandText
              
            $ds=New-Object system.Data.DataSet
            $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
            $da.fill($ds) | Out-Null
            $conn.Close()
        }
        catch
        {
            write-host("Failed to create primary key PK_dimAssessmentTarget_AssessmentTargetKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimAssessmentTarget already exists") -ForegroundColor Yellow
    }


    #create dimDBOwner
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "dimDBOwner"}
    if(!$tableCheck)
    {
        $dimDBOwnertbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "dimDBOwner")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDBOwnertbl, "DBOwnerKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col1.Nullable = $false
        $col1.Identity = $True
        $col1.IdentityIncrement = 1
        $col1.IdentitySeed = 1
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDBOwnertbl, "InstanceName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDBOwnertbl, "DatabaseName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))        
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($dimDBOwnertbl, "DBOwner", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))

        $dimDBOwnertbl.Columns.Add($col1)
        $dimDBOwnertbl.Columns.Add($col2)
        $dimDBOwnertbl.Columns.Add($col3)
        $dimDBOwnertbl.Columns.Add($col4)
        
        try
        {
            $dimDBOwnertbl.Create()
            Write-Host ("Table dimDBOwner created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host ("Failed to create table dimDBOwner") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($dimDBOwnertbl,"PK_dimDBOwner_DBOwnerkey")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            write-host("Primary Key PK_dimDBOwner_DBOwnerkey") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create primary key PK_dimDBOwner_DBOwnerkey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table dimDBOwner already exists") -ForegroundColor Yellow
    }


    #create FactAssessment
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "FactAssessment"}
    if(!$tableCheck)
    {            
        $FactAssessmenttbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "FactAssessment")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "DateKey", [Microsoft.SqlServer.Management.Smo.DataType]::Int)
        $col1.Nullable = $false
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "StatusKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col2.Nullable = $false
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "SourceCompatKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col3.Nullable = $false
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "TargetCompatKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col4.Nullable = $false
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "Categorykey", [Microsoft.SqlServer.Management.Smo.DataType]::SmallInt)
        $col5.Nullable = $false
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "SeverityKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col6.Nullable = $false
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "ChangeCategorykey", [Microsoft.SqlServer.Management.Smo.DataType]::SmallInt)
        $col7.Nullable = $false
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "RulesKey", [Microsoft.SqlServer.Management.Smo.DataType]::Int)
        $col8.Nullable = $false
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl,  "AssessmentTargetKey", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col9.Nullable = $false
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "ObjectTypeKey", [Microsoft.SqlServer.Management.Smo.DataType]::SmallInt)
        $col10.Nullable = $false
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "DBOwnerKey", [Microsoft.SqlServer.Management.Smo.DataType]::INT) ##this can be nullable
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "InstanceName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "DatabaseName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "SizeMB", [Microsoft.SqlServer.Management.Smo.DataType]::Decimal(2,7))
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "ImpactedObjectName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col16 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col17 = New-Object Microsoft.SqlServer.Management.Smo.Column($FactAssessmenttbl, "AssessmentName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        
         
        $FactAssessmenttbl.Columns.Add($col1)
        $FactAssessmenttbl.Columns.Add($col2)
        $FactAssessmenttbl.Columns.Add($col3)
        $FactAssessmenttbl.Columns.Add($col4)
        $FactAssessmenttbl.Columns.Add($col5)
        $FactAssessmenttbl.Columns.Add($col6)
        $FactAssessmenttbl.Columns.Add($col7)
        $FactAssessmenttbl.Columns.Add($col8)
        $FactAssessmenttbl.Columns.Add($col9)
        $FactAssessmenttbl.Columns.Add($col10)
        $FactAssessmenttbl.Columns.Add($col11)
        $FactAssessmenttbl.Columns.Add($col12)
        $FactAssessmenttbl.Columns.Add($col13)
        $FactAssessmenttbl.Columns.Add($col14)
        $FactAssessmenttbl.Columns.Add($col15)
        $FactAssessmenttbl.Columns.Add($col16)
        $FactAssessmenttbl.Columns.Add($col17)
        
        try
        {
            $FactAssessmenttbl.Create()
            Write-Host ("Table FactAccessmebt created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table FactAssessment") -ForegroundColor Red
            $error[0]|format-list -force
        }
          
        # Create foreign Keys 
         
        # dimCategory FK
        $dimCategoryFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimCategory"  
  
        $dimCategoryFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimCategoryFK, "CategoryKey", "CategoryKey"  
        $dimCategoryFK.Columns.Add($dimCategoryFKc)  

        $dimCategoryFK.ReferencedTable = "dimCategory"  
        $dimCategoryFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimCategoryFK.Create()  
            write-host("Foreign key PK_FactAssessment_dimChangeCategory created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key PK_FactAssessment_dimChangeCategory") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimChangeCategory FK
        $dimChangeCategoryFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimChangeCategory"  
  
        $dimChangeCategoryFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimChangeCategoryFK, "ChangeCategorykey", "ChangeCategorykey"  
        $dimChangeCategoryFK.Columns.Add($dimChangeCategoryFKc)  

        $dimChangeCategoryFK.ReferencedTable = "dimChangeCategory"  
        $dimChangeCategoryFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimChangeCategoryFK.Create() 
            write-host("Foreign key FK_FactAssessment_dimChangeCategory created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimChangeCategory") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimDate FK
        $dimDateFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimDate"  
  
        $dimDateFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimDateFK, "DateKey", "DateKey"  
        $dimDateFK.Columns.Add($dimDateFKc)  

        $dimDateFK.ReferencedTable = "dimDate"  
        $dimDateFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimDateFK.Create() 
            write-host("Foreign key FK_FactAssessment_dimDate created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimDate") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimObjectType FK
        $dimObjectTypeFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimObjectType"  
  
        $dimObjectTypeFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimObjectTypeFK, "ObjectTypeKey", "ObjectTypeKey"  
        $dimObjectTypeFK.Columns.Add($dimObjectTypeFKc)  

        $dimObjectTypeFK.ReferencedTable = "dimObjectType"  
        $dimObjectTypeFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimObjectTypeFK.Create() 
            write-host("Foreign Key FK_FactAssessment_dimObjectType created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimObjectType") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimRules FK
        $dimRulesFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimRules"  
  
        $dimRulesFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimRulesFK, "RulesKey", "RulesKey"  
        $dimRulesFK.Columns.Add($dimRulesFKc)  

        $dimRulesFK.ReferencedTable = "dimRules"  
        $dimRulesFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimRulesFK.Create() 
            write-host("Foreign key FK_FactAssessment_dimRules created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimRules") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimCategory FK
        $dimAssesssmentTargetFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimAssessmentTarget"  
  
        $dimAssesssmentTargetFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimAssesssmentTargetFK, "AssessmentTargetKey", "AssessmentTargetKey"  
        $dimAssesssmentTargetFK.Columns.Add($dimAssesssmentTargetFKc)  

        $dimAssesssmentTargetFK.ReferencedTable = "dimAssessmentTarget"  
        $dimAssesssmentTargetFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimAssesssmentTargetFK.Create()
            write-host("Foreign key FK_FactAssessment_dimAssessmentTarget created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimAssessmentTarget") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimSeverity FK
        $dimSeverityFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimSeverity"  
  
        $dimSeverityFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimSeverityFK, "SeverityKey", "SeverityKey"  
        $dimSeverityFK.Columns.Add($dimSeverityFKc)  

        $dimSeverityFK.ReferencedTable = "dimSeverity"  
        $dimSeverityFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimSeverityFK.Create()
            write-host("Foreign key FK_FactAssessment_dimSeverity created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimSeverity") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimSourceCompatibility FK
        $dimSourceCompatibilityFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimSourceCompatibility"  
  
        $dimSourceCompatibilityFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimSourceCompatibilityFK, "SourceCompatKey", "SourceCompatKey"  
        $dimSourceCompatibilityFK.Columns.Add($dimSourceCompatibilityFKc)  

        $dimSourceCompatibilityFK.ReferencedTable = "dimSourceCompatibility"  
        $dimSourceCompatibilityFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimSourceCompatibilityFK.Create()
            write-host("Foreign key FK_FactAssessment_dimSourceCompatibility created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimSourceCompatibility") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimStatus FK
        $dimStatusFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimStatus"  
  
        $dimStatusFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimStatusFK, "StatusKey", "StatusKey"  
        $dimStatusFK.Columns.Add($dimStatusFKc)  

        $dimStatusFK.ReferencedTable = "dimStatus"  
        $dimStatusFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimStatusFK.Create()
            write-host("Foreign key FK_FactAssessment_dimStatus created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimStatus") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # dimTargetCompability FK
        $dimTargetCompatibilityFK = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKey -argumentlist $FactAssessmenttbl, "FK_FactAssessment_dimTargetCompability"  
  
        $dimTargetCompatibilityFKc = New-Object -TypeName Microsoft.SqlServer.Management.SMO.ForeignKeyColumn -argumentlist $dimTargetCompatibilityFK, "TargetCompatKey", "TargetCompatKey"  
        $dimTargetCompatibilityFK.Columns.Add($dimTargetCompatibilityFKc)  

        $dimTargetCompatibilityFK.ReferencedTable = "dimTargetCompatibility"  
        $dimTargetCompatibilityFK.ReferencedTableSchema = "dbo"  
        
        try
        {
            $dimTargetCompatibilityFK.Create()
            write-host("Foreign key FK_FactAssessment_dimTargetCompatibility created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create foreign key FK_FactAssessment_dimTargetCompatibility") -ForegroundColor Red
            $error[0]|format-list -force
        }



        #create nonclustered indexes on foreign keys
        
        # Create nonclustered index for DateKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_DateKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "DateKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
  
        try
        {
            $idx.Create()  
            write-host("Nonclustered index IX_factAssessment_DateKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_DateKey") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # Create nonclustered index for StatusKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_StatusKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "StatusKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
        
        try
        {
            $idx.Create() 
            write-host("Nonclustered index IX_factAssessment_StatusKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_StatusKey") -ForegroundColor Red
            $error[0]|format-list -force
        }
        
        # Create nonclustered index for SourceCompatKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_SourceCompatKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "SourceCompatKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
        
        try
        {
            $idx.Create() 
            write-host("Nonclustered index IX_factAssessment_SourceCompatKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_SourceCompatKey") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # Create nonclustered index for TargetCompatKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_TargetCompatKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "TargetCompatKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
  
        try
        {
            $idx.Create() 
            write-host("Nonclustered index IX_factAssessment_TargetCompatKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_TargetCompatKey") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # Create nonclustered index for CategoryKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_CategoryKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "CategoryKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
        
        try
        {
            $idx.Create() 
            write-host("Nonclustered index IX_FactAssessment_CategoryKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_FactAssessment_CategoryKey") -ForegroundColor Red
            $error[0]|format-list -force
        }
        
        # Create nonclustered index for SeverityKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_Severitykey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "SeverityKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
  
        try
        {
            $idx.Create() 
            write-host("Nonclustered index IX_factAssessment_SeverityKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_SeverityKey") -ForegroundColor Red
            $error[0]|format-list -force
        }


        # Create nonclustered index for ChangeCategoryKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_ChangeCategoryKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "ChangeCategoryKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
  
        try
        {
            $idx.Create()
            write-host("Nonclustered index IX_factAssessment_ChangeCategoryKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_changeCategorykey") -ForegroundColor Red
            $error[0]|format-list -force
        }


        # Create nonclustered index for RulesKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_RuleKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "RulesKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
  
        try
        {
            $idx.Create()
            write-host("Nonclustered index IX_factAssessment_RulesKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_FactAssessment_RulesKey") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # Create nonclustered index for AssessmentTargetKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_AssessmentTargetKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "AssessmentTargetKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
  
        try
        {
            $idx.Create()
            write-host("Nonclustered index IX_factAssessment_AssessmentTargetKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_AssessmentTargetKey") -ForegroundColor Red
            $error[0]|format-list -force
        }

        # Create nonclustered index for ObjectTypeKey
        $idx = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Index -argumentlist $FactAssessmenttbl, "IX_factAssessment_ObjectTypeKey"  
  
        $icol1 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.IndexedColumn -ArgumentList $idx, "ObjectTypeKey", $true  
        $idx.IndexedColumns.Add($icol1)  
  
        $idx.IndexKeyType = [Microsoft.SqlServer.Management.SMO.IndexKeyType]::None   
        $idx.IsClustered = $false  
        $idx.FillFactor = 90  
    
        try
        {
            $idx.Create()
            write-host("Nonclustered index IX_factAssessment_ObjectTypeKey created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create nonclustered index IX_factAssessment_ObjectTypeKey") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table FactAccessmebt already exists") -ForegroundColor Yellow
    }

    #create historylog.MissingRules
    $tableCheck = $dbw.Tables | Where {$_.Name -eq "MissingRules"}
    if(!$tableCheck)
    {            
        $historyLogtbl = New-Object Microsoft.SqlServer.Management.Smo.Table($dbw, "MissingRules", "historyLog")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($historyLogtbl, "LogDateTime", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col1.Nullable = $false
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($historyLogtbl, "RuleId", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(500))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($historyLogtbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(500))
                     
        $historyLogtbl.Columns.Add($col1)
        $historyLogtbl.Columns.Add($col2)
        $historyLogtbl.Columns.Add($col3)
      
        try
        {          
            $historyLogtbl.Create()
            Write-Host ("Table MissingRules created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table MissingRules") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("Table MissingRules already exists") -ForegroundColor Yellow
    }
        

    #create views
    $vwCheck1 = $dbw.Views | Where {$_.Name -eq "DatabaseReadiness_Azure"}
    if(!$vwCheck1)
    {
        $vwDatabaseReadiness = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $dbw, "DatabaseReadiness_Azure", "reporting"  
  
        $vwDatabaseReadiness.TextHeader = "CREATE VIEW [reporting].[DatabaseReadiness_Azure] AS"  
        $vwDatabaseReadiness.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account breakingchange weighting.
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	DateKey
		,fa.InstanceName
		,fa.DatabaseName
		,DBOwner
		,tcc.TargetCompatibilityLevel
		,at.AssessmentTarget
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN COUNT(*) END ,0) AS 'BreakingChange'
		,COALESCE(CASE changecategory WHEN 'MigrationBlocker' THEN COUNT(*) END,0) AS 'MigrationBlocker'
FROM	FactAssessment fa
JOIN	dimChangeCategory dcc
	ON	fa.ChangeCategorykey = dcc.ChangeCategoryKey
JOIN	dimTargetCompatibility tcc
	ON	fa.TargetCompatKey = tcc.TargetCompatKey
JOIN	dimAssessmentTarget at
	ON	fa.AssessmentTargetKey = at.AssessmentTargetKey
LEFT JOIN	dimDBOwner dbo
	ON	fa.DBOwnerKey = dbo.DBOwnerKey
WHERE	at.AssessmentTarget = 'AzureSQLDatabaseV12'
	AND ChangeCategory != 'NotDefined'
	AND TargetCompatibilityLevel = 'CompatLevel130'
GROUP BY DateKey, fa.InstanceName, fa.DatabaseName, dbo.DBOwner, ChangeCategory, TargetCompatibilityLevel, at.AssessmentTarget
),
distinctissues
AS
(
SELECT	DateKey
		,InstanceName
		,DatabaseName
		,DBOwner
		,TargetCompatibilityLevel
		,AssessmentTarget
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
		,MAX(MigrationBlocker) AS 'MigrationBlocker'
FROM	issuecount
GROUP BY DateKey, InstanceName, DatabaseName, DBOwner, TargetCompatibilityLevel, AssessmentTarget
),
IssueTotaled
AS
(
SELECT	*, BehaviorChange + DeprecatedCount + BreakingChange + MigrationBlocker AS 'Total'
FROM	distinctissues 
),
RankedDatabases
AS
(
SELECT	DateKey
		,InstanceName
		,DatabaseName
		,DBOwner
		,TargetCompatibilityLevel
		,AssessmentTarget
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
		,CAST(100-((MigrationBlocker + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'MigrationBlocker'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	 DateKey
		,InstanceName
		,DatabaseName
		,DBOwner
		,TargetCompatibilityLevel
		,AssessmentTarget
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
		,CASE  WHEN MigrationBlocker > 0 THEN MigrationBlocker ELSE 1 END AS "MigrationBlocker" 
FROM	RankedDatabases
"@
  
        try
        {
            $vwDatabaseReadiness.Create() 
            Write-Host ("View reporting.DatabaseReadiness_Azure created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create view reporting.DatabaseReadiness_Azure") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("View reporting.DatabaseReadiness_Azure already exists") -ForegroundColor Yellow
    }
   
    ## this view can  be deleted as the DatabaseReadiness view superseeds it. 22/03/2017
    $vwCheck2 = $dbw.Views | Where {$_.Name -eq "DatabaseReadiness_OnPrem"}
    if(!$vwCheck2)
    {
        $vwDatabaseReadiness130 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $dbw, "DatabaseReadiness_OnPrem", "reporting"  
  
        $vwDatabaseReadiness130.TextHeader = "CREATE VIEW [reporting].[DatabaseReadiness_OnPrem] AS"  
        $vwDatabaseReadiness130.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account breakingchange weighting.
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	DateKey
		,fa.InstanceName
		,fa.DatabaseName
		,DBOwner
		,tcc.TargetCompatibilityLevel
		,at.AssessmentTarget
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN COUNT(*) END ,0) AS 'BreakingChange'
		,COALESCE(CASE changecategory WHEN 'MigrationBlocker' THEN COUNT(*) END,0) AS 'MigrationBlocker'
FROM	FactAssessment fa
JOIN	dimChangeCategory dcc
	ON	fa.ChangeCategorykey = dcc.ChangeCategoryKey
JOIN	dimTargetCompatibility tcc
	ON	fa.TargetCompatKey = tcc.TargetCompatKey
JOIN	dimAssessmentTarget at
	ON	fa.AssessmentTargetKey = at.AssessmentTargetKey
LEFT JOIN	dimDBOwner dbo
	ON	fa.DBOwnerKey = dbo.DBOwnerKey
WHERE	at.AssessmentTarget != 'AzureSQLDatabaseV12'
	AND ChangeCategory != 'NotDefined'
	AND TargetCompatibilityLevel != 'NA'
GROUP BY DateKey, fa.InstanceName, fa.DatabaseName, dbo.DBOwner, ChangeCategory, TargetCompatibilityLevel, at.AssessmentTarget
),
distinctissues
AS
(
SELECT	DateKey
		,InstanceName
		,DatabaseName
		,TargetCompatibilityLevel
		,AssessmentTarget
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
		,MAX(MigrationBlocker) AS 'MigrationBlocker'
FROM	issuecount
GROUP BY DateKey, InstanceName, DatabaseName, TargetCompatibilityLevel, AssessmentTarget
),
IssueTotaled
AS
(
SELECT	*, BehaviorChange + DeprecatedCount + BreakingChange + MigrationBlocker AS 'Total'
FROM	distinctissues 
),
RankedDatabases
AS
(
SELECT	DateKey
		,InstanceName
		,DatabaseName
		,TargetCompatibilityLevel
		,AssessmentTarget
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
		,CAST(100-((MigrationBlocker + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'MigrationBlocker'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	 DateKey
		,InstanceName
		,DatabaseName
		,TargetCompatibilityLevel
		,AssessmentTarget
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
		,CASE  WHEN MigrationBlocker > 0 THEN MigrationBlocker ELSE 1 END AS "MigrationBlocker" 
FROM	RankedDatabases
"@
  
        try
        {
            $vwDatabaseReadiness130.Create() 
            Write-Host ("View reporting.DatabaseReadiness_OnPrem created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create view reporting.DatabaseReadiness_OnPrem") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("View reporting.DatabaseReadiness_OnPrem already exists") -ForegroundColor Yellow
    }
    ##

    $vwCheck3 = $dbw.Views | Where {$_.Name -eq "InstanceReadiness_130"}
    if(!$vwCheck3)
    {
        $vwInstanceReadiness_130 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $dbw, "InstanceReadiness_130", "reporting"  
  
        $vwInstanceReadiness_130.TextHeader = "CREATE VIEW [reporting].[InstanceReadiness_130] AS"  
        $vwInstanceReadiness_130.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account breakingchange weighting.
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations

SELECT	dd.[Date]
		,InstanceName
		,tcc.TargetCompatibilityLevel
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN COUNT(*) END ,0) AS 'BreakingChange'
		,COALESCE(CASE changecategory WHEN 'MigrationBlocker' THEN COUNT(*) END,0) AS 'MigrationBlocker'
FROM factassessment fa
JOIN dimChangeCategory dcc
	ON fa.ChangeCategorykey = dcc.ChangeCategoryKey
JOIN dimTargetCompatibility tcc
	ON fa.TargetCompatKey = tcc.TargetCompatKey
JOIN dimDate dd
	ON fa.DateKey = dd.DateKey
WHERE TargetCompatibilityLevel = 'CompatLevel130'
	AND changecategory != 'NotDefined'
GROUP BY dd.[Date], InstanceName, changecategory, TargetCompatibilityLevel
),
distinctissues
AS
(
SELECT	[Date]
		,InstanceName
		,TargetCompatibilityLevel
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
		,MAX(MigrationBlocker) AS 'MigrationBlocker'
FROM	issuecount
GROUP BY [Date], InstanceName, TargetCompatibilityLevel
),
IssueTotaled
AS
(
SELECT	*, behaviorchange + deprecatedcount + breakingchange + MigrationBlocker AS 'Total'
FROM	distinctissues 
),
RankedDatabases
AS
(
SELECT	[Date]
		,InstanceName
		,TargetCompatibilityLevel
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
		,CAST(100-((MigrationBlocker + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'MigrationBlocker'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	[Date]
		,InstanceName
		,TargetCompatibilityLevel
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
		,CASE  WHEN MigrationBlocker > 0 THEN MigrationBlocker ELSE 1 END AS "MigrationBlocker" 
FROM	RankedDatabases
"@
        
        try
        {
            $vwInstanceReadiness_130.Create() 
            Write-Host ("View reporting.InstanceReadiness_130 created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create view reporting.InstanceReadiness_130") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("View reporting.InstanceReadiness_130 already exists") -ForegroundColor Yellow
    }


    $vwCheck4 = $dbw.Views | Where {$_.Name -eq "TeamReadiness_130"}
    if(!$vwCheck4)
    {
        $vwTeamReadiness_130 = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $dbw, "TeamReadiness_130", "reporting"  
  
        $vwTeamReadiness_130.TextHeader = "CREATE VIEW [reporting].[TeamReadiness_130] AS"  
        $vwTeamReadiness_130.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account breakingchange weighting.
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	dd.[Date]
		,dbo.DBOwner
		,tcc.TargetCompatibilityLevel
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN COUNT(*) END ,0) AS 'BreakingChange'
		,COALESCE(CASE changecategory WHEN 'MigrationBlocker' THEN COUNT(*) END,0) AS 'MigrationBlocker'
FROM	factassessment fa
JOIN	dimChangeCategory dcc
	ON fa.ChangeCategorykey = dcc.ChangeCategoryKey
JOIN	dimTargetCompatibility tcc
	ON fa.TargetCompatKey = tcc.TargetCompatKey
JOIN	dimDBOwner dbo
	ON fa.DBOwnerKey = dbo.DBOwnerkey
	AND fa.instancename = dbo.InstanceName
	AND fa.DatabaseName = dbo.DatabaseName
JOIN	dimDate dd
	ON fa.DateKey = dd.DateKey
WHERE	TargetCompatibilityLevel = 'CompatLevel130'
	AND changecategory != 'NotDefined'
GROUP BY dd.[Date], dbo.DBOwner, changecategory, TargetCompatibilityLevel
),
distinctissues
AS
(
SELECT	[Date]
		,DBOwner
		,TargetCompatibilityLevel
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
		,MAX(MigrationBlocker) AS 'MigrationBlocker'
FROM	issuecount
GROUP BY [Date], DBOwner, TargetCompatibilityLevel
),
IssueTotaled
AS
(
SELECT	*, behaviorchange + deprecatedcount + breakingchange + MigrationBlocker AS 'Total'
FROM	distinctissues 
),
RankedDatabases
AS
(
SELECT	[Date]
		,DBOwner
		,TargetCompatibilityLevel
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
		,CAST(100-((MigrationBlocker + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'MigrationBlocker'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	[Date]
		,DBOwner
		,TargetCompatibilityLevel
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
		,CASE  WHEN MigrationBlocker > 0 THEN MigrationBlocker ELSE 1 END AS "MigrationBlocker" 
FROM	RankedDatabases
"@
  
        try
        {
            $vwTeamReadiness_130.Create() 
            Write-Host ("View reporting.TeamReadiness_130 created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create view reporting.TeamReadiness_130") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("View reporting.TeamReadiness_130 already exists") -ForegroundColor Yellow
    }    
}