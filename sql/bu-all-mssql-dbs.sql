-- This Script will allow you to backup all DBs

-- The script looks for *.mdf files in your SQL instance and
-- backs up all of the files it finds except for the system databases...

DECLARE @name VARCHAR(50) -- database name  
DECLARE @path VARCHAR(256) -- path for backup files  
DECLARE @fileName VARCHAR(256) -- filename for backup  
DECLARE @fileDate VARCHAR(20) -- used for file name

-- specify BACKUP LOCATION (backup directory)
SET @path = 'BACKUP LOCATION'
-- ex. SET @path = 'C:\backup\'      -- local drive
-- ex. SET @path = 'O:\sqlbackup\'   -- remote drive
-- note that remote drive setup is an extra step you have to perform in
-- SQL server in order to backup your DBs to remote drives
-- You have to change your SQL Server account to a network account and add
-- that user to have full access to the network drive you are backing up to

-- specify filename format
-- File Naming Format DBname_YYYYDDMM.BAK
SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) 
-- File Naming Format DBname_YYYYDDMM_HHMMSS.BAK
-- If you want to also include the time in the filename, use this line:
-- SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) + REPLACE(CONVERT(VARCHAR(20),GETDATE(),108),':','')


DECLARE db_cursor CURSOR READ_ONLY FOR  
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb')  -- exclude these databases

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   

WHILE @@FETCH_STATUS = 0   
BEGIN   
   SET @fileName = @path + @name + '_' + @fileDate + '.BAK'  
   BACKUP DATABASE @name TO DISK = @fileName  
   FETCH NEXT FROM db_cursor INTO @name   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor
