package messages

import (
	"message-board/database"
	"message-board/users"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type Message struct {
	ID        int       `json:"id"`
	UserID    int       `json:"user_id"`
	Content   string    `json:"content"`
	Timestamp time.Time `json:"timestamp"`
}

func PostUserMessage(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Check if user exists
	exists, err := users.UserExists(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "The user does not exist"})
		return
	}

	var message Message
	message.UserID = id

	if err := c.ShouldBindJSON(&message); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	stmt, err := database.DBConn.Prepare("INSERT INTO messages (user_id, content) VALUES ($1, $2) RETURNING id, timestamp")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer stmt.Close()

	err = stmt.QueryRow(idParam, message.Content).Scan(&message.ID, &message.Timestamp)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, message)
}

func ListAllUserMessages(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Check if user exists
	exists, err := users.UserExists(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "The user does not exist"})
		return
	}

	rows, err := database.DBConn.Query("SELECT id, content, timestamp FROM messages WHERE user_id = $1", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list messages"})
		return
	}
	defer rows.Close()

	var messages []Message
	for rows.Next() {
		var message Message
		if err := rows.Scan(&message.ID, &message.Content, &message.Timestamp); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error scanning messages"})
			return
		}
		messages = append(messages, message)
	}

	c.JSON(http.StatusOK, messages)
}
