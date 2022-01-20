package server

import (
	"log"
	"net/http"
	"time"

	"commit-forge/config"
	"commit-forge/middleware"
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

	chain := middleware.Chain(
		middleware.Recovery,
		middleware.RequestID,
		middleware.CORS(cfg.CORSAllowOrigins),
		middleware.Logging,
	)

	addr := ":" + cfg.Port

	return &Server{
		cfg: cfg,
		httpServer: &http.Server{
			Addr:         addr,
			Handler:      chain(mux),
			ReadTimeout:  15 * time.Second,
			WriteTimeout: cfg.RequestTimeout + 10*time.Second,
			IdleTimeout:  60 * time.Second,
		},
	}
}

// Start begins serving HTTP traffic.
func (s *Server) Start() error {
	log.Printf("Starting server on %s ...", s.httpServer.Addr)
	return s.httpServer.ListenAndServe()
}
