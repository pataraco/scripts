-- If can't run xp_cmdshell, try this
USE master
GO

EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE WITH OVERRIDE
GO

/* change back to "0" to restore */
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE WITH OVERRIDE
GO
