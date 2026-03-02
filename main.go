package main

import (
	"log"

	"commit-forge/server"
)

func main() {
	srv := server.New()
	if err := srv.Start(); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}
