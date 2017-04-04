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
# Synopsis: Create DMAReporting database for reporting on DMA data.  This is also used as a staging database for DMAWarehouse
# Keywords: 
# Notes:  Script is called by dmaProcessor function if createDMAReporting is 1
# Comments: 
# 5.0   Script seperated from DMA_Processor v5 -19/03/20179

#------------------------------------------------------------------------------------ CREATE FUNCTIONS -------------------------------------------------------------------------------------


function createDMAReporting
{
param(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $serverName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $databaseName
)

    #Create database objects
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
    $srv = New-Object Microsoft.SqlServer.Management.SMO.Server($serverName)
           
    #create reporting database
    $dbCheck = $srv.Databases | Where {$_.Name -eq "$databaseName"} | Select Name
    if(!$dbCheck)
    {            
        $db = New-Object Microsoft.SqlServer.Management.Smo.Database ($srv, $databaseName)

        try     
        {
            $db.Create()
            Write-Host("Database $databaseName created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create database $database") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
            $db=$srv.Databases.Item($databaseName)
            Write-Host ("Database $databaseName already exists") -ForegroundColor Yellow
    }

    #create ReportData table
    $tableCheck = $db.Tables | Where {$_.Name -eq "ReportData"}
    if(!$tableCheck)
    {            
        $ReportDatatbl = New-Object Microsoft.SqlServer.Management.Smo.Table($db, "ReportData")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "InstanceName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Name", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "SizeMB", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "SourceCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "TargetCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ChangeCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(20))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "RuleId", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col16 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImpactedObjectName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col17 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col18 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col19 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "DBOwner", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col20 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "AssessmentTarget", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col21 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "AssessmentName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
              
        $ReportDatatbl.Columns.Add($col1)
        $ReportDatatbl.Columns.Add($col2)
        $ReportDatatbl.Columns.Add($col3)
        $ReportDatatbl.Columns.Add($col4)
        $ReportDatatbl.Columns.Add($col5)
        $ReportDatatbl.Columns.Add($col6)
        $ReportDatatbl.Columns.Add($col7)
        $ReportDatatbl.Columns.Add($col8)
        $ReportDatatbl.Columns.Add($col9)
        $ReportDatatbl.Columns.Add($col10)
        $ReportDatatbl.Columns.Add($col11)
        $ReportDatatbl.Columns.Add($col12)
        $ReportDatatbl.Columns.Add($col13)
        $ReportDatatbl.Columns.Add($col14)
        $ReportDatatbl.Columns.Add($col15)
        $ReportDatatbl.Columns.Add($col16)
        $ReportDatatbl.Columns.Add($col17)
        $ReportDatatbl.Columns.Add($col18) 
        $ReportDatatbl.Columns.Add($col19)
        $ReportDatatbl.Columns.Add($col20)
        $ReportDatatbl.Columns.Add($col21)    
        
        try
        {    
            $ReportDatatbl.Create()
            Write-Host ("Table ReportData created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host ("Failed to create table ReportData") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table ReportData already exists") -ForegroundColor Yellow
    }

    #create AzureFeatureParity table
    $tableCheck2 = $db.Tables | Where {$_.Name -eq "AzureFeatureParity"}
    if(!$tableCheck2)
    {            
        $AzureReportDatatbl = New-Object Microsoft.SqlServer.Management.Smo.Table($db, "AzureFeatureParity")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ServerName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Version", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(10))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "FeatureParityCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "RuleID", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImpactedDatabasename", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)

        $AzureReportDatatbl.Columns.Add($col1)
        $AzureReportDatatbl.Columns.Add($col2)
        $AzureReportDatatbl.Columns.Add($col3)
        $AzureReportDatatbl.Columns.Add($col4)
        $AzureReportDatatbl.Columns.Add($col5)
        $AzureReportDatatbl.Columns.Add($col6)
        $AzureReportDatatbl.Columns.Add($col7)
        $AzureReportDatatbl.Columns.Add($col8)
        $AzureReportDatatbl.Columns.Add($col9)
        $AzureReportDatatbl.Columns.Add($col10)
        $AzureReportDatatbl.Columns.Add($col11)
        $AzureReportDatatbl.Columns.Add($col12)
        $AzureReportDatatbl.Columns.Add($col13)
        $AzureReportDatatbl.Columns.Add($col14)
        $AzureReportDatatbl.Columns.Add($col15)
        
        try
        {    
            $AzureReportDatatbl.Create()
            Write-Host ("Table AzureFeatureParity created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create table AzureFeatureParity") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table AzureFeatureParity already exists") -ForegroundColor Yellow
    }

    #create BreakingChangeWeighting table
    $tableCheck3 = $db.Tables | Where {$_.Name -eq "BreakingChangeWeighting"}
    if(!$tableCheck3)
    {            
        $BreakingChangetbl = New-Object Microsoft.SqlServer.Management.Smo.Table($db, "BreakingChangeWeighting")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "RuleId", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(36))
        $col1.Nullable = $false
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(150))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "Effort", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "FixTime", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "Cost", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "ChangeRank", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $Col6.Computed = $True
        $Col6.ComputedText = "(Effort + FixTime + Cost) / 3"
       
        $BreakingChangetbl.Columns.Add($col1)
        $BreakingChangetbl.Columns.Add($col2)
        $BreakingChangetbl.Columns.Add($col3)
        $BreakingChangetbl.Columns.Add($col4)
        $BreakingChangetbl.Columns.Add($col5)
        $BreakingChangetbl.Columns.Add($col6)
        
        try
        {
            $BreakingChangetbl.Create()
            Write-Host ("Table BreakingChangeWeighting created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create Table BreakingChangeWeighting") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($BreakingChangetbl,"PK_BreakingChangeWeighting_RuleId")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol) 
        
        try
        {
            $PK.Create()
            Write-Host ("Primary Key PK_BreakingChangeWeighting_RuleId created successfully") -ForegroundColor Green
        }
        catch
        {
            write-host("Failed to create primary key PK_BreakingChangeWeighting_RuleId") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("Table BreakingChangeWeighting already exists") -ForegroundColor Yellow
    }

    #Create views
    $vwCheck1 = $db.Views | Where {$_.Name -eq "UpgradeSuccessRanking_OnPrem"}
    if(!$vwCheck1)
    {
        $vwUpgradeSuccessRankingop = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $db, "UpgradeSuccessRanking_OnPrem", "dbo"  
  
        $vwUpgradeSuccessRankingop.TextHeader = "CREATE VIEW [dbo].[UpgradeSuccessRanking_OnPrem] AS"  
        $vwUpgradeSuccessRankingop.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN SUM(ChangeRank) END ,0) AS 'BreakingChange'
FROM	ReportData rd
LEFT JOIN BreakingChangeWeighting bcw
	ON rd.RuleId = bcw.ruleid
WHERE	ChangeCategory != 'NotDefined'
	AND TargetCompatibilityLevel != 'NA'
	AND AssessmentTarget IN ('SqlServer2012', 'SqlServer2014', 'SqlServer2016')
GROUP BY InstanceName,name, changecategory, TargetCompatibilityLevel
),
distinctissues
AS
(
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
FROM	issuecount
GROUP BY InstanceName,name, TargetCompatibilityLevel
),
IssueTotaled
AS
(
SELECT	*, behaviorchange + deprecatedcount + breakingchange AS 'Total'
FROM	distinctissues 
),
RankedDatabases
AS
(
SELECT	InstanceName
		,Name
		,TargetCompatibilityLevel
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	 InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
FROM	RankedDatabases

"@
  
        try
        {
            $vwUpgradeSuccessRankingop.Create() 
            Write-Host ("View UpgradeSuccessRanking_OnPrem created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create view UpgradeSuccessRanking_OnPrem") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("View UpgradeSuccessRanking_OnPrem already exists") -ForegroundColor Yellow
    }

    $vwCheck2 = $db.Views | Where {$_.Name -eq "UpgradeSuccessRanking_Azure"}
    if(!$vwCheck2)
    {
        $vwUpgradeSuccessRankingaz = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $db, "UpgradeSuccessRanking_Azure", "dbo"  
  
        $vwUpgradeSuccessRankingaz.TextHeader = "CREATE VIEW [dbo].[UpgradeSuccessRanking_Azure] AS"  
        $vwUpgradeSuccessRankingaz.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN SUM(ChangeRank) END ,0) AS 'BreakingChange'
		,COALESCE(CASE changecategory WHEN 'MigrationBlocker' THEN COUNT(*) END,0) AS 'MigrationBlocker'
FROM	ReportData rd
LEFT JOIN BreakingChangeWeighting bcw
	ON	rd.RuleId = bcw.ruleid
WHERE	changecategory != 'NotDefined'
	AND TargetCompatibilityLevel != 'NA'
	AND AssessmentTarget = 'AzureSQLDatabaseV12'
GROUP BY InstanceName, [Name], changecategory, TargetCompatibilityLevel
),
distinctissues
AS
(
SELECT	InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
		,MAX(MigrationBlocker) AS 'MigrationBlocker'
FROM	issuecount
GROUP BY InstanceName, [Name], TargetCompatibilityLevel
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
SELECT	InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
		,CAST(100-((MigrationBlocker + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'MigrationBlocker'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	 InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
		,CASE  WHEN MigrationBlocker > 0 THEN MigrationBlocker ELSE 1 END AS "MigrationBlocker" 
FROM	RankedDatabases
"@
  
        try
        {
            $vwUpgradeSuccessRankingaz.Create() 
            Write-Host ("View UpgradeSuccessRanking_Azure created successfully") -ForegroundColor Green 
        }
        catch
        {
            Write-Host("Failed to create view UpgradeSuccessRanking_Azure") -ForegroundColor Red
            $error[0]|format-list -force
        }        
    }
    else
    {
        Write-Host ("View UpgradeSuccessRanking_Azure already exists") -ForegroundColor Yellow
    }

    #Create Table Types
    $ttCheck = $db.UserDefinedTableTypes | Where {$_.Name -eq "JSONResults"}
    if(!$ttCheck)
    {
        $JSONResultstt = New-Object -TypeName Microsoft.SqlServer.Management.Smo.UserDefinedTableType -ArgumentList $db, "JSONResults"
        
        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "InstanceName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Name", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "SizeMB", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "SourceCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "TargetCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ChangeCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(20))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "RuleId", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col16 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImpactedObjectName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col17 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col18 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col19 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "DBOwner", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col20 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "AssessmentTarget", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col21 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "AssessmentName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
      
        $JSONResultstt.Columns.Add($col1)
        $JSONResultstt.Columns.Add($col2)
        $JSONResultstt.Columns.Add($col3)
        $JSONResultstt.Columns.Add($col4)
        $JSONResultstt.Columns.Add($col5)
        $JSONResultstt.Columns.Add($col6)
        $JSONResultstt.Columns.Add($col7)
        $JSONResultstt.Columns.Add($col8)
        $JSONResultstt.Columns.Add($col9)
        $JSONResultstt.Columns.Add($col10)
        $JSONResultstt.Columns.Add($col11)
        $JSONResultstt.Columns.Add($col12)
        $JSONResultstt.Columns.Add($col13)
        $JSONResultstt.Columns.Add($col14)
        $JSONResultstt.Columns.Add($col15)
        $JSONResultstt.Columns.Add($col16)
        $JSONResultstt.Columns.Add($col17)
        $JSONResultstt.Columns.Add($col18)  
        $JSONResultstt.Columns.Add($col19)
        $JSONResultstt.Columns.Add($col20)   
        $JSONResultstt.Columns.Add($col21) 

        try
        {
            $JSONResultstt.Create()
            Write-Host ("Table Type JSONResults created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create table type JSONResults") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("Table Type JSONResults already exists") -ForegroundColor Yellow
    }
      
    $ttCheck2 = $db.UserDefinedTableTypes | Where {$_.Name -eq "AzureFeatureParityResults"}
    if(!$ttCheck2)
    {
        $AzureParityResultstt = New-Object -TypeName Microsoft.SqlServer.Management.Smo.UserDefinedTableType -ArgumentList $db, "AzureFeatureParityResults"
        
        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ServerName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Version", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(10))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "FeatureParityCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "RuleID", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImpactedDatabasename", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)

        $AzureParityResultstt.Columns.Add($col1)
        $AzureParityResultstt.Columns.Add($col2)
        $AzureParityResultstt.Columns.Add($col3)
        $AzureParityResultstt.Columns.Add($col4)
        $AzureParityResultstt.Columns.Add($col5)
        $AzureParityResultstt.Columns.Add($col6)
        $AzureParityResultstt.Columns.Add($col7)
        $AzureParityResultstt.Columns.Add($col8)
        $AzureParityResultstt.Columns.Add($col9)
        $AzureParityResultstt.Columns.Add($col10)
        $AzureParityResultstt.Columns.Add($col11)
        $AzureParityResultstt.Columns.Add($col12)
        $AzureParityResultstt.Columns.Add($col13)
        $AzureParityResultstt.Columns.Add($col14)
        $AzureParityResultstt.Columns.Add($col15)
            
        try
        {
            $AzureParityResultstt.Create()
            Write-Host ("Table Type AzureFeatureParityResults created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create table type AzureFeaturesParityResults") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("Table Type AzureFeatureParityResults already exists") -ForegroundColor Yellow
    }  
      
    #Create Stored Procedures
    $procCheck = $db.StoredProcedures | Where {$_.Name -eq "JSONResults_Insert"}
    if(!$procCheck)
    {
        $JSONResults_Insert = New-Object -TypeName Microsoft.SqlServer.Management.Smo.StoredProcedure -ArgumentList $db, "JSONResults_Insert", "dbo"
        
        $JSONResults_Insert.TextHeader = "CREATE PROCEDURE dbo.JSONResults_Insert @JSONResults JSONResults READONLY AS"
        $JSONResults_Insert.TextBody = @"
BEGIN

INSERT INTO dbo.ReportData (ImportDate, InstanceName, [Status], [Name], SizeMB, SourceCompatibilityLevel, TargetCompatibilityLevel, Category, Severity, ChangeCategory, RuleId, Title, Impact, Recommendation, MoreInfo, ImpactedObjectName, ImpactedObjectType, ImpactDetail, DBOwner, AssessmentTarget, AssessmentName)
SELECT ImportDate, InstanceName, [Status], [Name], SizeMB, SourceCompatibilityLevel, TargetCompatibilityLevel, Category, Severity, ChangeCategory, RuleId, Title, Impact, Recommendation, MoreInfo, ImpactedObjectName, ImpactedObjectType, ImpactDetail, DBOwner, AssessmentTarget, AssessmentName
FROM @JSONResults

END
"@

        try
        {
            $JSONResults_Insert.Create()
            Write-Host ("Stored Procedure JSONNResults_Insert created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create stored procedure JSONResults_Insert") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("Stored Procedure JSONNResults_Insert already exists") -ForegroundColor Yellow
    }

    $procCheck2 = $db.StoredProcedures | Where {$_.Name -eq "AzureFeatureParityResults_Insert"}
    if(!$procCheck2)
    {
        $AzureFeatureParityResults_Insert = New-Object -TypeName Microsoft.SqlServer.Management.Smo.StoredProcedure -ArgumentList $db, "AzureFeatureParityResults_Insert", "dbo"
        
        $AzureFeatureParityResults_Insert.TextHeader = "CREATE PROCEDURE dbo.AzureFeatureParityResults_Insert @AzureFeatureParityResults AzureFeatureParityResults READONLY AS"
        $AzureFeatureParityResults_Insert.TextBody = @"
BEGIN

INSERT INTO dbo.AzureFeatureParity (ImportDate, ServerName, Version, Status, Category, Severity, FeatureParityCategory, RuleID, Title, Impact, Recommendation, MoreInfo, ImpactedDatabasename, ImpactedObjectType, ImpactDetail)
SELECT ImportDate, ServerName, Version, Status, Category, Severity, FeatureParityCategory, RuleID, Title, Impact, Recommendation, MoreInfo, ImpactedDatabasename, ImpactedObjectType, ImpactDetail
FROM @AzureFeatureParityResults

END
"@

        try
        {
            $AzureFeatureParityResults_Insert.Create()
            Write-Host ("Stored Procedure AzureFeatureParityResults_Insert created successfully") -ForegroundColor Green 
        }
        catch
        {
            write-host("Failed to create stored procedure AzureFeaturesParityResults_Insert") -ForegroundColor Red
            $error[0]|format-list -force
        }
    }
    else
    {
        Write-Host ("Stored Procedure AzureFeatureParityResults_Insert already exists") -ForegroundColor Yellow
    }

    $connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;"

    #Populate the breaking change reference data
    $RefDataCheck = $db.Tables | Where {$_.Name -eq "BreakingChangeWeighting"} | Select RowCount
    if($RefDataCheck.RowCount -eq 0)
    {

        #populate static data into BreakingChangeWeighting
                
        $CommandText = @'
INSERT INTO BreakingChangeWeighting VALUES ('Microsoft.Rules.Data.Upgrade.UR00001','Syntax issue on the source server',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00006','BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements are not supported',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00007','BACKUP/RESTORE TRANSACTION statements are deprecated or discontinued',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00013','COMPUTE clause is not allowed in database compatibility 110',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00020','Read-only databases cannot be upgraded',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00021','Verify all filegroups are writeable during the upgrade process',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00023','SQL Server native SOAP support is discontinued in SQL Server 2014 and above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00044','Remove user-defined type (UDT)s named after the reserved GEOMETRY and GEOGRAPHY data types',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00050','Table hints in indexed view definitions are ignored in compatibility mode 80 and are not allowed in compatibility mode 90 or above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00058','After upgrade, new reserved keywords cannot be used as identifiers',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00062','Tables and Columns named NEXT may lead to an error using compatibility Level 110 and above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00086','XML is a reserved system type name',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00110','New column in output of sp_helptrigger may impact applications',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00113','SQL Mail has been discontinued',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00300','Remove the use of PASSWORD in BACKUP command',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00301','WITH CHECK OPTION is not supported in views that contain TOP in compatibility mode 90 and above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00302','Discontinued DBCC commands referenced in your T-SQL objects',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00308','Legacy style RAISERROR calls should be replaced with modern equivalents',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00311','Detected statements that reference removed system stored procedures that are not available in database compatibility level 100 and higher',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00318','FOR BROWSE is not allowed in views in 90 or later compatibility modes',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00321','Non ANSI style left outer join usage',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00322','Non ANSI style right outer join usage',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00326','Constant expressions are not allowed in the ORDER BY clause in 90 or later compatibility modes',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00332','FASTFIRSTROW table hint usage',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00336','Certain XPath functions are not allowed in OPENXML queries',1,1,1)
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
}