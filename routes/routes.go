package routes

import (
	"net/http"

	"commit-forge/handlers"
)

// Register wires up all HTTP routes to their handlers.
func Register(mux *http.ServeMux) {
	mux.HandleFunc("/", handlers.Root)
	mux.HandleFunc("/healthz", handlers.Health)
	mux.HandleFunc("/readyz", handlers.Ready)
	mux.HandleFunc("/version", handlers.Version)
	mux.HandleFunc("/rewrite-commits", handlers.Rewrite)
}
