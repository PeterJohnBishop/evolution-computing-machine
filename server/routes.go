package server

import (
	"evolution-computing-machine/server/storage"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

func AddChannelRoutes(r *gin.Engine, channelCollection *mongo.Collection) {
	v1 := r.Group("/v1")
	v1.POST("/channel", storage.HandleChannelCreation(channelCollection))
	v1.GET("/channel/:name", storage.HandleGetChannelByName(channelCollection))
	v1.GET("/channel/all", storage.HandleGetAllChannels(channelCollection))
	v1.PUT("/channel/:id", storage.HandleChannelUpdate(channelCollection))
	v1.DELETE("/channel/:id", storage.HandleDeleteChannel(channelCollection))
}

func AddMessageRoutes(r *gin.Engine) {
	v1 := r.Group("/v1")
	v1.POST("/message", storage.HandleCreateMessage)
	v1.GET("/message/all/channel/:id", storage.HandleGetChannelMessages)
	v1.DELETE("/message/:id", storage.HandleDeleteMessage)
}
