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

// String returns a safe string representation (without secrets).
func (c *Config) String() string {
	return "Config{Port:" + c.Port + ", LogLevel:" + c.LogLevel + ", CORSAllowOrigins:" + c.CORSAllowOrigins + "}"
}
