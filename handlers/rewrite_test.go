package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestRewriteMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/rewrite-commits", nil)
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", rr.Code)
	}
}

func TestRewriteInvalidJSON(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/rewrite-commits", strings.NewReader("not json"))
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", rr.Code)
	}
}

func TestRewriteMissingFields(t *testing.T) {
	body := `{"source_repo_url": "https://github.com/test/repo.git"}`
	req := httptest.NewRequest(http.MethodPost, "/rewrite-commits", strings.NewReader(body))
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", rr.Code)
	}
}

func TestRewriteEmptyBody(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/rewrite-commits", strings.NewReader("{}"))
	rr := httptest.NewRecorder()

	Rewrite(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", rr.Code)
	}
}
