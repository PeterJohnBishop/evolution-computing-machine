package storage

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// Channel Handler Functions

func HandleChannelCreation(c *gin.Context) {
	var ch Channel
	if err := c.ShouldBindJSON(&ch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "msg": "Invalid request body"})
		return
	}

	ch.CreatedAt = time.Now()

	result, err := CreateChannel(ch)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "msg": "Could not create channel"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"success": true, "id": result.InsertedID})
}

func HandleGetChannelById(c *gin.Context) {
	id := c.Param("id")

	if _, err := primitive.ObjectIDFromHex(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "msg": "Invalid ID format"})
		return
	}

	resp, err := GetChannel(id)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "msg": "Channel not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "msg": "Database error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "channel": resp})
}

func HandleGetAllChannels(c *gin.Context) {
	resp, err := GetAllChannels()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "msg": "Could not fetch channels"})
		return
	}

	if resp == nil {
		resp = []Channel{}
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "channels": resp})
}

func HandleChannelUpdate(c *gin.Context) {
	id := c.Param("id")

	var updateData bson.M
	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "msg": "Invalid request payload"})
		return
	}

	delete(updateData, "_id")

	result, err := UpdateChannel(id, updateData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "msg": "Failed to update channel"})
		return
	}

	if result.MatchedCount == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "msg": "Channel not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "msg": "Channel updated successfully"})
}

func HandleDeleteChannel(c *gin.Context) {
	id := c.Param("id")

	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "msg": "Invalid channel ID format"})
		return
	}

	result, err := DeleteChannel(objID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "msg": "Failed to delete channel"})
		return
	}

	if result.DeletedCount == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "msg": "Channel not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Channel deleted"})
}

// Message Handler Functions

func HandleCreateMessage(c *gin.Context) {
	var msg Message
	if err := c.ShouldBindJSON(&msg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid message format"})
		return
	}

	result, err := CreateMessage(msg)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"success": true, "id": result.InsertedID})
}

func HandleGetChannelMessages(c *gin.Context) {
	id := c.Param("id")

	if _, err := primitive.ObjectIDFromHex(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"succes": false, "msg": "Invalid channel ID format"})
		return
	}

	messages, err := GetMessagesByChannel(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"succes": false, "msg": "Failed to retrieve messages"})
		return
	}

	if messages == nil {
		messages = []Message{}
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "messages": messages})
}

func HandleDeleteMessage(c *gin.Context) {
	messageID := c.Param("id")

	if _, err := primitive.ObjectIDFromHex(messageID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"succes": false, "msg": "Invalid message ID format"})
		return
	}

	result, err := DeleteMessage(messageID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"succes": false, "msg": "Failed to delete message"})
		return
	}

	if result.DeletedCount == 0 {
		c.JSON(http.StatusNotFound, gin.H{"succes": false, "msg": "Message not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "msg": "Message deleted"})
}
