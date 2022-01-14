package routes

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRegister(t *testing.T) {
	mux := http.NewServeMux()
	Register(mux)

	routes := []struct {
		path   string
		method string
		status int
	}{
		{"/healthz", http.MethodGet, http.StatusOK},
		{"/version", http.MethodGet, http.StatusOK},
	}

	for _, rt := range routes {
		req := httptest.NewRequest(rt.method, rt.path, nil)
		rr := httptest.NewRecorder()
		mux.ServeHTTP(rr, req)

		if rr.Code != rt.status {
			t.Errorf("%s %s: expected %d, got %d", rt.method, rt.path, rt.status, rr.Code)
		}
	}
}
