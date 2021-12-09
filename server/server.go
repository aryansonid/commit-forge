package server

import (
	"log"
	"net/http"
	"os"
	"time"

	"commit-forge/routes"
)

// Server wraps the HTTP server configuration.
type Server struct {
	httpServer *http.Server
}

// New creates a new Server with routes and middleware wired up.
func New() *Server {
	mux := http.NewServeMux()
	routes.Register(mux)

	// PORT from env, default 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	addr := ":" + port

	return &Server{
		httpServer: &http.Server{
			Addr:    addr,
			Handler: loggingMiddleware(mux),
		},
	}
}

// Start begins serving HTTP traffic.
func (s *Server) Start() error {
	log.Printf("Starting server on %s ...", s.httpServer.Addr)
	return s.httpServer.ListenAndServe()
}

// loggingMiddleware logs basic request information.
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(start))
	})
}
