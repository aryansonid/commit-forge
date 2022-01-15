package git

import (
	"context"
	"log"
	"time"
)

// PushWithRetry pushes to remote with exponential backoff retries.
func PushWithRetry(ctx context.Context, repoDir, branch string, maxAttempts int) error {
	pushRef := "HEAD:refs/heads/" + branch
	retryDelay := 5 * time.Second

	for attempt := 1; ; attempt++ {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		err := RunCmd(ctx, repoDir, "git", "push", "--force-with-lease", "origin", pushRef)
		if err == nil {
			if attempt > 1 {
				log.Printf("push succeeded on attempt %d", attempt)
			}
			return nil
		}

		if attempt >= maxAttempts {
			return err
		}

		backoff := retryDelay * time.Duration(attempt)
		if backoff > 60*time.Second {
			backoff = 60 * time.Second
		}
		log.Printf("push failed (attempt %d/%d), retrying in %v: %v", attempt, maxAttempts, backoff, err)

		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(backoff):
		}
	}
}
