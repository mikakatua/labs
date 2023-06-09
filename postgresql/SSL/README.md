# PostgreSQL with client SSL certificate authentication
Requirements:
- Docker
- JDK 8 or newer

Download the PostgreSQL JDBC Driver from [here](https://jdbc.postgresql.org/download/postgresql-42.6.0.jar)

Compile the Java code
```
javac -cp postgresql-42.6.0.jar JdbcExample.java
```

Set up the certificates and config
```
./generatePostgresCertsKeysAndConf.sh
```

Start the PostgreSQL server
```
./runPostgreSQL.sh
```

Test connection (optional)
```
psql "port=5432 host=localhost dbname=mydb user=myuser sslcert=client.crt sslkey=client.key sslrootcert=root.crt sslmode=verify-full"
```

Execute the Java program
```
java -cp postgresql-42.6.0.jar:. JdbcExample
```
