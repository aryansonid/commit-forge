package main

import (
	"log"

	"commit-forge/config"
	"commit-forge/server"
)

func main() {
	cfg := config.Load()
	if err := cfg.Validate(); err != nil {
		log.Fatalf("invalid configuration: %v", err)
	}

	srv := server.New(cfg)
	if err := srv.Start(); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}
