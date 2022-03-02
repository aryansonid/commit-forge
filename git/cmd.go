package git

import (
	"context"
	"log"
	"os"
	"os/exec"
	"strings"
)

// RunCmd executes a command with the default environment.
func RunCmd(ctx context.Context, dir, name string, args ...string) error {
	return RunCmdWithEnv(ctx, dir, os.Environ(), name, args...)
}

// RunCmdWithEnv executes a command with a custom environment.
func RunCmdWithEnv(ctx context.Context, dir string, env []string, name string, args ...string) error {
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
