#!/bin/bash
set -e

# Helper to commit
commit() {
  git add -A
  git commit -m "$1"
}

# ── 1. Add .gitignore ──
cat > .gitignore << 'EOF'
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
commit-forge
server

# Test binary
*.test

# Output
*.out
*.prof

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
EOF
commit "chore: add .gitignore for Go project"

# ── 2. Add LICENSE ──
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Commit Forge

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
commit "chore: add MIT license"

# ── 3. Add .env.example ──
cat > .env.example << 'EOF'
PORT=8080
LOG_LEVEL=info
REQUEST_TIMEOUT=60m
MAX_RETRY_ATTEMPTS=5
CORS_ALLOWED_ORIGINS=*
EOF
commit "chore: add .env.example with default configuration"

# ── 4. Add Makefile ──
cat > Makefile << 'EOF'
.PHONY: build run test clean lint fmt vet docker-build docker-up docker-down

BINARY_NAME=commit-forge
GO=go

build:
	$(GO) build -o $(BINARY_NAME) .

run: build
	./$(BINARY_NAME)

test:
	$(GO) test ./... -v

clean:
	rm -f $(BINARY_NAME)
	$(GO) clean

lint:
	golangci-lint run ./...

fmt:
	$(GO) fmt ./...

vet:
	$(GO) vet ./...

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down
EOF
commit "chore: add Makefile with build, test, and docker targets"

# ── 5. Add config package - struct definition ──
mkdir -p config
cat > config/config.go << 'EOF'
package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all application configuration.
type Config struct {
	Port              string
	LogLevel          string
	RequestTimeout    time.Duration
	MaxRetryAttempts  int
	CORSAllowOrigins string
}
EOF
commit "feat: add config package with Config struct"

# ── 6. Add config loading from env ──
cat > config/config.go << 'EOF'
package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all application configuration.
type Config struct {
	Port              string
	LogLevel          string
	RequestTimeout    time.Duration
	MaxRetryAttempts  int
	CORSAllowOrigins string
}

// Load reads configuration from environment variables with defaults.
func Load() *Config {
	return &Config{
		Port:              getEnv("PORT", "8080"),
		LogLevel:          getEnv("LOG_LEVEL", "info"),
		RequestTimeout:    getDurationEnv("REQUEST_TIMEOUT", 60*time.Minute),
		MaxRetryAttempts:  getIntEnv("MAX_RETRY_ATTEMPTS", 5),
		CORSAllowOrigins: getEnv("CORS_ALLOWED_ORIGINS", "*"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getIntEnv(key string, fallback int) int {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	i, err := strconv.Atoi(v)
	if err != nil {
		return fallback
	}
	return i
}

func getDurationEnv(key string, fallback time.Duration) time.Duration {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return fallback
	}
	return d
}
EOF
commit "feat: add config.Load() with environment variable parsing"

# ── 7. Add config validation ──
cat >> config/config.go << 'EOF'

// Validate checks that the loaded config has valid values.
func (c *Config) Validate() error {
	if c.Port == "" {
		return ErrPortRequired
	}
	if c.MaxRetryAttempts < 1 {
		return ErrInvalidRetryAttempts
	}
	if c.RequestTimeout < time.Second {
		return ErrInvalidTimeout
	}
	return nil
}
EOF
commit "feat: add config validation method"

# ── 8. Add config errors ──
cat > config/errors.go << 'EOF'
package config

import "errors"

var (
	ErrPortRequired        = errors.New("config: port is required")
	ErrInvalidRetryAttempts = errors.New("config: max retry attempts must be >= 1")
	ErrInvalidTimeout      = errors.New("config: request timeout must be >= 1 second")
)
EOF
commit "feat: add config error constants"

# ── 9. Add config tests ──
cat > config/config_test.go << 'EOF'
package config

import (
	"os"
	"testing"
	"time"
)

func TestLoadDefaults(t *testing.T) {
	os.Clearenv()
	cfg := Load()

	if cfg.Port != "8080" {
		t.Errorf("expected port 8080, got %s", cfg.Port)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("expected log level info, got %s", cfg.LogLevel)
	}
	if cfg.MaxRetryAttempts != 5 {
		t.Errorf("expected 5 retries, got %d", cfg.MaxRetryAttempts)
	}
}

func TestLoadFromEnv(t *testing.T) {
	os.Setenv("PORT", "9090")
	os.Setenv("LOG_LEVEL", "debug")
	os.Setenv("MAX_RETRY_ATTEMPTS", "10")
	defer os.Clearenv()

	cfg := Load()

	if cfg.Port != "9090" {
		t.Errorf("expected port 9090, got %s", cfg.Port)
	}
	if cfg.LogLevel != "debug" {
		t.Errorf("expected log level debug, got %s", cfg.LogLevel)
	}
	if cfg.MaxRetryAttempts != 10 {
		t.Errorf("expected 10 retries, got %d", cfg.MaxRetryAttempts)
	}
}

func TestValidate(t *testing.T) {
	cfg := &Config{
		Port:             "8080",
		MaxRetryAttempts: 5,
		RequestTimeout:   60 * time.Minute,
	}
	if err := cfg.Validate(); err != nil {
		t.Errorf("valid config should not error: %v", err)
	}
}

func TestValidateInvalidPort(t *testing.T) {
	cfg := &Config{
		Port:             "",
		MaxRetryAttempts: 5,
		RequestTimeout:   60 * time.Minute,
	}
	if err := cfg.Validate(); err != ErrPortRequired {
		t.Errorf("expected ErrPortRequired, got %v", err)
	}
}

func TestValidateInvalidRetries(t *testing.T) {
	cfg := &Config{
		Port:             "8080",
		MaxRetryAttempts: 0,
		RequestTimeout:   60 * time.Minute,
	}
	if err := cfg.Validate(); err != ErrInvalidRetryAttempts {
		t.Errorf("expected ErrInvalidRetryAttempts, got %v", err)
	}
}
EOF
commit "test: add config package unit tests"

# ── 10. Integrate config into server ──
cat > server/server.go << 'EOF'
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
EOF
commit "refactor: update server to accept config dependency"

# ── 11. Update main.go to use config ──
cat > main.go << 'EOF'
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
EOF
commit "refactor: update main.go to load and validate config"

# ── 12. Add middleware package ──
mkdir -p middleware
cat > middleware/recovery.go << 'EOF'
package middleware

import (
	"log"
	"net/http"
	"runtime/debug"
)

// Recovery catches panics and returns 500 instead of crashing.
func Recovery(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("panic recovered: %v\n%s", err, debug.Stack())
				http.Error(w, "internal server error", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
EOF
commit "feat: add recovery middleware for panic handling"

# ── 13. Add request ID middleware ──
cat > middleware/requestid.go << 'EOF'
package middleware

import (
	"context"
	"crypto/rand"
	"fmt"
	"net/http"
)

type contextKey string

const RequestIDKey contextKey = "request_id"

// RequestID injects a unique ID into each request context and response header.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := generateID()
		ctx := context.WithValue(r.Context(), RequestIDKey, id)
		w.Header().Set("X-Request-ID", id)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func generateID() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return fmt.Sprintf("%x", b)
}
EOF
commit "feat: add request ID middleware"

# ── 14. Add CORS middleware ──
cat > middleware/cors.go << 'EOF'
package middleware

import "net/http"

// CORS adds basic CORS headers to responses.
func CORS(allowOrigin string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", allowOrigin)
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusNoContent)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
EOF
commit "feat: add CORS middleware"

# ── 15. Add rate limiting middleware ──
cat > middleware/ratelimit.go << 'EOF'
package middleware

import (
	"net/http"
	"sync"
	"time"
)

type visitor struct {
	lastSeen time.Time
	count    int
}

// RateLimiter limits requests per IP per window.
type RateLimiter struct {
	mu       sync.Mutex
	visitors map[string]*visitor
	limit    int
	window   time.Duration
}

// NewRateLimiter creates a new rate limiter.
func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		visitors: make(map[string]*visitor),
		limit:    limit,
		window:   window,
	}
	go rl.cleanup()
	return rl
}

// Middleware returns the HTTP middleware function.
func (rl *RateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := r.RemoteAddr

		rl.mu.Lock()
		v, exists := rl.visitors[ip]
		if !exists || time.Since(v.lastSeen) > rl.window {
			rl.visitors[ip] = &visitor{lastSeen: time.Now(), count: 1}
			rl.mu.Unlock()
			next.ServeHTTP(w, r)
			return
		}

		v.count++
		v.lastSeen = time.Now()
		if v.count > rl.limit {
			rl.mu.Unlock()
			http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
			return
		}
		rl.mu.Unlock()

		next.ServeHTTP(w, r)
	})
}

func (rl *RateLimiter) cleanup() {
	for {
		time.Sleep(rl.window)
		rl.mu.Lock()
		for ip, v := range rl.visitors {
			if time.Since(v.lastSeen) > rl.window {
				delete(rl.visitors, ip)
			}
		}
		rl.mu.Unlock()
	}
}
EOF
commit "feat: add rate limiting middleware"

# ── 16. Add middleware chain helper ──
cat > middleware/chain.go << 'EOF'
package middleware

import "net/http"

// Chain composes multiple middleware into a single middleware.
func Chain(middlewares ...func(http.Handler) http.Handler) func(http.Handler) http.Handler {
	return func(final http.Handler) http.Handler {
		for i := len(middlewares) - 1; i >= 0; i-- {
			final = middlewares[i](final)
		}
		return final
	}
}
EOF
commit "feat: add middleware chain helper"

# ── 17. Move logging middleware to middleware package ──
cat > middleware/logging.go << 'EOF'
package middleware

import (
	"log"
	"net/http"
	"time"
)

// Logging logs method, path, status, and duration for each request.
func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		wrapped := &statusWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(wrapped, r)
		log.Printf("%s %s %d %s", r.Method, r.URL.Path, wrapped.status, time.Since(start))
	})
}

type statusWriter struct {
	http.ResponseWriter
	status int
}

func (sw *statusWriter) WriteHeader(code int) {
	sw.status = code
	sw.ResponseWriter.WriteHeader(code)
}
EOF
commit "refactor: extract logging middleware to middleware package"

# ── 18. Wire middleware into server ──
cat > server/server.go << 'EOF'
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
EOF
commit "refactor: wire middleware chain into server"

# ── 19. Add graceful shutdown ──
cat > server/server.go << 'EOF'
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
EOF
commit "feat: add graceful shutdown on SIGINT/SIGTERM"

# ── 20. Add models package ──
mkdir -p models
cat > models/rewrite.go << 'EOF'
package models

// RewriteRequest defines the JSON payload expected by the rewrite API.
type RewriteRequest struct {
	SourceRepoURL    string `json:"source_repo_url"`
	DestRepoURL      string `json:"dest_repo_url"`
	DestRepoUsername string `json:"dest_repo_username,omitempty"`
	DestRepoPAT      string `json:"dest_repo_pat"`
	AuthorName       string `json:"author_name"`
	AuthorEmail      string `json:"author_email"`
	TargetBranch     string `json:"target_branch,omitempty"`
}
EOF
commit "refactor: extract RewriteRequest to models package"

# ── 21. Add response models ──
cat > models/response.go << 'EOF'
package models

// APIError represents a JSON error response.
type APIError struct {
	Error string `json:"error"`
}

// APISuccess represents a JSON success response.
type APISuccess struct {
	Message string `json:"message"`
}

// VersionInfo represents the version endpoint response.
type VersionInfo struct {
	Version string `json:"version"`
	Time    string `json:"time"`
}

// RouteInfo represents the root endpoint response.
type RouteInfo struct {
	Message       string `json:"message"`
	HealthRoute   string `json:"health_route"`
	VersionRoute  string `json:"version_route"`
	RewriteRoute  string `json:"rewrite_route"`
	ExampleMethod string `json:"example_method"`
}
EOF
commit "feat: add response models for API endpoints"

# ── 22. Add RewriteResponse model ──
cat >> models/rewrite.go << 'EOF'

// RewriteResponse is returned when a rewrite completes successfully.
type RewriteResponse struct {
	Message string `json:"message"`
	Branch  string `json:"branch"`
	DestURL string `json:"dest_url"`
}
EOF
commit "feat: add RewriteResponse model"

# ── 23. Update handler to use models ──
cat > handlers/basic.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"commit-forge/models"
)

const VERSION = "v0.3.0"

// Root is a simple landing handler describing available routes.
func Root(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, models.RouteInfo{
		Message:       "Welcome to Commit Forge",
		HealthRoute:   "/healthz",
		VersionRoute:  "/version",
		RewriteRoute:  "/rewrite-commits",
		ExampleMethod: "POST /rewrite-commits",
	})
}

// Health reports basic liveness.
func Health(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}

// Version reports service version information.
func Version(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, models.VersionInfo{
		Version: VERSION,
		Time:    time.Now().UTC().Format(time.RFC3339),
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeJSONError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, models.APIError{Error: msg})
}
EOF
commit "refactor: update basic handlers to use response models"

# ── 24. Bump version constant ──
sed -i '' 's/VERSION = "v0.3.0"/VERSION = "v0.4.0"/' handlers/basic.go
commit "chore: bump version to v0.4.0"

# ── 25. Add validation package ──
mkdir -p validation
cat > validation/rewrite.go << 'EOF'
package validation

import (
	"errors"
	"strings"

	"commit-forge/models"
)

var (
	ErrSourceURLRequired = errors.New("source_repo_url is required")
	ErrDestURLRequired   = errors.New("dest_repo_url is required")
	ErrPATRequired       = errors.New("dest_repo_pat is required")
	ErrAuthorRequired    = errors.New("author_name is required")
	ErrEmailRequired     = errors.New("author_email is required")
)

// ValidateRewriteRequest checks that all required fields are present.
func ValidateRewriteRequest(req *models.RewriteRequest) error {
	if strings.TrimSpace(req.SourceRepoURL) == "" {
		return ErrSourceURLRequired
	}
	if strings.TrimSpace(req.DestRepoURL) == "" {
		return ErrDestURLRequired
	}
	if strings.TrimSpace(req.DestRepoPAT) == "" {
		return ErrPATRequired
	}
	if strings.TrimSpace(req.AuthorName) == "" {
		return ErrAuthorRequired
	}
	if strings.TrimSpace(req.AuthorEmail) == "" {
		return ErrEmailRequired
	}
	return nil
}
EOF
commit "refactor: extract request validation to validation package"

# ── 26. Add validation tests ──
cat > validation/rewrite_test.go << 'EOF'
package validation

import (
	"testing"

	"commit-forge/models"
)

func TestValidateRewriteRequest_Valid(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorName:    "Test User",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != nil {
		t.Errorf("valid request should not error: %v", err)
	}
}

func TestValidateRewriteRequest_MissingSource(t *testing.T) {
	req := &models.RewriteRequest{
		DestRepoURL: "https://github.com/user/repo.git",
		DestRepoPAT: "ghp_test123",
		AuthorName:  "Test User",
		AuthorEmail: "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrSourceURLRequired {
		t.Errorf("expected ErrSourceURLRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingDest(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorName:    "Test User",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrDestURLRequired {
		t.Errorf("expected ErrDestURLRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingPAT(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		AuthorName:    "Test User",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrPATRequired {
		t.Errorf("expected ErrPATRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingAuthor(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrAuthorRequired {
		t.Errorf("expected ErrAuthorRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingEmail(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorName:    "Test User",
	}
	if err := ValidateRewriteRequest(req); err != ErrEmailRequired {
		t.Errorf("expected ErrEmailRequired, got %v", err)
	}
}
EOF
commit "test: add validation package unit tests"

# ── 27. Add git operations package ──
mkdir -p git
cat > git/clone.go << 'EOF'
package git

import (
	"context"
	"path/filepath"
)

// Clone clones a repository into a subdirectory of baseDir.
func Clone(ctx context.Context, baseDir, repoURL, branch string) (string, error) {
	repoDir := filepath.Join(baseDir, "repo")
	args := []string{"clone", "--no-tags", "--single-branch", "--branch", branch, "--progress", repoURL, repoDir}
	if err := RunCmd(ctx, baseDir, "git", args...); err != nil {
		return "", err
	}
	return repoDir, nil
}
EOF
commit "refactor: extract git clone operation to git package"

# ── 28. Add git push operation ──
cat > git/push.go << 'EOF'
package git

import (
	"context"
	"log"
	"time"
)

// PushWithRetry pushes to remote with exponential backoff retries.
func PushWithRetry(ctx context.Context, repoDir, branch string, maxAttempts int) error {
	pushRef := "HEAD:refs/heads/" + branch
	retryDelay := 5 * time.Second

	for attempt := 1; ; attempt++ {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		err := RunCmd(ctx, repoDir, "git", "push", "--force-with-lease", "origin", pushRef)
		if err == nil {
			if attempt > 1 {
				log.Printf("push succeeded on attempt %d", attempt)
			}
			return nil
		}

		if attempt >= maxAttempts {
			return err
		}

		backoff := retryDelay * time.Duration(attempt)
		if backoff > 60*time.Second {
			backoff = 60 * time.Second
		}
		log.Printf("push failed (attempt %d/%d), retrying in %v: %v", attempt, maxAttempts, backoff, err)

		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(backoff):
		}
	}
}
EOF
commit "refactor: extract git push with retry to git package"

# ── 29. Add git command runner ──
cat > git/cmd.go << 'EOF'
package git

import (
	"context"
	"log"
	"os"
	"os/exec"
	"strings"
)

// RunCmd executes a command with the default environment.
func RunCmd(ctx context.Context, dir, name string, args ...string) error {
	return RunCmdWithEnv(ctx, dir, os.Environ(), name, args...)
}

// RunCmdWithEnv executes a command with a custom environment.
func RunCmdWithEnv(ctx context.Context, dir string, env []string, name string, args ...string) error {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Dir = dir
	cmd.Env = env

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("command failed: %s %s\nin dir: %s\noutput:\n%s", name, strings.Join(args, " "), dir, string(output))
		return err
	}

	log.Printf("command succeeded: %s %s\nin dir: %s\noutput:\n%s", name, strings.Join(args, " "), dir, string(output))
	return nil
}
EOF
commit "refactor: extract command runner to git package"

# ── 30. Add git filter-branch operation ──
cat > git/filter.go << 'EOF'
package git

import (
	"context"
	"log"
	"os"
	"os/exec"
	"strings"
)

// FilterBranchRewriteAuthor rewrites all commits on a branch with new author info.
func FilterBranchRewriteAuthor(ctx context.Context, repoDir, branch, authorName, authorEmail string) error {
	env := append(os.Environ(),
		"NEW_AUTHOR_NAME="+authorName,
		"NEW_AUTHOR_EMAIL="+authorEmail,
	)

	filterScript := `
export GIT_AUTHOR_NAME="$NEW_AUTHOR_NAME"
export GIT_AUTHOR_EMAIL="$NEW_AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$NEW_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$NEW_AUTHOR_EMAIL"
`
	filterCmd := "git filter-branch --env-filter '" + strings.TrimSpace(filterScript) + "' --tag-name-filter cat -- " + branch

	return RunCmdWithEnv(ctx, repoDir, env, "bash", "-lc", filterCmd)
}

// CleanupFilterBranchBackups removes refs/original and runs gc.
func CleanupFilterBranchBackups(ctx context.Context, dir string) error {
	cmd := exec.CommandContext(ctx, "git", "for-each-ref", "--format=%(refname)", "refs/original/")
	cmd.Dir = dir
	cmd.Env = os.Environ()

	out, err := cmd.Output()
	if err != nil {
		log.Printf("warning: failed to list refs/original for cleanup: %v", err)
	} else {
		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		for _, ref := range lines {
			ref = strings.TrimSpace(ref)
			if ref == "" {
				continue
			}
			if err := RunCmd(ctx, dir, "git", "update-ref", "-d", ref); err != nil {
				log.Printf("warning: failed to delete backup ref %s: %v", ref, err)
			}
		}
	}

	if err := RunCmd(ctx, dir, "git", "reflog", "expire", "--expire=now", "--all"); err != nil {
		log.Printf("warning: git reflog expire failed: %v", err)
	}

	return RunCmd(ctx, dir, "git", "gc", "--prune=now")
}
EOF
commit "refactor: extract filter-branch operations to git package"

# ── 31. Add git remote helpers ──
cat > git/remote.go << 'EOF'
package git

import (
	"context"
	"errors"
	"net/url"
)

// SetRemoteOrigin replaces the origin remote with a new URL.
func SetRemoteOrigin(ctx context.Context, repoDir, remoteURL string) error {
	_ = RunCmd(ctx, repoDir, "git", "remote", "remove", "origin")
	return RunCmd(ctx, repoDir, "git", "remote", "add", "origin", remoteURL)
}

// BuildAuthenticatedURL injects credentials into a repo URL.
func BuildAuthenticatedURL(rawURL, username, pat string) (string, error) {
	u, err := url.Parse(rawURL)
	if err != nil {
		return "", err
	}
	if u.Scheme != "https" && u.Scheme != "http" {
		return "", errors.New("only http/https URLs are supported for dest_repo_url")
	}
	u.User = url.UserPassword(username, pat)
	return u.String(), nil
}
EOF
commit "refactor: extract remote helpers to git package"

# ── 32. Update rewrite handler to use new packages ──
cat > handlers/rewrite.go << 'EOF'
package handlers

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"commit-forge/git"
	"commit-forge/models"
	"commit-forge/validation"
)

// Rewrite handles POST /rewrite-commits requests.
func Rewrite(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.RewriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if err := validation.ValidateRewriteRequest(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 60*time.Minute)
	defer cancel()

	if err := processRewrite(ctx, &req); err != nil {
		log.Printf("rewrite failed: %v", err)
		writeJSONError(w, http.StatusInternalServerError, err.Error())
		return
	}

	branch := strings.TrimSpace(req.TargetBranch)
	if branch == "" {
		branch = "main"
	}

	writeJSON(w, http.StatusOK, models.RewriteResponse{
		Message: "repository rewritten and pushed successfully",
		Branch:  branch,
		DestURL: req.DestRepoURL,
	})
}

func processRewrite(ctx context.Context, req *models.RewriteRequest) error {
	tmpDir, err := os.MkdirTemp("", "rewrite-repo-*")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmpDir)

	log.Printf("Using temp directory: %s", tmpDir)

	branch := strings.TrimSpace(req.TargetBranch)
	if branch == "" {
		branch = "main"
	}

	repoDir, err := git.Clone(ctx, tmpDir, req.SourceRepoURL, branch)
	if err != nil {
		return err
	}

	if err := git.FilterBranchRewriteAuthor(ctx, repoDir, branch, req.AuthorName, req.AuthorEmail); err != nil {
		return err
	}

	if err := git.CleanupFilterBranchBackups(ctx, repoDir); err != nil {
		log.Printf("warning: cleanup after filter-branch failed: %v", err)
	}

	username := strings.TrimSpace(req.DestRepoUsername)
	if username == "" {
		username = strings.TrimSpace(req.AuthorName)
	}

	authURL, err := git.BuildAuthenticatedURL(req.DestRepoURL, username, req.DestRepoPAT)
	if err != nil {
		return err
	}

	if err := git.SetRemoteOrigin(ctx, repoDir, authURL); err != nil {
		return err
	}

	return git.PushWithRetry(ctx, repoDir, branch, 5)
}
EOF
commit "refactor: update rewrite handler to use git and validation packages"

# ── 33. Add handler tests - basic handlers ──
cat > handlers/basic_test.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"commit-forge/models"
)

func TestRootHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	Root(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}

	var body models.RouteInfo
	if err := json.NewDecoder(rr.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body.Message != "Welcome to Commit Forge" {
		t.Errorf("unexpected message: %s", body.Message)
	}
}

func TestRootHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	rr := httptest.NewRecorder()

	Root(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := httptest.NewRecorder()

	Health(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}
	if rr.Body.String() != "ok" {
		t.Errorf("expected body 'ok', got %s", rr.Body.String())
	}
}

func TestHealthHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/healthz", nil)
	rr := httptest.NewRecorder()

	Health(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}

func TestVersionHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/version", nil)
	rr := httptest.NewRecorder()

	Version(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}

	var body models.VersionInfo
	if err := json.NewDecoder(rr.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body.Version != VERSION {
		t.Errorf("expected version %s, got %s", VERSION, body.Version)
	}
}

func TestVersionHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodDelete, "/version", nil)
	rr := httptest.NewRecorder()

	Version(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}
EOF
commit "test: add basic handler unit tests"

# ── 34. Add rewrite handler tests ──
cat > handlers/rewrite_test.go << 'EOF'
package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestRewriteMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/rewrite-commits", nil)
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}

func TestRewriteInvalidJSON(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/rewrite-commits", strings.NewReader("not json"))
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", rr.Code)
	}
}

func TestRewriteMissingFields(t *testing.T) {
	body := `{"source_repo_url": "https://github.com/test/repo.git"}`
	req := httptest.NewRequest(http.MethodPost, "/rewrite-commits", strings.NewReader(body))
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", rr.Code)
	}
}

func TestRewriteEmptyBody(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/rewrite-commits", strings.NewReader("{}"))
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", rr.Code)
	}
}
EOF
commit "test: add rewrite handler unit tests"

# ── 35. Add middleware tests - recovery ──
cat > middleware/recovery_test.go << 'EOF'
package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRecoveryMiddleware(t *testing.T) {
	handler := Recovery(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		panic("test panic")
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("expected status 500, got %d", rr.Code)
	}
}

func TestRecoveryMiddlewareNoPanic(t *testing.T) {
	handler := Recovery(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}
}
EOF
commit "test: add recovery middleware unit tests"

# ── 36. Add middleware tests - request ID ──
cat > middleware/requestid_test.go << 'EOF'
package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRequestIDMiddleware(t *testing.T) {
	handler := RequestID(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Context().Value(RequestIDKey)
		if id == nil {
			t.Error("request ID not found in context")
		}
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Header().Get("X-Request-ID") == "" {
		t.Error("X-Request-ID header not set")
	}
}

func TestRequestIDUniqueness(t *testing.T) {
	handler := RequestID(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req1 := httptest.NewRequest(http.MethodGet, "/", nil)
	rr1 := httptest.NewRecorder()
	handler.ServeHTTP(rr1, req1)

	req2 := httptest.NewRequest(http.MethodGet, "/", nil)
	rr2 := httptest.NewRecorder()
	handler.ServeHTTP(rr2, req2)

	id1 := rr1.Header().Get("X-Request-ID")
	id2 := rr2.Header().Get("X-Request-ID")

	if id1 == id2 {
		t.Error("request IDs should be unique")
	}
}
EOF
commit "test: add request ID middleware unit tests"

# ── 37. Add middleware tests - CORS ──
cat > middleware/cors_test.go << 'EOF'
package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestCORSMiddleware(t *testing.T) {
	handler := CORS("*")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Header().Get("Access-Control-Allow-Origin") != "*" {
		t.Error("CORS origin header not set")
	}
}

func TestCORSPreflight(t *testing.T) {
	handler := CORS("https://example.com")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodOptions, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Errorf("expected status 204 for preflight, got %d", rr.Code)
	}
	if rr.Header().Get("Access-Control-Allow-Origin") != "https://example.com" {
		t.Error("CORS origin not set correctly for preflight")
	}
}
EOF
commit "test: add CORS middleware unit tests"

# ── 38. Add middleware tests - chain ──
cat > middleware/chain_test.go << 'EOF'
package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestChain(t *testing.T) {
	var order []string

	m1 := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			order = append(order, "m1-before")
			next.ServeHTTP(w, r)
			order = append(order, "m1-after")
		})
	}

	m2 := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			order = append(order, "m2-before")
			next.ServeHTTP(w, r)
			order = append(order, "m2-after")
		})
	}

	handler := Chain(m1, m2)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		order = append(order, "handler")
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	expected := []string{"m1-before", "m2-before", "handler", "m2-after", "m1-after"}
	if len(order) != len(expected) {
		t.Fatalf("expected %d calls, got %d", len(expected), len(order))
	}
	for i, v := range expected {
		if order[i] != v {
			t.Errorf("position %d: expected %s, got %s", i, v, order[i])
		}
	}
}
EOF
commit "test: add middleware chain unit tests"

# ── 39. Add git package tests ──
cat > git/remote_test.go << 'EOF'
package git

import "testing"

func TestBuildAuthenticatedURL(t *testing.T) {
	url, err := BuildAuthenticatedURL("https://github.com/user/repo.git", "myuser", "mytoken")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	expected := "https://myuser:mytoken@github.com/user/repo.git"
	if url != expected {
		t.Errorf("expected %s, got %s", expected, url)
	}
}

func TestBuildAuthenticatedURLHTTP(t *testing.T) {
	url, err := BuildAuthenticatedURL("http://gitlab.local/user/repo.git", "admin", "pass")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	expected := "http://admin:pass@gitlab.local/user/repo.git"
	if url != expected {
		t.Errorf("expected %s, got %s", expected, url)
	}
}

func TestBuildAuthenticatedURLInvalidScheme(t *testing.T) {
	_, err := BuildAuthenticatedURL("ssh://git@github.com/user/repo.git", "user", "token")
	if err == nil {
		t.Error("expected error for ssh scheme")
	}
}

func TestBuildAuthenticatedURLInvalidURL(t *testing.T) {
	_, err := BuildAuthenticatedURL("://invalid", "user", "token")
	if err == nil {
		t.Error("expected error for invalid URL")
	}
}
EOF
commit "test: add git remote helper unit tests"

# ── 40. Add content-type middleware ──
cat > middleware/contenttype.go << 'EOF'
package middleware

import "net/http"

// ContentType sets a default Content-Type header if one is not already set.
func ContentType(contentType string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if w.Header().Get("Content-Type") == "" {
				w.Header().Set("Content-Type", contentType)
			}
			next.ServeHTTP(w, r)
		})
	}
}
EOF
commit "feat: add content-type middleware"

# ── 41. Add security headers middleware ──
cat > middleware/security.go << 'EOF'
package middleware

import "net/http"

// SecurityHeaders sets common security headers.
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		next.ServeHTTP(w, r)
	})
}
EOF
commit "feat: add security headers middleware"

# ── 42. Wire security headers into server ──
cat > server/server.go << 'EOF'
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
EOF
commit "feat: wire security headers middleware into server"

# ── 43. Add readiness endpoint ──
cat > handlers/basic.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"sync/atomic"
	"time"

	"commit-forge/models"
)

const VERSION = "v0.4.0"

var ready atomic.Bool

// SetReady marks the service as ready to accept traffic.
func SetReady() { ready.Store(true) }

// Root is a simple landing handler describing available routes.
func Root(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, models.RouteInfo{
		Message:       "Welcome to Commit Forge",
		HealthRoute:   "/healthz",
		VersionRoute:  "/version",
		RewriteRoute:  "/rewrite-commits",
		ExampleMethod: "POST /rewrite-commits",
	})
}

// Health reports basic liveness.
func Health(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}

// Ready reports whether the service is ready for traffic.
func Ready(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if !ready.Load() {
		http.Error(w, "not ready", http.StatusServiceUnavailable)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ready"))
}

// Version reports service version information.
func Version(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, models.VersionInfo{
		Version: VERSION,
		Time:    time.Now().UTC().Format(time.RFC3339),
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeJSONError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, models.APIError{Error: msg})
}
EOF
commit "feat: add readiness endpoint /readyz"

# ── 44. Register readiness route ──
cat > routes/routes.go << 'EOF'
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
EOF
commit "feat: register /readyz route"

# ── 45. Call SetReady in server start ──
cat > server/server.go << 'EOF'
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
	"commit-forge/handlers"
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
		handlers.SetReady()
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
EOF
commit "feat: mark server as ready on startup"

# ── 46. Add readiness test ──
cat >> handlers/basic_test.go << 'EOF'

func TestReadyHandler_NotReady(t *testing.T) {
	ready.Store(false)
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	rr := httptest.NewRecorder()

	Ready(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Errorf("expected status 503, got %d", rr.Code)
	}
}

func TestReadyHandler_Ready(t *testing.T) {
	SetReady()
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	rr := httptest.NewRecorder()

	Ready(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}
	if rr.Body.String() != "ready" {
		t.Errorf("expected body 'ready', got %s", rr.Body.String())
	}
}
EOF
commit "test: add readiness endpoint unit tests"

# ── 47. Add request body size limiter ──
cat > middleware/bodylimit.go << 'EOF'
package middleware

import "net/http"

// BodyLimit limits the maximum request body size.
func BodyLimit(maxBytes int64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			r.Body = http.MaxBytesReader(w, r.Body, maxBytes)
			next.ServeHTTP(w, r)
		})
	}
}
EOF
commit "feat: add request body size limit middleware"

# ── 48. Add GitHub Actions CI workflow ──
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      - name: Build
        run: go build -v ./...

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      - name: Test
        run: go test -v -race ./...
EOF
commit "ci: add GitHub Actions workflow for build and test"

# ── 49. Add lint job to CI ──
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      - name: Build
        run: go build -v ./...

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      - name: Test
        run: go test -v -race ./...

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      - name: Vet
        run: go vet ./...

      - name: Format check
        run: |
          gofmt -l .
          test -z "$(gofmt -l .)"
EOF
commit "ci: add lint and vet jobs to CI workflow"

# ── 50. Add Docker build job to CI ──
cat >> .github/workflows/ci.yml << 'EOF'

  docker:
    runs-on: ubuntu-latest
    needs: [build, test]
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t commit-forge:test .
EOF
commit "ci: add Docker build job to CI workflow"

# ── 51. Add timeout middleware ──
cat > middleware/timeout.go << 'EOF'
package middleware

import (
	"context"
	"net/http"
	"time"
)

// Timeout wraps requests with a context timeout.
func Timeout(d time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx, cancel := context.WithTimeout(r.Context(), d)
			defer cancel()
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
EOF
commit "feat: add request timeout middleware"

# ── 52. Add logger package ──
mkdir -p logger
cat > logger/logger.go << 'EOF'
package logger

import (
	"log"
	"os"
)

var (
	Info  *log.Logger
	Error *log.Logger
	Debug *log.Logger
)

func init() {
	Info = log.New(os.Stdout, "INFO: ", log.Ldate|log.Ltime|log.Lshortfile)
	Error = log.New(os.Stderr, "ERROR: ", log.Ldate|log.Ltime|log.Lshortfile)
	Debug = log.New(os.Stdout, "DEBUG: ", log.Ldate|log.Ltime|log.Lshortfile)
}

// SetLevel configures which loggers are active.
func SetLevel(level string) {
	switch level {
	case "debug":
		// all loggers active
	case "error":
		Info.SetOutput(os.NewFile(0, os.DevNull))
		Debug.SetOutput(os.NewFile(0, os.DevNull))
	default: // "info"
		Debug.SetOutput(os.NewFile(0, os.DevNull))
	}
}
EOF
commit "feat: add structured logger package"

# ── 53. Add logger tests ──
cat > logger/logger_test.go << 'EOF'
package logger

import "testing"

func TestLoggerInit(t *testing.T) {
	if Info == nil {
		t.Error("Info logger should not be nil")
	}
	if Error == nil {
		t.Error("Error logger should not be nil")
	}
	if Debug == nil {
		t.Error("Debug logger should not be nil")
	}
}

func TestSetLevel(t *testing.T) {
	// Should not panic
	SetLevel("debug")
	SetLevel("info")
	SetLevel("error")
}
EOF
commit "test: add logger package unit tests"

# ── 54. Add constants package ──
mkdir -p constants
cat > constants/constants.go << 'EOF'
package constants

const (
	DefaultPort       = "8080"
	DefaultBranch     = "main"
	DefaultLogLevel   = "info"
	MaxBodySize       = 1 << 20 // 1 MB
	ShutdownTimeout   = 30      // seconds
	DefaultRetryDelay = 5       // seconds
	MaxRetryBackoff   = 60      // seconds
)
EOF
commit "feat: add constants package"

# ── 55. Add health check response model ──
cat >> models/response.go << 'EOF'

// HealthStatus represents detailed health check response.
type HealthStatus struct {
	Status  string `json:"status"`
	Version string `json:"version"`
	Uptime  string `json:"uptime,omitempty"`
}
EOF
commit "feat: add HealthStatus response model"

# ── 56. Add docker health check ──
cat > Dockerfile << 'EOF'
FROM golang:1.21 AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server .

FROM alpine:3.19

# Install git, bash, and certs for HTTPS clones
RUN apk add --no-cache git bash ca-certificates curl

RUN adduser -D -g '' appuser
USER appuser

WORKDIR /app

COPY --from=builder /app/server .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1

ENTRYPOINT ["./server"]
EOF
commit "feat: add Docker health check"

# ── 57. Add docker-compose env config ──
cat > docker-compose.yml << 'EOF'
version: "3.9"

services:
  commit-forge:
    build: .
    container_name: commit-forge-server
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - LOG_LEVEL=info
      - CORS_ALLOWED_ORIGINS=*
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
EOF
commit "feat: add environment config to docker-compose"

# ── 58. Add .dockerignore ──
cat > .dockerignore << 'EOF'
.git
.gitignore
.github
.env
.env.local
*.md
LICENSE
Makefile
cloner
*.test
*.out
*.prof
EOF
commit "chore: add .dockerignore to optimize Docker builds"

# ── 59. Add editorconfig ──
cat > .editorconfig << 'EOF'
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
trim_trailing_whitespace = true

[*.go]
indent_style = tab
indent_size = 4

[*.{yml,yaml}]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab

[*.md]
trim_trailing_whitespace = false
EOF
commit "chore: add .editorconfig"

# ── 60. Add test coverage to Makefile ──
cat > Makefile << 'EOF'
.PHONY: build run test test-cover clean lint fmt vet docker-build docker-up docker-down

BINARY_NAME=commit-forge
GO=go

build:
	$(GO) build -o $(BINARY_NAME) .

run: build
	./$(BINARY_NAME)

test:
	$(GO) test ./... -v

test-cover:
	$(GO) test ./... -v -coverprofile=coverage.out
	$(GO) tool cover -html=coverage.out -o coverage.html

test-race:
	$(GO) test ./... -v -race

clean:
	rm -f $(BINARY_NAME) coverage.out coverage.html
	$(GO) clean

lint:
	golangci-lint run ./...

fmt:
	$(GO) fmt ./...

vet:
	$(GO) vet ./...

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down
EOF
commit "feat: add test coverage and race detection targets to Makefile"

# ── 61. Add rate limit test ──
cat > middleware/ratelimit_test.go << 'EOF'
package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestRateLimiterAllows(t *testing.T) {
	rl := NewRateLimiter(5, time.Minute)
	handler := rl.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	for i := 0; i < 5; i++ {
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		req.RemoteAddr = "1.2.3.4:1234"
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
		if rr.Code != http.StatusOK {
			t.Errorf("request %d: expected 200, got %d", i+1, rr.Code)
		}
	}
}

func TestRateLimiterBlocks(t *testing.T) {
	rl := NewRateLimiter(2, time.Minute)
	handler := rl.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	for i := 0; i < 3; i++ {
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		req.RemoteAddr = "1.2.3.4:1234"
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
		if i < 2 && rr.Code != http.StatusOK {
			t.Errorf("request %d: expected 200, got %d", i+1, rr.Code)
		}
		if i == 2 && rr.Code != http.StatusTooManyRequests {
			t.Errorf("request %d: expected 429, got %d", i+1, rr.Code)
		}
	}
}
EOF
commit "test: add rate limiter middleware unit tests"

# ── 62. Add security headers test ──
cat > middleware/security_test.go << 'EOF'
package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders(t *testing.T) {
	handler := SecurityHeaders(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	tests := map[string]string{
		"X-Content-Type-Options": "nosniff",
		"X-Frame-Options":       "DENY",
		"X-XSS-Protection":      "1; mode=block",
		"Referrer-Policy":       "strict-origin-when-cross-origin",
	}

	for header, expected := range tests {
		if got := rr.Header().Get(header); got != expected {
			t.Errorf("header %s: expected %q, got %q", header, expected, got)
		}
	}
}
EOF
commit "test: add security headers middleware unit tests"

# ── 63. Add body limit test ──
cat > middleware/bodylimit_test.go << 'EOF'
package middleware

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestBodyLimitAllows(t *testing.T) {
	handler := BodyLimit(1024)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "read error", http.StatusRequestEntityTooLarge)
			return
		}
		w.WriteHeader(http.StatusOK)
	}))

	body := strings.Repeat("a", 512)
	req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(body))
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rr.Code)
	}
}
EOF
commit "test: add body limit middleware unit tests"

# ── 64. Add timeout test ──
cat > middleware/timeout_test.go << 'EOF'
package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestTimeoutMiddleware(t *testing.T) {
	handler := Timeout(5 * time.Second)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		deadline, ok := r.Context().Deadline()
		if !ok {
			t.Error("context should have a deadline")
		}
		if time.Until(deadline) > 6*time.Second {
			t.Error("deadline should be approximately 5 seconds")
		}
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rr.Code)
	}
}
EOF
commit "test: add timeout middleware unit tests"

# ── 65. Add response status endpoint ──
cat > handlers/status.go << 'EOF'
package handlers

import (
	"net/http"
	"runtime"
	"time"
)

var startTime = time.Now()

// Status returns server runtime information.
func Status(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	writeJSON(w, http.StatusOK, map[string]any{
		"uptime":       time.Since(startTime).String(),
		"goroutines":   runtime.NumGoroutine(),
		"go_version":   runtime.Version(),
		"os":           runtime.GOOS,
		"arch":         runtime.GOARCH,
		"alloc_mb":     m.Alloc / 1024 / 1024,
		"sys_mb":       m.Sys / 1024 / 1024,
		"num_gc":       m.NumGC,
	})
}
EOF
commit "feat: add /status endpoint with runtime info"

# ── 66. Register status route ──
cat > routes/routes.go << 'EOF'
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
	mux.HandleFunc("/status", handlers.Status)
	mux.HandleFunc("/rewrite-commits", handlers.Rewrite)
}
EOF
commit "feat: register /status route"

# ── 67. Add status handler test ──
cat > handlers/status_test.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestStatusHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/status", nil)
	rr := httptest.NewRecorder()

	Status(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}

	var body map[string]any
	if err := json.NewDecoder(rr.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if _, ok := body["uptime"]; !ok {
		t.Error("response should contain uptime")
	}
	if _, ok := body["goroutines"]; !ok {
		t.Error("response should contain goroutines")
	}
	if _, ok := body["go_version"]; !ok {
		t.Error("response should contain go_version")
	}
}

func TestStatusHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/status", nil)
	rr := httptest.NewRecorder()

	Status(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}
EOF
commit "test: add status handler unit tests"

# ── 68. Add route listing test ──
cat > routes/routes_test.go << 'EOF'
package routes

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRegister(t *testing.T) {
	mux := http.NewServeMux()
	Register(mux)

	routes := []struct {
		path   string
		method string
		status int
	}{
		{"/healthz", http.MethodGet, http.StatusOK},
		{"/version", http.MethodGet, http.StatusOK},
	}

	for _, rt := range routes {
		req := httptest.NewRequest(rt.method, rt.path, nil)
		rr := httptest.NewRecorder()
		mux.ServeHTTP(rr, req)

		if rr.Code != rt.status {
			t.Errorf("%s %s: expected %d, got %d", rt.method, rt.path, rt.status, rr.Code)
		}
	}
}
EOF
commit "test: add routes registration test"

# ── 69. Update root handler to include new routes ──
cat > handlers/basic.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"sync/atomic"
	"time"

	"commit-forge/models"
)

const VERSION = "v0.5.0"

var ready atomic.Bool

// SetReady marks the service as ready to accept traffic.
func SetReady() { ready.Store(true) }

// Root is a simple landing handler describing available routes.
func Root(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"service":        "Commit Forge",
		"version":        VERSION,
		"health_route":   "/healthz",
		"ready_route":    "/readyz",
		"version_route":  "/version",
		"status_route":   "/status",
		"rewrite_route":  "/rewrite-commits",
		"example_method": "POST /rewrite-commits",
	})
}

// Health reports basic liveness.
func Health(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}

// Ready reports whether the service is ready for traffic.
func Ready(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if !ready.Load() {
		http.Error(w, "not ready", http.StatusServiceUnavailable)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ready"))
}

// Version reports service version information.
func Version(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, models.VersionInfo{
		Version: VERSION,
		Time:    time.Now().UTC().Format(time.RFC3339),
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeJSONError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, models.APIError{Error: msg})
}
EOF
commit "feat: update root handler to list all available routes"

# ── 70. Bump version to v0.5.0 and update root test ──
cat > handlers/basic_test.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRootHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	Root(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}

	var body map[string]any
	if err := json.NewDecoder(rr.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body["service"] != "Commit Forge" {
		t.Errorf("unexpected service name: %v", body["service"])
	}
	if body["version"] != VERSION {
		t.Errorf("unexpected version: %v", body["version"])
	}
}

func TestRootHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	rr := httptest.NewRecorder()

	Root(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := httptest.NewRecorder()

	Health(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}
	if rr.Body.String() != "ok" {
		t.Errorf("expected body 'ok', got %s", rr.Body.String())
	}
}

func TestHealthHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/healthz", nil)
	rr := httptest.NewRecorder()

	Health(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}

func TestVersionHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/version", nil)
	rr := httptest.NewRecorder()

	Version(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}

	var body map[string]string
	if err := json.NewDecoder(rr.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body["version"] != VERSION {
		t.Errorf("expected version %s, got %s", VERSION, body["version"])
	}
}

func TestVersionHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodDelete, "/version", nil)
	rr := httptest.NewRecorder()

	Version(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}

func TestReadyHandler_NotReady(t *testing.T) {
	ready.Store(false)
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	rr := httptest.NewRecorder()

	Ready(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Errorf("expected status 503, got %d", rr.Code)
	}
}

func TestReadyHandler_Ready(t *testing.T) {
	SetReady()
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	rr := httptest.NewRecorder()

	Ready(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rr.Code)
	}
	if rr.Body.String() != "ready" {
		t.Errorf("expected body 'ready', got %s", rr.Body.String())
	}
}
EOF
commit "test: update basic handler tests for new root response shape"

# ── 71. Add Makefile help target ──
cat >> Makefile << 'EOF'

help:
	@echo "Available targets:"
	@echo "  build        - Build the binary"
	@echo "  run          - Build and run the server"
	@echo "  test         - Run all tests"
	@echo "  test-cover   - Run tests with coverage report"
	@echo "  test-race    - Run tests with race detector"
	@echo "  clean        - Remove build artifacts"
	@echo "  lint         - Run golangci-lint"
	@echo "  fmt          - Format Go code"
	@echo "  vet          - Run go vet"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-up    - Start Docker containers"
	@echo "  docker-down  - Stop Docker containers"
	@echo "  help         - Show this help message"
EOF
commit "chore: add help target to Makefile"

# ── 72. Add config string representation ──
cat >> config/config.go << 'EOF'

// String returns a safe string representation (without secrets).
func (c *Config) String() string {
	return "Config{Port:" + c.Port + ", LogLevel:" + c.LogLevel + ", CORSAllowOrigins:" + c.CORSAllowOrigins + "}"
}
EOF
commit "feat: add safe String() method to Config"

# ── 73. Final: clean up and add build info to version ──
cat > handlers/basic.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"sync/atomic"
	"time"

	"commit-forge/models"
)

var (
	// VERSION is the current application version.
	VERSION = "v0.5.0"

	// BuildTime can be set at compile time via -ldflags.
	BuildTime = "unknown"

	ready atomic.Bool
)

// SetReady marks the service as ready to accept traffic.
func SetReady() { ready.Store(true) }

// Root is a simple landing handler describing available routes.
func Root(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"service":        "Commit Forge",
		"version":        VERSION,
		"health_route":   "/healthz",
		"ready_route":    "/readyz",
		"version_route":  "/version",
		"status_route":   "/status",
		"rewrite_route":  "/rewrite-commits",
		"example_method": "POST /rewrite-commits",
	})
}

// Health reports basic liveness.
func Health(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}

// Ready reports whether the service is ready for traffic.
func Ready(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if !ready.Load() {
		http.Error(w, "not ready", http.StatusServiceUnavailable)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ready"))
}

// Version reports service version and build information.
func Version(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{
		"version":    VERSION,
		"build_time": BuildTime,
		"time":       time.Now().UTC().Format(time.RFC3339),
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeJSONError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, models.APIError{Error: msg})
}
EOF
commit "feat: add build-time version info via ldflags"

echo ""
echo "Done! Total commits:"
git log --oneline | wc -l
