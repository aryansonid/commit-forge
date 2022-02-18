package git

import "testing"

func TestBuildAuthenticatedURL(t *testing.T) {
	url, err := BuildAuthenticatedURL("https://github.com/user/repo.git", "myuser", "mytoken")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	expected := "https://myuser:mytoken@github.com/user/repo.git"
	if url != expected {
		t.Errorf("expected %s, got %s", expected, url)
	}
}

func TestBuildAuthenticatedURLHTTP(t *testing.T) {
	url, err := BuildAuthenticatedURL("http://gitlab.local/user/repo.git", "admin", "pass")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	expected := "http://admin:pass@gitlab.local/user/repo.git"
	if url != expected {
		t.Errorf("expected %s, got %s", expected, url)
	}
}

func TestBuildAuthenticatedURLInvalidScheme(t *testing.T) {
	_, err := BuildAuthenticatedURL("ssh://git@github.com/user/repo.git", "user", "token")
	if err == nil {
		t.Error("expected error for ssh scheme")
	}
}

func TestBuildAuthenticatedURLInvalidURL(t *testing.T) {
	_, err := BuildAuthenticatedURL("://invalid", "user", "token")
	if err == nil {
		t.Error("expected error for invalid URL")
	}
}
