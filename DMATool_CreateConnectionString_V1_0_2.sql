/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
We grant you a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute
the object code form of the Sample Code, provided that you agree:
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code. 
---------------------------------------------------------------------------------------- 
 Script: DMATool_CreateConnectionSting.sql 
 Author: Chris Lound
 Date: 05/10/2016 
 Version:  1.0.3
 Synopsis: Creates connection string for DMA (Data Migration Assistant) command line utility for all user databases (including SSRS db and SSIS db).  This excludes system databases.  
 Keywords: 
 Comments: 
 1.0 	Initial Release
 1.0.1	Updated connection string to use DmaCmd instead of sqladvisor.exe
 1.0.2  Made script SQL 2005 compatible.  Added instancename variables used for file name
 1.0.3  Added SQL Auth Section

Ensure result location exists before executing this connection string using the DMA CMD utility.  
~ in the filename is required for import powershell script as this is used for substring function/string split.

Notes:
A single connection string can contain multiple server instances.  This will go in parallel which is defined in the dma config file.
To add feature recommendations add the /AssessmentEvaluateRecommendations switch into command line
---------------------------------------------------------------------------------------- 
 */
 
DECLARE @servername VARCHAR(100) 
DECLARE @instancename VARCHAR(100)
DECLARE	@AssessmentName VARCHAR(30) 
DECLARE	@ResultLocation VARCHAR(255) 
DECLARE	@TargetPlatform VARCHAR(20) 
DECLARE @SQLAuthUserName VARCHAR(128)
DECLARE @SQLAuthPassword VARCHAR(128)
DECLARE @TargetServer VARCHAR(128)

SET @servername  = CAST(SERVERPROPERTY('ComputerNamePhysicalNETBios') AS VARCHAR(100))
SET @instancename = COALESCE(CAST(SERVERPROPERTY('instancename') AS VARCHAR(100)),'MSSQLSERVER')
SET @AssessmentName = 'UpgradeAssessment';
SET @ResultLocation = 'C:\DMAResults\' + @servername + '_' + @instancename + '~' + 'DMA_Analysis_Output.json';
SET @TargetPlatform = 'AzureSQLDatabaseV12' --'SqlServer2016';
SET @SQLAuthUserName = 'UserName'
SET @SQLAuthPassword = 'Password'
SET @TargetServer = 'servername\instancename'

-- Windows Auth
;WITH XMLDatabaseString (dbstring)
AS
(
	SELECT	'"Server=' + @servername + ';Initial Catalog=' + "name" + ';Integrated Security=true" ' AS "DBString"
	FROM	sys.databases
	WHERE	database_id NOT IN (1,2,3,4) -- EXCLUDE DATABASES HERE
	FOR XML PATH(''), TYPE
)
SELECT 'DmaCmd.exe /Action="Assess" /AssessmentName="'+ @AssessmentName + '" /Silent /AssessmentDatabases=' +
		REPLACE(REPLACE(CAST(DBString AS VARCHAR(MAX)), '<dbstring>',''),'</dbstring>','') +
		' /AssessmentEvaluateCompatibilityIssues /AssessmentEvaluateRecommendations /AssessmentOverwriteResult /AssessmentEvaluateFeatureParity /AssessmentResultJson="' + @ResultLocation + '"  /AssessmentTargetPlatform="' + @TargetPlatform + '"' as "DMAConnectionString_WindowsAuth"
FROM	 XMLDatabaseString;

-- SQL Auth
;WITH XMLDatabaseString (dbstring)
AS
(
	SELECT	'"Server=' + @TargetServer + ';Initial Catalog=' + "name" + ';User Id=' + @SQLAuthUserName + ';Password=' + @SQLAuthPassword + ';" ' AS "DBString"
	FROM	sys.databases
	WHERE	database_id NOT IN (1,2,3,4) -- EXCLUDE DATABASES HERE
	FOR XML PATH(''), TYPE
)
SELECT 'DmaCmd.exe /Action="Assess" /AssessmentName="'+ @AssessmentName + '" /Silent /AssessmentDatabases=' +
		REPLACE(REPLACE(CAST(DBString AS VARCHAR(MAX)), '<dbstring>',''),'</dbstring>','') +
		' /AssessmentEvaluateCompatibilityIssues  /AssessmentOverwriteResult /AssessmentResultJson="' + @ResultLocation + '"  /AssessmentTargetPlatform="' + @TargetPlatform + '"' as "DMAConnectionString_SQLAuth"
FROM	 XMLDatabaseString;

