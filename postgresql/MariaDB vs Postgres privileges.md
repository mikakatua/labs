# Understanding PostgreSQL privileges
Goal: We want that only user1 has privileges on db1

### Testing the database server in a container
```
docker run --name mariadb -e MARIADB_ROOT_PASSWORD=password -d mariadb
docker exec -it mariadb mysql -ppassword
```
```
docker run --name postgres -e POSTGRES_PASSWORD=password -d postgres
docker exec -it postgres psql -U postgres
```

## MySQL: A user with its own database
Create a user and database. Give all privileges on the database to the user
```
MariaDB [(none)]> CREATE USER user1 IDENTIFIED BY 'password';
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> CREATE USER user2 IDENTIFIED BY 'password';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> CREATE DATABASE db1;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> GRANT ALL ON db1.* TO user1;
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> \! mysql -u user1 -ppassword -s db1
MariaDB [db1]> SHOW TABLES;
Tables_in_db1
t1
MariaDB [db1]> exit
MariaDB [(none)]> \! mysql -u user2 -ppassword -s db1
ERROR 1044 (42000): Access denied for user 'user2'@'%' to database 'db1'
MariaDB [(none)]> 
```

## PostgreSQL: Any user can create objects in any database!
By default, everyone has `CREATE` and `USAGE` privileges on the schema `public`. This is never a secure pattern. It is acceptable only when the database has a single user or a few mutually-trusting users.
```
postgres=# CREATE USER user1 PASSWORD 'password';
CREATE ROLE
postgres=# CREATE USER user2 PASSWORD 'password';
CREATE ROLE
postgres=# CREATE DATABASE db1;
CREATE DATABASE
postgres=# GRANT ALL ON DATABASE db1 TO user1;
GRANT
postgres=# \c db1 user1
You are now connected to database "db1" as user "user1".
db1=> CREATE TABLE t1(a int);
CREATE TABLE
db1=> \c - user2
You are now connected to database "db1" as user "user2".
db1=> CREATE TABLE t2(a int);
CREATE TABLE
db1=> 
```

## PostgreSQL: Constrain ordinary users to user-private schemas
Remove the privileges from public schema, and create a schema for each user with the same name as that user. Recall that the default [search_path](https://www.postgresql.org/docs/current/ddl-schemas.html#DDL-SCHEMAS-PATH) starts with `$user`, which resolves to the user name.
```
postgres=# \c template1
You are now connected to database "template1" as user "postgres".
template1=# REVOKE CREATE ON SCHEMA public FROM public;
REVOKE
template1=# CREATE USER user1 PASSWORD 'password';
CREATE ROLE
template1=# CREATE USER user2 PASSWORD 'password';
CREATE ROLE
template1=# CREATE DATABASE db1;
CREATE DATABASE
template1=# \c db1
You are now connected to database "db1" as user "postgres".
db1=# CREATE SCHEMA user1;
CREATE SCHEMA
db1=# GRANT ALL ON SCHEMA user1 TO user1;
GRANT
db1=# \c - user1
You are now connected to database "db1" as user "user1".
db1=> CREATE TABLE t1(a int);
CREATE TABLE
db1=> \c - user2
You are now connected to database "db1" as user "user2".
db1=> CREATE TABLE t2(a int);
ERROR:  no schema has been selected to create in
LINE 1: create table t2(a int);
                     ^
db1=> 
```

Instead of creating the schema and granting all privileges on it to `user1`, you may want to grant the `CREATE` privilege on the database, and let the `user1` create its schema itself (so that the user become its owner and will thereby get all the privileges on it)
```
postgres=# \c template1
You are now connected to database "template1" as user "postgres".
template1=# REVOKE CREATE ON SCHEMA public FROM public;
REVOKE
postgres=# CREATE USER user1 PASSWORD 'password';
CREATE ROLE
postgres=# CREATE USER user2 PASSWORD 'password';
CREATE ROLE
postgres=# CREATE DATABASE db1;
CREATE DATABASE
postgres=# GRANT ALL PRIVILEGES ON DATABASE db1 TO user1;
GRANT
postgres=# \c db1 user1
You are now connected to database "db1" as user "user1".
db1=> CREATE SCHEMA user1;
CREATE SCHEMA
db1=> CREATE TABLE t1(a int);
CREATE TABLE
db1=> \c - user2
You are now connected to database "db1" as user "user2".
db1=> CREATE TABLE t2(a int);
ERROR:  no schema has been selected to create in
LINE 1: create table t2(a int);
                     ^
db1=> 
```
In both cases the table is created in the schema `user1`
```
db1-> \dt
       List of relations
 Schema | Name | Type  | Owner 
--------+------+-------+-------
 user1  | t1   | table | user1
(1 row)

```

## PostgreSQL: Changing the ownership of the public schema
A shorter way to achieve the same result, without modifying the `template1` database and without creating an additional schema, is setting ownership for the `public` schema on database `db1` to `user1`
```
postgres=# CREATE USER user1 PASSWORD 'password';
CREATE ROLE
postgres=# CREATE USER user2 PASSWORD 'password';
CREATE ROLE
postgres=# CREATE DATABASE db1 OWNER user1;
CREATE DATABASE
postgres=# \c db1
You are now connected to database "db1" as user "postgres".
db1=# ALTER SCHEMA public OWNER TO user1;
ALTER SCHEMA
db1=# REVOKE CREATE ON SCHEMA public FROM public;
REVOKE
db1=# \c db1 user1
You are now connected to database "db1" as user "user1".
db1=> CREATE TABLE t1(a int);
CREATE TABLE
db1=> \c - user2
You are now connected to database "db1" as user "user2".
db1=> CREATE TABLE t2(a int);
ERROR:  no schema has been selected to create in
LINE 1: create table t2(a int);
                     ^
db1=> 
```

See also:
* [Schema privileges vs Database privileges in PostgreSQL](https://stackoverflow.com/questions/72152705/schema-privileges-vs-database-privileges-in-postgresql)