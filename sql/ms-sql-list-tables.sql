USE databasename;
SELECT schema_name(t.schema_id) AS schema_name,
    t.name AS table_name,
    t.create_date,
    t.modify_date
FROM sys.tables t
ORDER BY schema_name,
         table_name;