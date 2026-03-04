package storage

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Channel represents a chat room
type Channel struct {
	ID          primitive.ObjectID   `bson:"_id,omitempty"`
	Name        string               `bson:"name"`
	Description string               `bson:"description"`
	UserIDs     []primitive.ObjectID `bson:"user_ids"`
	CreatedAt   time.Time            `bson:"created_at"`
}

// Message represents a single chat entry
type Message struct {
	ID        primitive.ObjectID `bson:"_id,omitempty"`
	Channel   primitive.ObjectID `bson:"channel"`
	SenderID  primitive.ObjectID `bson:"sender_id"`
	Content   string             `bson:"content"`
	Timestamp time.Time          `bson:"timestamp"`
}
