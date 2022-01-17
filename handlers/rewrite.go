package handlers

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"commit-forge/git"
	"commit-forge/models"
	"commit-forge/validation"
)

// Rewrite handles POST /rewrite-commits requests.
func Rewrite(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.RewriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if err := validation.ValidateRewriteRequest(&req); err != nil {
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

	branch := strings.TrimSpace(req.TargetBranch)
	if branch == "" {
		branch = "main"
	}

	writeJSON(w, http.StatusOK, models.RewriteResponse{
		Message: "repository rewritten and pushed successfully",
		Branch:  branch,
		DestURL: req.DestRepoURL,
	})
}

func processRewrite(ctx context.Context, req *models.RewriteRequest) error {
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

	repoDir, err := git.Clone(ctx, tmpDir, req.SourceRepoURL, branch)
	if err != nil {
		return err
	}

	if err := git.FilterBranchRewriteAuthor(ctx, repoDir, branch, req.AuthorName, req.AuthorEmail); err != nil {
		return err
	}

	if err := git.CleanupFilterBranchBackups(ctx, repoDir); err != nil {
		log.Printf("warning: cleanup after filter-branch failed: %v", err)
	}

	username := strings.TrimSpace(req.DestRepoUsername)
	if username == "" {
		username = strings.TrimSpace(req.AuthorName)
	}

	authURL, err := git.BuildAuthenticatedURL(req.DestRepoURL, username, req.DestRepoPAT)
	if err != nil {
		return err
	}

	if err := git.SetRemoteOrigin(ctx, repoDir, authURL); err != nil {
		return err
	}

	return git.PushWithRetry(ctx, repoDir, branch, 5)
}
