
-- 14.0.0  Access Control and User Management
--         Expect this lab to take approximately 40 minutes.
--         Lab Purpose: Students will work with the Snowflake security model and
--         learn how to create roles, grant privileges, build, and implement
--         basic security models.

-- 14.1.0  Determine Privileges (GRANTs)

-- 14.1.1  Navigate to [Worksheets] and create a new worksheet named Managing
--         Security.

-- 14.1.2  If you haven’t created the class database or warehouse, do it now

CREATE WAREHOUSE IF NOT EXISTS LEARNING;
CREATE DATABASE IF NOT EXISTS LEARNING;


-- 14.1.3  Run these commands to see what has been granted to you as a user, and
--         to your roles:

SHOW GRANTS TO USER LEARNING;
SHOW GRANTS TO ROLE LEARNING;
SHOW GRANTS TO ROLE SYSADMIN;
SHOW GRANTS TO ROLE SECURITYADMIN;

--         NOTE: The LEARNING role has some specific privileges granted - not
--         all roles in the system would be able to see these results.

-- 14.2.0  Work with Role Permissions

-- 14.2.1  Change your role to SECURITYADMIN:

USE ROLE SECURITYADMIN;


-- 14.2.2  Create two new custom roles, called CLASSIFIED and GENERAL:

CREATE ROLE CLASSIFIED;
CREATE ROLE GENERAL;


-- 14.2.3  GRANT both roles to SYSADMIN, and to your user:

GRANT ROLE CLASSIFIED, GENERAL TO ROLE SYSADMIN;
GRANT ROLE CLASSIFIED, GENERAL TO USER LEARNING;


-- 14.2.4  Change to the role SYSADMIN, so you can assign permissions to the
--         roles you created:

USE ROLE SYSADMIN;


-- 14.2.5  Create a warehouse named LEARNING_SHARED:

CREATE WAREHOUSE LEARNING_SHARED;


-- 14.2.6  Grant both new roles privileges to use the shared warehouse:

GRANT USAGE ON WAREHOUSE LEARNING_SHARED
  TO ROLE CLASSIFIED;
GRANT USAGE ON WAREHOUSE LEARNING_SHARED
  TO ROLE GENERAL;


-- 14.2.7  Create a database called CLASSIFIED:

CREATE DATABASE CLASSIFIED;


-- 14.2.8  Grant the role CLASSIFIED all necessary privileges to create
--         tables on any schema in CLASSIFIED:

GRANT USAGE ON DATABASE CLASSIFIED
TO ROLE CLASSIFIED;
GRANT USAGE ON ALL SCHEMAS IN DATABASE CLASSIFIED
TO ROLE CLASSIFIED;
GRANT CREATE TABLE ON ALL SCHEMAS IN DATABASE CLASSIFIED
TO ROLE CLASSIFIED;


-- 14.2.9  Use the role CLASSIFIED, and create a table called
--         SUPER_SECRET inside the CLASSIFIED.PUBLIC schema:

USE ROLE CLASSIFIED;
USE CLASSIFIED.PUBLIC;
CREATE TABLE SUPER_SECRET (id INT);


-- 14.2.10 Insert some data into the table:

INSERT INTO SUPER_SECRET VALUES (1), (10), (30);


-- 14.2.11 Assign GRANT SELECT privileges on SUPER_SECRET to the role
--         GENERAL:

GRANT SELECT ON SUPER_SECRET TO ROLE GENERAL;


-- 14.2.12 Use the role GENERAL to SELECT * from the table
--         SUPER_SECRET:

USE ROLE GENERAL;
SELECT * FROM CLASSIFIED.PUBLIC.SUPER_SECRET;

--         What happens? Why?

-- 14.2.13 Grant role GENERAL usage on all schemas in
--         CLASSIFIED:

USE ROLE SYSADMIN;
GRANT USAGE ON DATABASE CLASSIFIED TO ROLE GENERAL;
GRANT USAGE ON ALL SCHEMAs IN DATABASE CLASSIFIED TO ROLE GENERAL;


-- 14.2.14 Now try again:

USE ROLE GENERAL;
SELECT * FROM CLASSIFIED.PUBLIC.SUPER_SECRET;


-- 14.2.15 Drop the database CLASSIFIED:

USE ROLE SYSADMIN;
DROP DATABASE CLASSIFIED;


-- 14.2.16 Drop the roles CLASSIFIED and GENERAL:

USE ROLE SECURITYADMIN;
DROP ROLE CLASSIFIED;
DROP ROLE GENERAL;

--         HINT: What role do you need to use to do this?

-- 14.3.0  Create Parent and Child Roles

-- 14.3.1  Change your role to SECURITYADMIN:

USE ROLE SECURITYADMIN;


-- 14.3.2  Create a parent and child role, and GRANT the roles to the role
--         SYSADMIN. At this point, the roles are peers (neither one is below
--         the other in the hierarchy):

CREATE ROLE CHILD;
CREATE ROLE PARENT;
GRANT ROLE CHILD, PARENT TO ROLE SYSADMIN;


-- 14.3.3  Give your user name privileges to use the roles:

GRANT ROLE CHILD, PARENT TO USER LEARNING;


-- 14.3.4  Change your role to SYSADMIN:

USE ROLE SYSADMIN;


-- 14.3.5  Grant the following object permissions to the child role:

GRANT USAGE ON WAREHOUSE LEARNING TO ROLE CHILD;
GRANT USAGE ON DATABASE LEARNING TO ROLE CHILD;
GRANT USAGE ON SCHEMA LEARNING.PUBLIC TO ROLE CHILD;
GRANT CREATE TABLE ON SCHEMA LEARNING.PUBLIC
   TO ROLE CHILD;


-- 14.3.6  Use the child role to create a table:

USE ROLE CHILD;
USE WAREHOUSE LEARNING;
USE DATABASE LEARNING;
USE SCHEMA LEARNING.PUBLIC;
CREATE TABLE genealogy (name STRING, age INTEGER, mother STRING,
   father STRING);


-- 14.3.7  Verify that you can see the table:

SHOW TABLES LIKE '%genealogy%';


-- 14.3.8  Use the parent role and view the table:

USE ROLE PARENT;
SHOW TABLES LIKE '%genealogy%';

--         You will not see the table, because the parent role has not been
--         granted access.

-- 14.3.9  Change back to the SECURITYADMIN role and change the hierarchy so the
--         child role is beneath the parent role:

USE ROLE SECURITYADMIN;
GRANT ROLE CHILD to ROLE PARENT;


-- 14.3.10 Use the parent role, and verify the parent can now see the table
--         created by the child:

USE ROLE PARENT;
SHOW TABLES LIKE '%genealogy%';


-- 14.3.11 Suspend and resize the warehouse

ALTER WAREHOUSE LEARNING SET WAREHOUSE_SIZE=XSmall;
ALTER WAREHOUSE LEARNING SUSPEND;

