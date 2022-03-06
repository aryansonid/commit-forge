package validation

import (
	"testing"

	"commit-forge/models"
)

func TestValidateRewriteRequest_Valid(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorName:    "Test User",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != nil {
		t.Errorf("valid request should not error: %v", err)
	}
}

func TestValidateRewriteRequest_MissingSource(t *testing.T) {
	req := &models.RewriteRequest{
		DestRepoURL: "https://github.com/user/repo.git",
		DestRepoPAT: "ghp_test123",
		AuthorName:  "Test User",
		AuthorEmail: "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrSourceURLRequired {
		t.Errorf("expected ErrSourceURLRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingDest(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorName:    "Test User",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrDestURLRequired {
		t.Errorf("expected ErrDestURLRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingPAT(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		AuthorName:    "Test User",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrPATRequired {
		t.Errorf("expected ErrPATRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingAuthor(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorEmail:   "test@example.com",
	}
	if err := ValidateRewriteRequest(req); err != ErrAuthorRequired {
		t.Errorf("expected ErrAuthorRequired, got %v", err)
	}
}

func TestValidateRewriteRequest_MissingEmail(t *testing.T) {
	req := &models.RewriteRequest{
		SourceRepoURL: "https://github.com/example/repo.git",
		DestRepoURL:   "https://github.com/user/repo.git",
		DestRepoPAT:   "ghp_test123",
		AuthorName:    "Test User",
	}
	if err := ValidateRewriteRequest(req); err != ErrEmailRequired {
		t.Errorf("expected ErrEmailRequired, got %v", err)
	}
}
