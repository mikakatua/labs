package main

import (
	"log"
	"message-board/database"
	"message-board/messages"
	"message-board/users"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize the database connection
	err := database.Initialize()
	if err != nil {
		log.Fatalf("Could not set up database: %v", err)
		os.Exit(1)
	}
	defer database.DBConn.Close()

	router := gin.Default()

	// Route the web root to serve SwaggerUI
	router.GET("/", func(c *gin.Context) {
		c.File("./static/index.html")
	})
	router.Static("/static", "./static")

	// User Management
	router.POST("/users", users.CreateUser)
	router.GET("/users/:id", users.GetUserById)
	router.PUT("/users/:id", users.UpdateUser)
	router.DELETE("/users/:id", users.DeleteUserById)
	router.GET("/users", users.GetAllUsers)

	// Message Management
	router.POST("/users/:id/messages", messages.PostUserMessage)
	router.GET("/users/:id/messages", messages.ListAllUserMessages)

	// Listen and serve on 0.0.0.0:8080
	router.Run(":8080")
}
