package models

// RewriteRequest defines the JSON payload expected by the rewrite API.
type RewriteRequest struct {
	SourceRepoURL    string `json:"source_repo_url"`
	DestRepoURL      string `json:"dest_repo_url"`
	DestRepoUsername string `json:"dest_repo_username,omitempty"`
	DestRepoPAT      string `json:"dest_repo_pat"`
	AuthorName       string `json:"author_name"`
	AuthorEmail      string `json:"author_email"`
	TargetBranch     string `json:"target_branch,omitempty"`
}
