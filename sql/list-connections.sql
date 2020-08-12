/*
  Description: Lists all connections linked to the database.
  Provided by: http://www.diademblogs.com/database/some-useful-sql-commands-for-ms-sql-db-admins
*/
SELECT DB_NAME(dbid)AS ConnectedToDB,
hostname, program_name,loginame,
cpu, physical_io, memusage, login_time,
last_batch, [status]
FROM master.dbo.sysprocesses
ORDER BY dbid, login_time, last_batch