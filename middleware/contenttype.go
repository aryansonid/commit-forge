package middleware

import "net/http"

// ContentType sets a default Content-Type header if one is not already set.
func ContentType(contentType string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if w.Header().Get("Content-Type") == "" {
				w.Header().Set("Content-Type", contentType)
			}
			next.ServeHTTP(w, r)
		})
	}
}
