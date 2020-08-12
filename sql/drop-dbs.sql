-- Drop connections to the database
DECLARE @DatabaseName nvarchar(50)
SET @DatabaseName = N'raco-test'

DECLARE @SQL varchar(max)

SELECT @SQL = COALESCE(@SQL,'') + 'Kill ' + Convert(varchar, SPId) + ';'
FROM MASTER..SysProcesses
WHERE DBId = DB_ID(@DatabaseName) AND SPId <> @@SPId

--SELECT @SQL 
EXEC(@SQL)

-- drop it

USE master ;  
GO  
DROP DATABASE "raco-test" ;  
GO