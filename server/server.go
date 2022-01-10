package server

import (
	"log"
	"net/http"
	"time"

	"commit-forge/config"
	"commit-forge/routes"
)

// Server wraps the HTTP server configuration.
type Server struct {
	httpServer *http.Server
	cfg        *config.Config
}

// New creates a new Server with routes and middleware wired up.
func New(cfg *config.Config) *Server {
	mux := http.NewServeMux()
	routes.Register(mux)

	addr := ":" + cfg.Port

	return &Server{
		cfg: cfg,
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
