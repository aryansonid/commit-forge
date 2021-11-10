package git

import (
	"context"
	"path/filepath"
)

// Clone clones a repository into a subdirectory of baseDir.
func Clone(ctx context.Context, baseDir, repoURL, branch string) (string, error) {
	repoDir := filepath.Join(baseDir, "repo")
	args := []string{"clone", "--no-tags", "--single-branch", "--branch", branch, "--progress", repoURL, repoDir}
	if err := RunCmd(ctx, baseDir, "git", args...); err != nil {
		return "", err
	}
	return repoDir, nil
}
