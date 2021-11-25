package logger

import "testing"

func TestLoggerInit(t *testing.T) {
	if Info == nil {
		t.Error("Info logger should not be nil")
	}
	if Error == nil {
		t.Error("Error logger should not be nil")
	}
	if Debug == nil {
		t.Error("Debug logger should not be nil")
	}
}

func TestSetLevel(t *testing.T) {
	// Should not panic
	SetLevel("debug")
	SetLevel("info")
	SetLevel("error")
}
