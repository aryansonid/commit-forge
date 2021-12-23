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
