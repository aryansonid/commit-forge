package git

import (
	"context"
	"log"
	"os"
	"os/exec"
	"strings"
)

// FilterBranchRewriteAuthor rewrites all commits on a branch with new author info.
func FilterBranchRewriteAuthor(ctx context.Context, repoDir, branch, authorName, authorEmail string) error {
	env := append(os.Environ(),
		"NEW_AUTHOR_NAME="+authorName,
		"NEW_AUTHOR_EMAIL="+authorEmail,
	)

	filterScript := `
export GIT_AUTHOR_NAME="$NEW_AUTHOR_NAME"
export GIT_AUTHOR_EMAIL="$NEW_AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$NEW_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$NEW_AUTHOR_EMAIL"
`
	filterCmd := "git filter-branch --env-filter '" + strings.TrimSpace(filterScript) + "' --tag-name-filter cat -- " + branch

	return RunCmdWithEnv(ctx, repoDir, env, "bash", "-lc", filterCmd)
}

// CleanupFilterBranchBackups removes refs/original and runs gc.
func CleanupFilterBranchBackups(ctx context.Context, dir string) error {
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
			if err := RunCmd(ctx, dir, "git", "update-ref", "-d", ref); err != nil {
				log.Printf("warning: failed to delete backup ref %s: %v", ref, err)
			}
		}
	}

	if err := RunCmd(ctx, dir, "git", "reflog", "expire", "--expire=now", "--all"); err != nil {
		log.Printf("warning: git reflog expire failed: %v", err)
	}

	return RunCmd(ctx, dir, "git", "gc", "--prune=now")
}
