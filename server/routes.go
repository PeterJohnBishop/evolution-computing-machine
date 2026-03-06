package server

import (
	"evolution-computing-machine/server/storage"

	"github.com/gin-gonic/gin"
)

func AddChannelRoutes(r *gin.Engine) {
	v1 := r.Group("/v1")
	v1.POST("/channel", storage.HandleChannelCreation)
	v1.GET("/channel/:id", storage.HandleGetChannelById)
	v1.GET("/channel/all", storage.HandleGetAllChannels)
	v1.PUT("/channel/:id", storage.HandleChannelUpdate)
	v1.DELETE("/channel/:id", storage.HandleDeleteChannel)
}

func AddMessageRoutes(r *gin.Engine) {
	v1 := r.Group("/v1")
	v1.POST("/message", storage.HandleCreateMessage)
	v1.GET("/message/all/channel/:id", storage.HandleGetChannelMessages)
	v1.DELETE("/message/:id", storage.HandleDeleteMessage)
}
