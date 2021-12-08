package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// RewriteRequest defines the JSON payload expected by the API.
type RewriteRequest struct {
	SourceRepoURL    string `json:"source_repo_url"`
	DestRepoURL      string `json:"dest_repo_url"`
	DestRepoUsername string `json:"dest_repo_username,omitempty"`
	DestRepoPAT      string `json:"dest_repo_pat"`
	AuthorName       string `json:"author_name"`
	AuthorEmail      string `json:"author_email"`
	TargetBranch     string `json:"target_branch,omitempty"`
}

// Rewrite handles POST /rewrite-commits requests.
func Rewrite(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RewriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if err := validateRequest(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 60*time.Minute)
	defer cancel()

	if err := processRewrite(ctx, &req); err != nil {
		log.Printf("rewrite failed: %v", err)
		writeJSONError(w, http.StatusInternalServerError, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{
		"message": "repository rewritten and pushed successfully",
	})
}

func validateRequest(req *RewriteRequest) error {
	if strings.TrimSpace(req.SourceRepoURL) == "" {
		return errors.New("source_repo_url is required")
	}
	if strings.TrimSpace(req.DestRepoURL) == "" {
		return errors.New("dest_repo_url is required")
	}
	if strings.TrimSpace(req.DestRepoPAT) == "" {
		return errors.New("dest_repo_pat is required")
	}
	if strings.TrimSpace(req.AuthorName) == "" {
		return errors.New("author_name is required")
	}
	if strings.TrimSpace(req.AuthorEmail) == "" {
		return errors.New("author_email is required")
	}
	return nil
}

// processRewrite: clone -> rewrite authors -> push.
func processRewrite(ctx context.Context, req *RewriteRequest) error {
	tmpDir, err := os.MkdirTemp("", "rewrite-repo-*")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmpDir)

	log.Printf("Using temp directory: %s", tmpDir)

	branch := strings.TrimSpace(req.TargetBranch)
	if branch == "" {
		branch = "main"
	}

	repoDir := filepath.Join(tmpDir, "repo")
	if err := runCmd(ctx, tmpDir, "git", "clone", "--no-tags", "--single-branch", "--branch", branch, "--progress", req.SourceRepoURL, repoDir); err != nil {
		return err
	}

	env := append(os.Environ(),
		"NEW_AUTHOR_NAME="+req.AuthorName,
		"NEW_AUTHOR_EMAIL="+req.AuthorEmail,
	)

	filterScript := `
export GIT_AUTHOR_NAME="$NEW_AUTHOR_NAME"
export GIT_AUTHOR_EMAIL="$NEW_AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$NEW_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$NEW_AUTHOR_EMAIL"
`
	filterCmd := "git filter-branch --env-filter '" + strings.TrimSpace(filterScript) + "' --tag-name-filter cat -- " + branch

	if err := runCmdWithEnv(ctx, repoDir, env, "bash", "-lc", filterCmd); err != nil {
		return err
	}

	if err := cleanupFilterBranchBackups(ctx, repoDir); err != nil {
		log.Printf("warning: cleanup after filter-branch failed: %v", err)
	}

	username := strings.TrimSpace(req.DestRepoUsername)
	if username == "" {
		username = strings.TrimSpace(req.AuthorName)
	}
	authURL, err := buildAuthenticatedURL(req.DestRepoURL, username, req.DestRepoPAT)
	if err != nil {
		return err
	}

	_ = runCmd(ctx, repoDir, "git", "remote", "remove", "origin")
	if err := runCmd(ctx, repoDir, "git", "remote", "add", "origin", authURL); err != nil {
		return err
	}

	pushRef := "HEAD:refs/heads/" + branch
	retryDelay := 5 * time.Second
	attempt := 0

	for {
		attempt++

		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		if err := runCmd(ctx, repoDir, "git", "push", "--force-with-lease", "origin", pushRef); err != nil {
			backoff := retryDelay * time.Duration(attempt)
			if backoff > 60*time.Second {
				backoff = 60 * time.Second
			}
			log.Printf("push failed (attempt %d), retrying in %v: %v", attempt, backoff, err)

			select {
			case <-ctx.Done():
				return ctx.Err()
			case <-time.After(backoff):
			}
		} else {
			if attempt > 1 {
				log.Printf("push succeeded on attempt %d", attempt)
			}
			break
		}
	}

	log.Printf("Successfully pushed rewritten commits to %s (branch %s)", req.DestRepoURL, branch)
	return nil
}

func cleanupFilterBranchBackups(ctx context.Context, dir string) error {
	cmd := exec.CommandContext(ctx, "git", "for-each-ref", "--format=%(refname)", "refs/original/")
	cmd.Dir = dir
	cmd.Env = os.Environ()

	out, err := cmd.Output()
	if err != nil {
		log.Printf("warning: failed to list refs/original for cleanup: %v", err)
	} else {
		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		for _, ref := range lines {
			ref = strings.TrimSpace(ref)
			if ref == "" {
				continue
			}
			if err := runCmd(ctx, dir, "git", "update-ref", "-d", ref); err != nil {
				log.Printf("warning: failed to delete backup ref %s: %v", ref, err)
			}
		}
	}

	if err := runCmd(ctx, dir, "git", "reflog", "expire", "--expire=now", "--all"); err != nil {
		log.Printf("warning: git reflog expire failed: %v", err)
	}

	if err := runCmd(ctx, dir, "git", "gc", "--prune=now"); err != nil {
		return err
	}

	return nil
}

func buildAuthenticatedURL(rawURL, username, pat string) (string, error) {
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

func runCmd(ctx context.Context, dir, name string, args ...string) error {
	return runCmdWithEnv(ctx, dir, os.Environ(), name, args...)
}

func runCmdWithEnv(ctx context.Context, dir string, env []string, name string, args ...string) error {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Dir = dir
	cmd.Env = env

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("command failed: %s %s\nin dir: %s\noutput:\n%s", name, strings.Join(args, " "), dir, string(output))
		return err
	}

	log.Printf("command succeeded: %s %s\nin dir: %s\noutput:\n%s", name, strings.Join(args, " "), dir, string(output))
	return nil
}
