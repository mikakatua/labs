create database mydb;
create user myuser with encrypted password 'mypass';
alter database mydb owner to myuser;
\c mydb myuser
create table mytable(id int, name varchar);
insert into mytable values(1, 'First');
insert into mytable values(2, 'Second');
insert into mytable values(3, 'Third');
