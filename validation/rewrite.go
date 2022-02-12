package validation

import (
	"errors"
	"strings"

	"commit-forge/models"
)

var (
	ErrSourceURLRequired = errors.New("source_repo_url is required")
	ErrDestURLRequired   = errors.New("dest_repo_url is required")
	ErrPATRequired       = errors.New("dest_repo_pat is required")
	ErrAuthorRequired    = errors.New("author_name is required")
	ErrEmailRequired     = errors.New("author_email is required")
)

// ValidateRewriteRequest checks that all required fields are present.
func ValidateRewriteRequest(req *models.RewriteRequest) error {
	if strings.TrimSpace(req.SourceRepoURL) == "" {
		return ErrSourceURLRequired
	}
	if strings.TrimSpace(req.DestRepoURL) == "" {
		return ErrDestURLRequired
	}
	if strings.TrimSpace(req.DestRepoPAT) == "" {
		return ErrPATRequired
	}
	if strings.TrimSpace(req.AuthorName) == "" {
		return ErrAuthorRequired
	}
	if strings.TrimSpace(req.AuthorEmail) == "" {
		return ErrEmailRequired
	}
	return nil
}
