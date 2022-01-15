package server

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
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
		middleware.SecurityHeaders,
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

// Start begins serving HTTP traffic with graceful shutdown.
func (s *Server) Start() error {
	errCh := make(chan error, 1)

	go func() {
		log.Printf("Starting server on %s ...", s.httpServer.Addr)
		errCh <- s.httpServer.ListenAndServe()
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-errCh:
		return err
	case sig := <-quit:
		log.Printf("Received signal %v, shutting down gracefully...", sig)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	return s.httpServer.Shutdown(ctx)
}
