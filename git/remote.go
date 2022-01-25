package git

import (
	"context"
	"errors"
	"net/url"
)

// SetRemoteOrigin replaces the origin remote with a new URL.
func SetRemoteOrigin(ctx context.Context, repoDir, remoteURL string) error {
	_ = RunCmd(ctx, repoDir, "git", "remote", "remove", "origin")
	return RunCmd(ctx, repoDir, "git", "remote", "add", "origin", remoteURL)
}

// BuildAuthenticatedURL injects credentials into a repo URL.
func BuildAuthenticatedURL(rawURL, username, pat string) (string, error) {
	u, err := url.Parse(rawURL)
	if err != nil {
		return "", err
	}
	if u.Scheme != "https" && u.Scheme != "http" {
		return "", errors.New("only http/https URLs are supported for dest_repo_url")
	}
	u.User = url.UserPassword(username, pat)
	return u.String(), nil
}
