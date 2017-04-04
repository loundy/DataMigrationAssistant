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
# Date: 08/02/2017 
# Version:  5.0
# Synopsis: Create reporting objects and loads JSON files from DMA output folder into SQL server 
# Keywords: 
# Notes:  A processed folder is created in the root folder of the folder containing the DMA JSON output (user specified).  Script currently only supports windows authentication to SQL Server.
# Comments: 
# 1.0 	Initial Release - 22/11/2016 
# 2.0   Refactored JSON shredder for SQL2014 and below.  Made this the only shredding function by removing the SQL2016 dependency
# 3.0   Built in weighted breaking changes.  Added table to support breaking change weighting and updated view to use it for reporting.  Also removed Azure Artifacts
# 3.1   Change importdate type to datetime.  Added DBOwner column for reportdata table. - 16/02/2017
# 4.0   Added DMAWarehouse objects. Cleaned up output into console
# 4.1   Added Warehouse views, AssessmentTarget and AssessmentName properties and dependants
# 5.0   Added support for feature parity for azure targets (new table, table type, stored procedure, datatable (ps), shredding loop (ps).
#       Added error handling for failed dataset fills.  Added support for only moving files when they are actually processed.  if they fail they dont get moved.
#       Added option to create data warehouse
#       Altered UpgradeSuccessRanking view to exclude TargetCompatibilityMode of 'NA' (Azure migrations)
#       Split UpgradeSuccessRanking views into 2, 1 for onprem and 1 for azure to fix assessment counts in powerbi

#------------------------------------------------------------------------------------ CREATE FUNCTIONS -------------------------------------------------------------------------------------

#requires -version 5.0 

#Import JSON to SQL on prem or azure
function dmaProcessor 
{
param(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $serverName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $databaseName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $warehouseName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $jsonDirectory,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("SQLServer")] 
    [string] $processTo,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(0,1)]
    [int] $CreateDMAReporting,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(0,1)]
    [int] $CreateDataWarehouse
)

    if ($createDMAReporting -eq 1)
    {
        #load createDMAReporting function
        [string] $path = (Split-Path $script:MyInvocation.MyCommand.Path) + "\DMA_createDMAReporting.ps1" 
        . $path
        
        createDMAReporting -serverName $serverName -databaseName $databaseName
    }
     

    if ($CreateDataWarehouse -eq 1)
    {
        #load createWarehouse function
        [string] $path = (Split-Path $script:MyInvocation.MyCommand.Path) + "\DMA_createWarehouse.ps1" 
        . $path
        
        createWarehouse -serverName $serverName -warehouseName $warehouseName
    }
   

    #Make processed directory inside the folder that contains the json files
    if(!$jsonDirectory.EndsWith("\"))
    {
        $jsonDirectory = "$jsonDirectory\"
    }
    $processedDir = "$jsonDirectory`Processed"

    if((Test-Path $processedDir) -eq $false)
    {
        new-item $processedDir -ItemType directory 
        Write-Host ("Processed directory created successfully at [$processDir]") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Processed directory already exists") -ForegroundColor Yellow
    }
       
    # if there are no files to process stop importer
    $FileCheck = Get-ChildItem $jsonDirectory -Filter *.JSON
    if($FileCheck.Count -eq 0)
    {
        Write-Host ("There are no JSON assessment files to process") -ForegroundColor Yellow 
        Break
    }
    
    
    $connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;"

    # importer for SQL2014 and previous versions. Done via PowerShell
    Get-ChildItem $jsonDirectory -Filter *.JSON | 
    Foreach-Object {
        
        $filename = $_.FullName

        #ReportData datatable                                                                                                                                                                                                                                                                                {                   
        $datatable = New-Object -type system.data.datatable
        $datatable.columns.add("ImportDate",[DateTime]) | Out-Null
        $datatable.columns.add("InstanceName",[String]) | Out-Null
        $datatable.columns.add("Status",[String]) | Out-Null
        $datatable.columns.add("Name",[String]) | Out-Null
        $datatable.columns.add("SizeMB",[String]) | Out-Null
        $datatable.columns.add("SourceCompatibilityLevel",[String]) | Out-Null
        $datatable.columns.add("TargetCompatibilityLevel",[String]) | Out-Null
        $datatable.columns.add("Category",[String]) | Out-Null
        $datatable.columns.add("Severity",[String]) | Out-Null
        $datatable.columns.add("ChangeCategory",[String]) | Out-Null
        $datatable.columns.add("RuleId",[String]) | Out-Null
        $datatable.columns.add("Title",[String]) | Out-Null
        $datatable.columns.add("Impact",[String]) | Out-Null
        $datatable.columns.add("Recommendation",[String]) | Out-Null
        $datatable.columns.add("MoreInfo",[String]) | Out-Null
        $datatable.columns.add("ImpactedObjectName",[String]) | Out-Null
        $datatable.columns.add("ImpactedObjectType",[String]) | Out-Null
        $datatable.columns.add("ImpactDetail",[string]) | Out-Null
        $datatable.columns.add("DBOwner",[string]) | Out-Null
        $datatable.columns.add("AssessmentTarget",[string]) | Out-Null
        $datatable.columns.add("AssessmentName",[string]) | Out-Null

        #AzureFeatureParity datatable
        $azuredatatable = New-Object -type system.data.datatable
        $azuredatatable.columns.add("ImportDate",[DateTime]) | Out-Null
        $azuredatatable.columns.add("ServerName",[String]) | Out-Null
        $azuredatatable.columns.add("Version",[String]) | Out-Null
        $azuredatatable.columns.add("Status",[String]) | Out-Null
        $azuredatatable.columns.add("Category",[String]) | Out-Null
        $azuredatatable.columns.add("Severity",[String]) | Out-Null
        $azuredatatable.columns.add("FeatureParityCategory",[String]) | Out-Null
        $azuredatatable.columns.add("RuleID",[String]) | Out-Null
        $azuredatatable.columns.add("Title",[String]) | Out-Null
        $azuredatatable.columns.add("Impact",[String]) | Out-Null
        $azuredatatable.columns.add("Recommendation",[String]) | Out-Null
        $azuredatatable.columns.add("MoreInfo",[String]) | Out-Null
        $azuredatatable.columns.add("ImpactedDatabasename",[String]) | Out-Null
        $azuredatatable.columns.add("ImpactedObjectType",[String]) | Out-Null
        $azuredatatable.columns.add("ImpactDetail",[String]) | Out-Null


        $processStartTime = Get-Date
        $datetime = Get-Date                    
        $content = Get-Content $_.FullName -Raw
        
        # when a database assessment fails the assessment recommendations and impacted objects arrays
        # will be blank.  Setting them to default values allows for the errors to be captured
        $blankAssessmentRecommendations =   (New-Object PSObject |
                                           Add-Member -PassThru NoteProperty CompatibilityLevel NA |
                                           Add-Member -PassThru NoteProperty Category NA          |
                                           Add-Member -PassThru NoteProperty Severity NA     |
                                           Add-Member -PassThru NoteProperty ChangeCategory NA |
                                           Add-Member -PassThru NoteProperty RuleId NA |
                                           Add-Member -PassThru NoteProperty Title NA |
                                           Add-Member -PassThru NoteProperty Impact NA |
                                           Add-Member -PassThru NoteProperty Recommendation NA |
                                           Add-Member -PassThru NoteProperty MoreInfo NA |
                                           Add-Member -PassThru NoteProperty ImpactedObjects NA
                                        ) 
        
        $blankImpactedObjects = (New-Object PSObject |
                                           Add-Member -PassThru NoteProperty Name NA |
                                           Add-Member -PassThru NoteProperty ObjectType NA          |
                                           Add-Member -PassThru NoteProperty ImpactDetail NA     
                                        )

        $blankImpactedDatabases = (New-Object PSObject |
                                           Add-Member -PassThru NoteProperty Name NA |
                                           Add-Member -PassThru NoteProperty ObjectType NA          |
                                           Add-Member -PassThru NoteProperty ImpactDetail NA     
                                        ) 


        # Start looping through each JSON array
        
        #fill dataset for ReportData table
        foreach($obj in (ConvertFrom-Json $content)) #level 1, the actual file
        {          
            foreach($database in $obj.Databases) #level 2, the sources
            {
                $database.AssessmentRecommendations = if($database.AssessmentRecommendations.Length -eq 0) {$blankAssessmentRecommendations } else {$database.AssessmentRecommendations}
                
                foreach($assessment in $database.AssessmentRecommendations) #level 3, the assessment
                {
                    #$assessment.CompatibilityLevel = if($assessment.CompatibilityLevel -eq $null) { "NA" } else {$assessment.CompatibilityLevel}
                    #$assessment.Category = if ($assessment.Category -eq $null) {"NA"} else {$assessment.Category}
                    #$assessment.Severity = if ($assessment.Severity -eq $null) {"NA"} else {$assessment.Severity}
                    #$assessment.ChangeCategory = if ($assessment.ChangeCategory -eq $null) {"NA"} else {$assessment.ChangeCategory}
                    #$assessment.RuleId = if ($assessment.RuleId -eq $null) {"NA"} else {$assessment.RuleId}
                    #$assessment.Title = if ($assessment.Title -eq $null) {"NA"} else {$assessment.Title}
                    #$assessment.Impact = if ($assessment.Impact -eq $null) {"NA"} else {$assessment.Impact}
                    #$assessment.Recommendation = if ($assessment.Recommendation -eq $null) {"NA"} else {$assessment.Recommendation}
                    #$assessment.MoreInfo = if ($assessment.MoreInfo -eq $null) {"NA"} else {$assessment.MoreInfo}
                    $assessment.ImpactedObjects = if ($assessment.ImpactedObjects.Length -eq 0) {$blankImpactedObjects} else {$assessment.ImpactedObjects}

                    foreach($impactedobj in $assessment.ImpactedObjects) #level 4, the impacted objects
                    {
                        #$impactedobj.Name = if ($impactedobj.Name -eq $null) { "NA" } else { $impactedobj.Name }
                        #$impactedobj.ObjectType = if ($impactedobj.ObjectType -eq $null) { "NA" } else { $impactedobj.ObjectType }
                        #$impactedobj.ImpactDetail = if ($impactedobj.ImpactDetail -eq $null) { "NA" } else { $impactedobj.ImpactDetail }
                        
                        #TODO Get date here will eventually be replace with timestamp from JSON file
                        $datatable.rows.add((Get-Date).toString(), $database.ServerName, $database.Status, $database.Name, $database.SizeMB, $database.CompatibilityLevel, $assessment.CompatibilityLevel, $assessment.Category, $assessment.severity, $assessment.ChangeCategory, $assessment.RuleId, $assessment.Title, $assessment.Impact, $assessment.Recommendation, $assessment.MoreInfo, $impactedobj.Name, $impactedobj.ObjectType, $impactedobj.ImpactDetail, $null, $obj.TargetPlatform, $obj.Name) | Out-Null
                    }
                }
            }
        }           

        #fill data set for AzureFeatureParity table
        foreach($obj in (ConvertFrom-Json $content)) #level 1, the actual file
        {          
            foreach($serverInstances in $obj.ServerInstances) #level 2, the ServerInstances
            {
                foreach($assessment in $serverInstances.AssessmentRecommendations) #level 3, the assessment
                {
                    $assessment.ImpactedDatabases = if ($assessment.ImpactedDatabases.Length -eq 0) {$blankImpactedDatabases} else {$assessment.ImpactedDatabases}
                        
                    foreach($impacteddbs in $assessment.ImpactedDatabases) #level 4, the impacted objects
                    {                       
                        #TODO Get date here will eventually be replace with timestamp from JSON file
                        $azuredatatable.rows.add((Get-Date).toString(), $serverInstances.ServerName, $serverInstances.Version, $serverInstances.Status, $assessment.Category, $assessment.Severity, $assessment.FeatureParityCategory, $assessment.RuleId, $assessment.Title, $assessment.Impact, $assessment.Recommendation, $assessment.MoreInfo, $impacteddbs.Name, $impacteddbs.ObjectType, $impacteddbs.ImpactDetail) | Out-Null
                    }
                        
                }
            }
        }

        $rowcount_rd = $datatable.rows.Count
        $rowcount_afp = $azuredatatable.rows.Count

        $query1='dbo.JSONResults_Insert' 
        $query2='dbo.AzureFeatureParityResults_Insert'  

        #Connect
        $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString 
        $conn.Open() | Out-Null

        $cmd1 = New-Object System.Data.SqlClient.SqlCommand
        $cmd1.Connection = $conn
        $cmd1.CommandType = [System.Data.CommandType]"StoredProcedure"
        $cmd1.CommandText= $query1
        $cmd1.Parameters.Add("@JSONResults" , [System.Data.SqlDbType]::Structured) | Out-Null
        $cmd1.Parameters["@JSONResults"].Value =$datatable

        $cmd2 = New-Object System.Data.SqlClient.SqlCommand
        $cmd2.Connection = $conn
        $cmd2.CommandType = [System.Data.CommandType]"StoredProcedure"
        $cmd2.CommandText= $query2
        $cmd2.Parameters.Add("@AzureFeatureParityResults" , [System.Data.SqlDbType]::Structured) | Out-Null
        $cmd2.Parameters["@AzureFeatureParityResults"].Value = $azuredatatable
                     
        $ds1=New-Object system.Data.DataSet
        $da1=New-Object system.Data.SqlClient.SqlDataAdapter($cmd1)
          
        $ds2=New-Object system.Data.DataSet
        $da2=New-Object system.Data.SqlClient.SqlDataAdapter($cmd2)
      
        # ensure that the dataset can write to the database, if not the dont move the file to processed directory
        try
        {
            $da1.fill($ds1) | Out-Null
            $da2.fill($ds2) | out-null
   
            try
            {
                Move-Item $filename $processedDir -Force
            }
            catch
            {
                write-host("Error moving file $filename to directory") -ForegroundColor Red
                $error[0]|format-list -force
            }

        }
        catch
        {
            $rowcount_rd = 0
            $rowcount_afp = 0
            write-host("Error writing results for file $filename to database") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $conn.Close()

        $processEndTime = Get-Date
        $processTime = NEW-TIMESPAN -Start $processStartTime -End $processEndTime
        Write-Host("Rows Processed for ReportData Table = $rowcount_rd  Rows processed for AzureFeatureParityTable = $rowcount_afp for file $filename Total Processing Time = $processTime")

        $datatable.Clear()
        $azuredatatable.Clear()
        
    }
}

#------------------------------------------------------------------------------------  END FUNCTIONS ------------------------------------------------------------------------------------------





#------------------------------------------------------------------------------------- EXECUTE FUNCTIONS --------------------------------------------------------------------------------------

dmaProcessor -serverName localhost `
            -jsonDirectory "C:\DMAResults\" `
            -processTo SQLServer `
            -CreateDMAReporting 1 `
            -CreateDataWarehouse 1 `
            -databaseName DMAReporting `
            -warehouseName DMAWarehouse
                       


#        To process on a named instance use SERVERNAME\INSTANCENAME as the -serverName 

#------------------------------------------------------------------------------------ END EXECUTE FUNCTIONS ------------------------------------------------------------------------------------

