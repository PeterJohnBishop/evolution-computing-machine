package storage

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type Message struct {
	ID        primitive.ObjectID `bson:"_id,omitempty"`
	Channel   primitive.ObjectID `bson:"channel"`
	SenderID  primitive.ObjectID `bson:"sender_id"`
	Content   string             `bson:"content"`
	Timestamp time.Time          `bson:"timestamp"`
}

var messageCollection *mongo.Collection

func CreateMessage(msg Message) (*mongo.InsertOneResult, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	msg.Timestamp = time.Now()
	return messageCollection.InsertOne(ctx, msg)
}

func GetMessagesByChannel(channelID string) ([]Message, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	objID, _ := primitive.ObjectIDFromHex(channelID)
	cursor, err := messageCollection.Find(ctx, bson.M{"channel": objID})
	if err != nil {
		return nil, err
	}

	var messages []Message
	if err = cursor.All(ctx, &messages); err != nil {
		return nil, err
	}
	return messages, nil
}

func DeleteMessage(messageID string) (*mongo.DeleteResult, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	objID, _ := primitive.ObjectIDFromHex(messageID)
	return messageCollection.DeleteOne(ctx, bson.M{"_id": objID})
}
