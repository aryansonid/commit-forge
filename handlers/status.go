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
