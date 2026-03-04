package server

import (
	"evolution-computing-machine/server/storage"
	"evolution-computing-machine/server/websocket"
	"fmt"
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

var hub *websocket.Hub

func ServeGin(port string, uri string) {
	log.Println("Ordering Gin")

	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()
	r.Use(gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
			param.ClientIP,
			param.TimeStamp.Format(time.RFC1123),
			param.Method,
			param.Path,
			param.Request.Proto,
			param.StatusCode,
			param.Latency,
			param.Request.UserAgent(),
			param.ErrorMessage,
		)
	}))
	r.Use(gin.Recovery())

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"identity": "gin-server",
		})
	})

	hub := websocket.NewHub()
	go hub.Run()
	r.GET("/ws", func(c *gin.Context) {
		name := c.GetHeader("X-Client-Name")
		id := c.GetHeader("X-Device-ID")
		if id == "" {
			c.JSON(401, gin.H{"error": "ID not found in context"})
			return
		}
		if name == "" {
			// name = random name
		}
		log.Printf("%v connected to WebSocket", name)
		websocket.HandleWebsocket(name, id, hub, c)
	})

	go storage.ConnectDB(uri)

	if port == "" {
		port = "8080"
	}

	config := fmt.Sprintf(":%s", port)
	log.Printf("Serving Gin on port :%s", port)
	r.Run(config)
}
