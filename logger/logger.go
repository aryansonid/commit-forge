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
