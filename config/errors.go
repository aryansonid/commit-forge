package config

import "errors"

var (
	ErrPortRequired        = errors.New("config: port is required")
	ErrInvalidRetryAttempts = errors.New("config: max retry attempts must be >= 1")
	ErrInvalidTimeout      = errors.New("config: request timeout must be >= 1 second")
)
