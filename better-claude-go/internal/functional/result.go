package functional

import (
	"errors"
	"fmt"
)

// Result represents a value that can be either success or failure
type Result[T any] struct {
	value T
	err   error
}

// Success creates a successful Result
func Success[T any](value T) Result[T] {
	return Result[T]{value: value, err: nil}
}

// Failure creates a failed Result
func Failure[T any](err error) Result[T] {
	var zero T
	return Result[T]{value: zero, err: err}
}

// IsSuccess returns true if the Result is successful
func (r Result[T]) IsSuccess() bool {
	return r.err == nil
}

// IsFailure returns true if the Result is a failure
func (r Result[T]) IsFailure() bool {
	return r.err != nil
}

// Value returns the value if successful, or the zero value if failed
func (r Result[T]) Value() T {
	return r.value
}

// Error returns the error if failed, or nil if successful
func (r Result[T]) Error() error {
	return r.err
}

// Unwrap returns the value and error separately
func (r Result[T]) Unwrap() (T, error) {
	return r.value, r.err
}

// Map applies a function to the value if the Result is successful
func Map[T, U any](r Result[T], f func(T) U) Result[U] {
	if r.IsFailure() {
		return Failure[U](r.err)
	}
	return Success(f(r.value))
}

// FlatMap applies a function that returns a Result to the value if successful
func FlatMap[T, U any](r Result[T], f func(T) Result[U]) Result[U] {
	if r.IsFailure() {
		return Failure[U](r.err)
	}
	return f(r.value)
}

// AndThen is an alias for FlatMap for better readability
func AndThen[T, U any](r Result[T], f func(T) Result[U]) Result[U] {
	return FlatMap(r, f)
}

// OnSuccess executes a side effect if the Result is successful
func (r Result[T]) OnSuccess(f func(T)) Result[T] {
	if r.IsSuccess() {
		f(r.value)
	}
	return r
}

// OnFailure executes a side effect if the Result is a failure
func (r Result[T]) OnFailure(f func(error)) Result[T] {
	if r.IsFailure() {
		f(r.err)
	}
	return r
}

// Recover attempts to recover from a failure using a recovery function
func (r Result[T]) Recover(f func(error) T) Result[T] {
	if r.IsFailure() {
		return Success(f(r.err))
	}
	return r
}

// Try wraps a function that can return an error into a Result
func Try[T any](f func() (T, error)) Result[T] {
	value, err := f()
	if err != nil {
		return Failure[T](err)
	}
	return Success(value)
}

// Pipeline represents a sequence of operations that can be chained
type Pipeline[T any] struct {
	result Result[T]
}

// NewPipeline creates a new pipeline with an initial value
func NewPipeline[T any](value T) *Pipeline[T] {
	return &Pipeline[T]{result: Success(value)}
}

// NewPipelineFromResult creates a new pipeline from a Result
func NewPipelineFromResult[T any](result Result[T]) *Pipeline[T] {
	return &Pipeline[T]{result: result}
}

// Then chains another operation to the pipeline
func (p *Pipeline[T]) Then(f func(T) Result[T]) *Pipeline[T] {
	if p.result.IsFailure() {
		return p
	}
	newResult := f(p.result.value)
	return &Pipeline[T]{result: newResult}
}

// ThenMap chains a simple transformation to the pipeline
func (p *Pipeline[T]) ThenMap(f func(T) T) *Pipeline[T] {
	if p.result.IsFailure() {
		return p
	}
	newValue := f(p.result.value)
	return &Pipeline[T]{result: Success(newValue)}
}

// ThenMapDifferent chains a transformation that returns a different type
func ThenMapDifferent[T, U any](p *Pipeline[T], f func(T) U) *Pipeline[U] {
	if p.result.IsFailure() {
		return &Pipeline[U]{result: Failure[U](p.result.err)}
	}
	newValue := f(p.result.value)
	return &Pipeline[U]{result: Success(newValue)}
}

// Result returns the final Result from the pipeline
func (p *Pipeline[T]) Result() Result[T] {
	return p.result
}

// Combine multiple Results using a combiner function
func Combine[T, U, V any](r1 Result[T], r2 Result[U], combiner func(T, U) V) Result[V] {
	if r1.IsFailure() {
		return Failure[V](r1.err)
	}
	if r2.IsFailure() {
		return Failure[V](r2.err)
	}
	return Success(combiner(r1.value, r2.value))
}

// CombineAll combines multiple Results of the same type
func CombineAll[T any](results ...Result[T]) Result[[]T] {
	values := make([]T, 0, len(results))
	for i, result := range results {
		if result.IsFailure() {
			return Failure[[]T](fmt.Errorf("result %d failed: %w", i, result.err))
		}
		values = append(values, result.value)
	}
	return Success(values)
}

// ForEach executes a function for each successful Result in a slice
func ForEach[T any](results []Result[T], f func(T)) {
	for _, result := range results {
		if result.IsSuccess() {
			f(result.value)
		}
	}
}

// MapSlice applies a function to each element in a slice, returning Results
func MapSlice[T, U any](slice []T, f func(T) Result[U]) []Result[U] {
	results := make([]Result[U], len(slice))
	for i, item := range slice {
		results[i] = f(item)
	}
	return results
}

// FilterSuccessful returns only the successful Results from a slice
func FilterSuccessful[T any](results []Result[T]) []T {
	var successful []T
	for _, result := range results {
		if result.IsSuccess() {
			successful = append(successful, result.value)
		}
	}
	return successful
}

// FilterFailed returns only the failed Results from a slice
func FilterFailed[T any](results []Result[T]) []error {
	var failed []error
	for _, result := range results {
		if result.IsFailure() {
			failed = append(failed, result.err)
		}
	}
	return failed
}

// NewError creates a new error with a message
func NewError(message string) error {
	return errors.New(message)
}

// NewErrorf creates a new error with formatted message
func NewErrorf(format string, args ...interface{}) error {
	return fmt.Errorf(format, args...)
}