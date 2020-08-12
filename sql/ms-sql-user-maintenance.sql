USE master;
GO

ALTER LOGIN SA WITH DEFAULT_DATABASE=master
GO

ALTER LOGIN SA WITH PASSWORD=N'uG8gaeciech|e2veig#ainu)G'
GO

USE master;

/* creating a new user */
/*
CREATE LOGIN mgauthier
    WITH PASSWORD = 'lae5uo^f6ahm1piri3mouTh1H';
GO
*/

/* changing an existing user */
ALTER LOGIN mgauthier
    WITH PASSWORD = 'laXXXXXXXXXXXXXXXh1H';
GO

USE palmdale;
GO

/* creating a new user for a DB */
CREATE USER mgauthier FOR LOGIN mgauthier;
GO

/* after restoring a DB */
ALTER USER mgauthier WITH LOGIN = mgauthier;
GO

/* Granting permissions */
/*
GRANT SELECT ON SW_SensorConfig TO mgauthier;
GO
 */

GRANT SELECT TO mgauthier;
GO

/* list users */
SELECT name AS username,
    create_date,
    modify_date,
    type_desc as type,
    authentication_type_desc as authentication_type
FROM sys.database_principals
WHERE type NOT IN ('A', 'G', 'R', 'X')
    AND sid IS NOT NULL
    AND name != 'guest'
ORDER BY username;
GO
