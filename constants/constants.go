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
