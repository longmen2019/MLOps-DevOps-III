package main // Defines the main package — required for executable programs

import (
	"context"       // Used for graceful shutdown timeouts
	"encoding/json" // Used to encode JSON responses
	"errors"        // Used to compare errors (e.g., http.ErrServerClosed)
	"fmt"           // Used for formatted output
	"log/slog"      // Structured logging
	"net/http"      // Core HTTP server and handler interfaces
	"os"            // Access to OS signals, stderr, exit codes
	"os/signal"     // Allows listening for OS interrupt signals
	"strconv"       // Converts strings to numbers (used for userID validation)
	"syscall"       // Provides SIGTERM constant
	"time"          // Used for timeouts and request duration logging

	"github.com/go-chi/chi/v5"            // Chi router
	"github.com/go-chi/chi/v5/middleware" // Chi middleware utilities
)

// --- Server ---

// APIServer holds configuration and dependencies for the server.
type APIServer struct {
	addr   string       // Address the server listens on (e.g., ":8080")
	logger *slog.Logger // Structured logger instance
}

// NewAPIServer creates a new APIServer with a JSON logger.
func NewAPIServer(addr string) *APIServer {
	return &APIServer{
		addr:   addr,                                          // Store the address
		logger: slog.New(slog.NewJSONHandler(os.Stdout, nil)), // Log to stdout in JSON format
	}
}

// Run starts the HTTP server and configures routes + graceful shutdown.
func (s *APIServer) Run() error {
	r := chi.NewRouter() // Create a new Chi router

	// Global middleware applied to all routes
	r.Use(middleware.Recoverer)    // Converts panics into 500 responses
	r.Use(middleware.StripSlashes) // Removes trailing slashes for consistent routing
	r.Use(middleware.RequestID)    // Adds a unique request ID to each request
	r.Use(s.requestLogger)         // Custom structured request logger

	// Public route — no authentication required
	r.Get("/health", s.healthHandler)

	// Versioned API namespace
	r.Route("/api/v1", func(r chi.Router) {

		// Protected routes — require Authorization header
		r.With(s.requireAuth).Route("/users/{userID}", func(r chi.Router) {
			r.Get("/", s.getUserHandler) // GET /api/v1/users/{userID}/
		})
	})

	// Configure the HTTP server with timeouts
	server := &http.Server{
		Addr:         s.addr,            // Port to listen on
		Handler:      r,                 // Chi router handles all requests
		ReadTimeout:  5 * time.Second,   // Max time to read request
		WriteTimeout: 10 * time.Second,  // Max time to write response
		IdleTimeout:  120 * time.Second, // Keep-alive timeout
	}

	// Channel used to signal when shutdown is complete
	idleConnsClosed := make(chan struct{})

	// Goroutine that waits for SIGINT or SIGTERM
	go func() {
		sigint := make(chan os.Signal, 1)                    // Channel for OS signals
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM) // Listen for Ctrl+C or termination
		<-sigint                                             // Block until signal is received

		s.logger.Info("shutting down", slog.String("addr", s.addr))

		// Allow up to 30 seconds for graceful shutdown
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		// Attempt graceful shutdown
		if err := server.Shutdown(ctx); err != nil {
			s.logger.Error("shutdown error", slog.Any("error", err))
		}

		close(idleConnsClosed) // Notify main goroutine shutdown is complete
	}()

	s.logger.Info("server starting", slog.String("addr", s.addr))

	// Start the server — ListenAndServe blocks until shutdown
	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("server error: %w", err) // Unexpected error
	}

	<-idleConnsClosed // Wait for shutdown goroutine to finish
	s.logger.Info("server stopped")
	return nil
}

// --- Handlers ---

// healthHandler returns a simple JSON health check.
func (s *APIServer) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")           // Response is JSON
	w.WriteHeader(http.StatusOK)                                 // 200 OK
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"}) // Write JSON body
}

// getUserHandler returns the user ID from the URL.
func (s *APIServer) getUserHandler(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userID") // Extract {userID} from URL

	if userID == "" { // Missing userID
		s.jsonError(w, "missing userID", http.StatusBadRequest)
		return
	}

	// Validate userID is numeric
	if _, err := strconv.Atoi(userID); err != nil {
		s.jsonError(w, "invalid userID", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "text/plain") // Plain text response
	w.WriteHeader(http.StatusOK)                 // 200 OK

	// Write response body
	if _, err := w.Write([]byte("User ID: " + userID)); err != nil {
		s.logger.Error("write error", slog.Any("error", err))
	}
}

// --- Middleware ---

// requestLogger logs each request with structured fields.
func (s *APIServer) requestLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()                                     // Track start time
		ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor) // Wrap writer to capture status + bytes

		next.ServeHTTP(ww, r) // Call next handler

		// Log request details
		s.logger.Info("request",
			slog.String("method", r.Method),
			slog.String("path", r.URL.Path),
			slog.Int("status", ww.Status()),
			slog.Int("bytes", ww.BytesWritten()),
			slog.Duration("duration", time.Since(start)),
			slog.String("request_id", middleware.GetReqID(r.Context())),
		)
	})
}

// requireAuth checks the Authorization header.
func (s *APIServer) requireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("Authorization") // Read Authorization header

		if token != "Bearer token" { // Simple static token check
			s.jsonError(w, "unauthorized", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r) // Continue to next handler
	})
}

// --- Helpers ---

// jsonError sends a JSON error response with a given status code.
func (s *APIServer) jsonError(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

// --- Entry Point ---

func main() {
	server := NewAPIServer(":8080")      // Create server listening on port 8080
	if err := server.Run(); err != nil { // Start server
		fmt.Fprintln(os.Stderr, "fatal:", err) // Print fatal error
		os.Exit(1)                             // Exit with error code
	}
}
