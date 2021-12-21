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

// HealthStatus represents detailed health check response.
type HealthStatus struct {
	Status  string `json:"status"`
	Version string `json:"version"`
	Uptime  string `json:"uptime,omitempty"`
}
