package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

type Response struct {
	Message string `json:"message"`
	Version string `json:"version"`
}

// GetMessage returns a simple greeting message
func GetMessage() string {
	return "Hello from Kubernetes 2!"
}

// createResponse creates a Response struct with the given message and version
func createResponse(message, version string) Response {
	return Response{
		Message: message,
		Version: version,
	}
}

func main() {
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "1.0.1"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		response := createResponse(GetMessage(), version)
		w.Header().Set("Content-Type", "application/json")
		err := json.NewEncoder(w).Encode(response)
		if err != nil {
			log.Printf("Error encoding response: %v", err)
		}
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
