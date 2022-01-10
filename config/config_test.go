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
