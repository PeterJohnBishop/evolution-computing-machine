package storage

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type Channel struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Name        string             `bson:"name" json:"name"`
	Description string             `bson:"description" json:"description"`
	UserIDs     []string           `bson:"user_ids" json:"user_ids"`
	CreatedAt   time.Time          `bson:"created_at" json:"created_at"`
}

func CreateChannel(ch Channel, channelCollection *mongo.Collection) (*mongo.InsertOneResult, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	ch.ID = primitive.NewObjectID()

	ch.CreatedAt = time.Now()

	return channelCollection.InsertOne(ctx, ch)
}

func GetChannel(name string, channelCollection *mongo.Collection) (Channel, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var ch Channel
	err := channelCollection.FindOne(ctx, bson.M{"name": name}).Decode(&ch)
	return ch, err
}

func GetAllChannels(channelCollection *mongo.Collection) ([]Channel, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var channels []Channel

	cursor, err := channelCollection.Find(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("error finding querying channels: %v", err)
	}

	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &channels); err != nil {
		return nil, fmt.Errorf("error decoding channels: %v", err)
	}

	if channels == nil {
		channels = []Channel{}
	}

	return channels, nil
}

func UpdateChannel(id string, update bson.M, channelCollection *mongo.Collection) (*mongo.UpdateResult, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	objID, _ := primitive.ObjectIDFromHex(id)
	return channelCollection.UpdateOne(ctx, bson.M{"_id": objID}, bson.M{"$set": update})
}

func DeleteChannel(id primitive.ObjectID, channelCollection *mongo.Collection) (*mongo.DeleteResult, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return channelCollection.DeleteOne(ctx, bson.M{"_id": id})
}
