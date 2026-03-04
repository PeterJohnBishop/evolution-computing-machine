package websocket

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type WSMessage struct {
	Type     string `json:"type"`
	TargetID string `json:"target_id"`
	Content  string `json:"content"`
	Sender   string `json:"sender"`
	SenderID string `json:"sender_id"`
	Channel  string `json:"channel"`
}

type Client struct {
	ID   string
	Name string
	Conn *websocket.Conn
	Send chan WSMessage
}

type Hub struct {
	Clients            map[string]*Client
	Channels           map[string]map[*Client]bool
	Register           chan *Client
	Unregister         chan *Client
	Broadcast          chan WSMessage
	Direct             chan WSMessage
	ChannelCollection  *mongo.Collection
	MessagesCollection *mongo.Collection
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func NewHub(chColl *mongo.Collection, msgColl *mongo.Collection) *Hub {
	return &Hub{
		Clients:            make(map[string]*Client),
		Channels:           make(map[string]map[*Client]bool),
		Register:           make(chan *Client),
		Unregister:         make(chan *Client),
		Broadcast:          make(chan WSMessage),
		Direct:             make(chan WSMessage),
		ChannelCollection:  chColl,
		MessagesCollection: msgColl,
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			if existingClient, ok := h.Clients[client.ID]; ok {
				log.Printf("Duplicate ID detected: %s. Closing old connection.", client.ID)
				close(existingClient.Send)
				existingClient.Conn.Close()
				delete(h.Clients, client.ID)
			}
			h.Clients[client.ID] = client

		case client := <-h.Unregister:
			if _, ok := h.Clients[client.ID]; ok {
				delete(h.Clients, client.ID)

				// remove client from all channels they were in
				for _, clientsInChannel := range h.Channels {
					delete(clientsInChannel, client)
				}
				close(client.Send)
			}

		case msg := <-h.Broadcast:
			for id, client := range h.Clients {
				select {
				case client.Send <- msg:
				default:
					close(client.Send)
					delete(h.Clients, id)
				}
			}

		case msg := <-h.Direct:
			if client, ok := h.Clients[msg.TargetID]; ok {
				select {
				case client.Send <- msg:
				default:
					close(client.Send)
					delete(h.Clients, msg.TargetID)
				}
			}
		}
	}
}

// broadcast to all
func handleBroadcast(hub *Hub, msg WSMessage) {
	fmt.Printf("handleBroadcast recieved: %s", msg)
	hub.Broadcast <- msg
}

// process then broadcast
func handleProcessedBroadcast(hub *Hub, msg WSMessage) {
	fmt.Printf("handleProcessedBroadcast recieved: %s", msg)
	msg.Content = "ALARM: " + msg.Content // Example processing
	hub.Broadcast <- msg
}

// broadcast direct to client x
func handlePrivate(hub *Hub, msg WSMessage) {
	fmt.Printf("handlePrivate recieved: %s", msg)
	hub.Direct <- msg
}

// process then broadcast to client x
func handleProcessedPrivate(hub *Hub, msg WSMessage) {
	fmt.Printf("handleProcessedPrivate recieved: %s", msg)
	msg.Content = "SECURE MSG: " + msg.Content // Example processing
	hub.Direct <- msg
}

// broadcast to channel
func handleChannelBroadcast(hub *Hub, msg WSMessage, sender *Client) {
	fmt.Printf("handleChannelBroadcast received: %s from %s\n", msg.Channel, sender.Name)

	// check if channel exists, if not, create it
	if _, ok := hub.Channels[msg.Channel]; !ok {
		hub.Channels[msg.Channel] = make(map[*Client]bool)
		log.Printf("Created new channel: %s", msg.Channel)
	}

	// add sender to the channel
	hub.Channels[msg.Channel][sender] = true

	// broadcast message to everyone in that specific channel
	for client := range hub.Channels[msg.Channel] {
		select {
		case client.Send <- msg:
		default:
			close(client.Send)
			delete(hub.Clients, client.ID)
			delete(hub.Channels[msg.Channel], client)
		}
	}
}

func (c *Client) ReadPump(hub *Hub) {
	defer func() {
		hub.Unregister <- c
		c.Conn.Close()
	}()

	for {
		var msg WSMessage
		err := c.Conn.ReadJSON(&msg)
		if err != nil {
			log.Printf("Read error for client %s: %v", c.ID, err)
			break
		}
		msg.Sender = c.Name
		msg.SenderID = c.ID
		fmt.Printf("Parsed Message: Type=%s, Content=%s, Sender=%s\n", msg.Type, msg.Content, msg.Sender)

		// ROUTING LOGIC
		switch msg.Type {
		case "broadcast":
			handleBroadcast(hub, msg)
		case "broadcast_special":
			handleProcessedBroadcast(hub, msg)
		case "private":
			handlePrivate(hub, msg)
		case "private_special":
			handleProcessedPrivate(hub, msg)
		case "channel_broadcast":
			handleChannelBroadcast(hub, msg, c)
		}
	}
}

func (c *Client) WritePump() {
	for msg := range c.Send {
		c.Conn.WriteJSON(msg)
	}
}

func HandleWebsocket(name string, id string, hub *Hub, ctx *gin.Context) {
	conn, err := upgrader.Upgrade(ctx.Writer, ctx.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed for user %s: %v", id, err)
		return
	}

	client := &Client{
		Name: name,
		ID:   id,
		Conn: conn,
		Send: make(chan WSMessage, 256),
	}

	hub.Register <- client

	go client.WritePump()
	go client.ReadPump(hub)
}
