package main

import (
	"testing"
)

func TestGetMessage(t *testing.T) {
	// Test the GetMessage function
	message := GetMessage()

	// Expected message
	expected := "Hello from Kubernetes 2!"

	// Check if the returned message matches the expected message
	if message != expected {
		t.Errorf("GetMessage() = %q, want %q", message, expected)
	}
}

func TestCreateResponse(t *testing.T) {
	// Test the createResponse function
	message := "Test message"
	version := "1.0.0"

	response := createResponse(message, version)

	// Check if the response has the correct values
	if response.Message != message {
		t.Errorf("createResponse().Message = %q, want %q", response.Message, message)
	}

	if response.Version != version {
		t.Errorf("createResponse().Version = %q, want %q", response.Version, version)
	}
}
