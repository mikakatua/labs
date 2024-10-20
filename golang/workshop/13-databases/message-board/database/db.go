package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

const users = `
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		name VARCHAR(80) NOT NULL,
		email VARCHAR(80) UNIQUE
	)
`

const messages = `
	CREATE TABLE IF NOT EXISTS messages (
		id SERIAL PRIMARY KEY,
		user_id int NOT NULL REFERENCES users(id),
		content VARCHAR(280),
		timestamp TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp
	)
`

var (
	host     = os.Getenv("DB_HOST")
	port     = os.Getenv("DB_PORT")
	user     = os.Getenv("DB_USER")
	password = os.Getenv("DB_PASSWORD")
	dbname   = os.Getenv("DB_NAME")
	schema   = os.Getenv("DB_SCHEMA")
)

var DBConn *sql.DB

// Initialize the database connection
func Initialize() error {
	var err error
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s search_path=%s sslmode=disable", host, port, user, password, dbname, schema)

	DBConn, err = sql.Open("postgres", dsn)
	if err != nil {
		return fmt.Errorf("error opening database connection: %v", err)
	}

	// Check the connection
	if err = DBConn.Ping(); err != nil {
		return fmt.Errorf("error connecting to the database: %v", err)
	}

	log.Println("Database connected successfully!")

	// Create users table
	_, err = DBConn.Exec(users)
	if err != nil {
		log.Println("Eror creatig table users.", err)
	}

	// Create messages table
	_, err = DBConn.Exec(messages)
	if err != nil {
		log.Println("Error creating table messages.", err)
	}

	log.Println("All tables created/initialized successfully!")

	return nil
}
