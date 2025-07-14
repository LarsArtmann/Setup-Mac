package main

import (
	"testing"

	"better-claude/internal/functional"
)

func TestResultTypes(t *testing.T) {
	// Test Success case
	result := functional.Success("test value")
	if !result.IsSuccess() {
		t.Error("Expected result to be successful")
	}
	if result.Value() != "test value" {
		t.Error("Expected value to be 'test value'")
	}
	if result.Error() != nil {
		t.Error("Expected error to be nil for successful result")
	}

	// Test Failure case
	err := functional.Failure[string](functional.NewError("test error"))
	if !err.IsFailure() {
		t.Error("Expected result to be failure")
	}
	if err.Error() == nil {
		t.Error("Expected error to not be nil for failed result")
	}
}

func TestPipeline(t *testing.T) {
	// Test successful pipeline
	result := functional.NewPipeline("initial").
		ThenMap(func(s string) string { return s + " processed" }).
		ThenMap(func(s string) string { return s + " final" }).
		Result()

	if !result.IsSuccess() {
		t.Error("Expected pipeline to be successful")
	}
	if result.Value() != "initial processed final" {
		t.Errorf("Expected 'initial processed final', got '%s'", result.Value())
	}
}

func TestFunctionalComposition(t *testing.T) {
	// Test Map function
	initial := functional.Success(5)
	doubled := functional.Map(initial, func(i int) int { return i * 2 })

	if !doubled.IsSuccess() {
		t.Error("Expected mapped result to be successful")
	}
	if doubled.Value() != 10 {
		t.Errorf("Expected 10, got %d", doubled.Value())
	}

	// Test FlatMap function
	squared := functional.FlatMap(doubled, func(i int) functional.Result[int] {
		return functional.Success(i * i)
	})

	if !squared.IsSuccess() {
		t.Error("Expected flatmapped result to be successful")
	}
	if squared.Value() != 100 {
		t.Errorf("Expected 100, got %d", squared.Value())
	}
}

func TestErrorRecovery(t *testing.T) {
	// Test recovery from failure
	failed := functional.Failure[string](functional.NewError("initial error"))
	recovered := failed.Recover(func(error) string { return "recovered" })

	if !recovered.IsSuccess() {
		t.Error("Expected recovered result to be successful")
	}
	if recovered.Value() != "recovered" {
		t.Errorf("Expected 'recovered', got '%s'", recovered.Value())
	}
}

func TestTryFunction(t *testing.T) {
	// Test successful Try
	successResult := functional.Try(func() (string, error) {
		return "success", nil
	})

	if !successResult.IsSuccess() {
		t.Error("Expected Try result to be successful")
	}
	if successResult.Value() != "success" {
		t.Errorf("Expected 'success', got '%s'", successResult.Value())
	}

	// Test failed Try
	failResult := functional.Try(func() (string, error) {
		return "", functional.NewError("try failed")
	})

	if !failResult.IsFailure() {
		t.Error("Expected Try result to be failure")
	}
}
