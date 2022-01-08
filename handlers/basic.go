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
