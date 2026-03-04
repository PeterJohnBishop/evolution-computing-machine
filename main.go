package main

import (
	"evolution-computing-machine/server"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

func main() {
	fmt.Println("[ evolution-computing-machine ]")

	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	mongoURI := os.Getenv("MONGODB_URI")
	port := os.Getenv("PORT")

	if mongoURI == "" {
		log.Fatal("MONGODB_URI not set in .env")
	}

	server.ServeGin(port, mongoURI)
}
