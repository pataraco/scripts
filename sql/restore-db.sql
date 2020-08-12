exec msdb.dbo.rds_restore_database 
	@restore_db_name='palmdale', 
	@s3_arn_to_restore_from='arn:aws:s3:::innovyze-info360-telemetry-palmdale/Palmdale_Peter.bak',
	@with_norecovery=0,
	@type='FULL';
--	@with_norecovery=0, -- RECOVERY: database is online after restore 
--	@with_norecovery=1, -- NORECOVERY: database remains in the RESTORING state
--	[@kms_master_key_arn='arn:aws:kms:region:account-id:key/key-id'],
--	[@type='DIFFERENTIAL|FULL'];  -- default: FULL


RESTORE DATABASE palmdale
    FROM DISK = '/var/opt/mssql/backup/Palmdale_Peter.bak'
    WITH
       MOVE 'SCADAWatch' TO '/var/opt/mssql/data/palmdale.mdf',
       MOVE 'SCADAWatch_log' TO '/var/opt/mssql/data/palmdale_log.ldf',
       REPLACE,
       RECOVERY,
       STATS = 5

/*
RESTORE DATABASE palmdale
    FROM DISK = '/var/opt/mssql/backup/Palmdale_Peter.bak'
    WITH
       MOVE 'SCADAWatch_Palmdale_New' TO '/var/opt/mssql/data/palmdale.mdf',
       MOVE 'SCADAWatch_Palmdale_New_log' TO '/var/opt/mssql/data/palmdale_log.ldf',
       REPLACE,
       RECOVERY,
       STATS = 5
 */

/*
 RESTORE FILELISTONLY FROM DISK = '/var/opt/mssql/backup/Palmdale_Peter.bak'
 */

/* copy data files and attach */
USE [master]
GO

EXEC sp_attach_db @dbname = N'palmdale',
    @filename1 =   '/var/opt/mssql/data/palmdale.mdf',
    @filename2 =   '/var/opt/mssql/data/palmdale_log.ldf';
GO
