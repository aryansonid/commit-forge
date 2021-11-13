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
