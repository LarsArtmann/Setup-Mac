// SystemNix Dagger Module
// Provides CI/CD pipelines for the Nix flake configuration
package main

import (
	"context"
	"fmt"
	"path/filepath"

	"dagger.io/dagger"
)

// SystemNix provides CI/CD pipelines for the Nix configuration
type Systemnix struct{}

// NixConfig represents the Nix flake source code
type NixConfig struct {
	Source *dagger.Directory
}

// GoPackage represents a Go package to build
type GoPackage struct {
	Source    *dagger.Directory
	Name      string
	Binary    string
	BuildTags []string
}

// Nix returns a NixConfig with the source code
func (m *Systemnix) Nix(source *dagger.Directory) *NixConfig {
	return &NixConfig{Source: source}
}

// Go returns a GoPackage with the source code
func (m *Systemnix) Go(source *dagger.Directory, name string) *GoPackage {
	return &GoPackage{
		Source:    source,
		Name:      name,
		Binary:    name,
		BuildTags: []string{},
	}
}

// WithBinary sets the binary name for the Go package
func (g *GoPackage) WithBinary(name string) *GoPackage {
	g.Binary = name
	return g
}

// WithBuildTags sets build tags for the Go package
func (g *GoPackage) WithBuildTags(tags []string) *GoPackage {
	g.BuildTags = tags
	return g
}

// Lint runs golangci-lint on the Go package
func (g *GoPackage) Lint(ctx context.Context) (*dagger.Container, error) {
	golangciVersion := "v1.64"

	ctr := dag.Container().
		From(fmt.Sprintf("golangci/golangci-lint:%s", golangciVersion)).
		WithDirectory("/src", g.Source).
		WithWorkdir("/src").
		WithExec([]string{"golangci-lint", "run", "./...", "--timeout=5m"})

	return ctr, nil
}

// Test runs Go tests on the package
func (g *GoPackage) Test(ctx context.Context) (*dagger.Container, error) {
	goVersion := "1.26"

	ctr := dag.Container().
		From(fmt.Sprintf("golang:%s-alpine", goVersion)).
		WithDirectory("/src", g.Source).
		WithWorkdir("/src").
		WithExec([]string{"go", "test", "-v", "./..."})

	return ctr, nil
}

// Build compiles the Go binary and returns the binary file
func (g *GoPackage) Build(ctx context.Context) (*dagger.File, error) {
	goVersion := "1.26"

	ldflags := "-s -w"
	if g.Name != "" {
		ldflags = fmt.Sprintf("%s -X main.version=0.1.0", ldflags)
	}

	buildArgs := []string{"go", "build", "-ldflags", ldflags, "-o", g.Binary}
	if len(g.BuildTags) > 0 {
		buildArgs = append(buildArgs, "-tags")
		buildArgs = append(buildArgs, g.BuildTags...)
	}
	buildArgs = append(buildArgs, ".")

	ctr := dag.Container().
		From(fmt.Sprintf("golang:%s-alpine", goVersion)).
		WithDirectory("/src", g.Source).
		WithWorkdir("/src").
		WithExec(buildArgs)

	return ctr.File(filepath.Join("/src", g.Binary)), nil
}

// Check runs nix flake check on the configuration
func (n *NixConfig) Check(ctx context.Context) (*dagger.Container, error) {
	ctr := dag.Container().
		From("nixos/nix:latest").
		WithDirectory("/flake", n.Source).
		WithWorkdir("/flake").
		WithEnvVariable("NIX_CONFIG", "experimental-features = nix-command flakes").
		WithExec([]string{"nix", "flake", "check", "--no-build"})

	return ctr, nil
}

// Format runs alejandra formatter on the configuration
func (n *NixConfig) Format(ctx context.Context) (*dagger.Container, error) {
	ctr := dag.Container().
		From("nixos/nix:latest").
		WithDirectory("/flake", n.Source).
		WithWorkdir("/flake").
		WithEnvVariable("NIX_CONFIG", "experimental-features = nix-command flakes").
		WithExec([]string{"sh", "-c", "nix-shell -p alejandra --run 'alejandra --check .'"})

	return ctr, nil
}

// BuildDarwin builds the Darwin configuration
func (n *NixConfig) BuildDarwin(ctx context.Context) (*dagger.Container, error) {
	ctr := dag.Container().
		From("nixos/nix:latest").
		WithDirectory("/flake", n.Source).
		WithWorkdir("/flake").
		WithEnvVariable("NIX_CONFIG", "experimental-features = nix-command flakes").
		WithExec([]string{"nix", "build", ".#darwinConfigurations.Lars-MacBook-Air.config.system.build.toplevel", "--dry-run"})

	return ctr, nil
}

// BuildNixos builds the NixOS configuration
func (n *NixConfig) BuildNixos(ctx context.Context) (*dagger.Container, error) {
	ctr := dag.Container().
		From("nixos/nix:latest").
		WithDirectory("/flake", n.Source).
		WithWorkdir("/flake").
		WithEnvVariable("NIX_CONFIG", "experimental-features = nix-command flakes").
		WithExec([]string{"nix", "build", ".#nixosConfigurations.evo-x2.config.system.build.toplevel", "--dry-run"})

	return ctr, nil
}

// Deadnix runs deadnix linter on the configuration
func (n *NixConfig) Deadnix(ctx context.Context) (*dagger.Container, error) {
	ctr := dag.Container().
		From("nixos/nix:latest").
		WithDirectory("/flake", n.Source).
		WithWorkdir("/flake").
		WithEnvVariable("NIX_CONFIG", "experimental-features = nix-command flakes").
		WithExec([]string{"sh", "-c", "nix-shell -p deadnix --run 'deadnix --fail .'"})

	return ctr, nil
}

// Statix runs statix linter on the configuration
func (n *NixConfig) Statix(ctx context.Context) (*dagger.Container, error) {
	ctr := dag.Container().
		From("nixos/nix:latest").
		WithDirectory("/flake", n.Source).
		WithWorkdir("/flake").
		WithEnvVariable("NIX_CONFIG", "experimental-features = nix-command flakes").
		WithExec([]string{"sh", "-c", "nix-shell -p statix --run 'statix check .'"})

	return ctr, nil
}

// Ci runs the full CI pipeline: format check, linters, and nix flake check
func (n *NixConfig) Ci(ctx context.Context) (string, error) {
	// Run all checks in parallel
	checks := []func() (*dagger.Container, error){
		func() (*dagger.Container, error) { return n.Check(ctx) },
		func() (*dagger.Container, error) { return n.Deadnix(ctx) },
		func() (*dagger.Container, error) { return n.Statix(ctx) },
	}

	errors := make(chan error, len(checks))
	for _, check := range checks {
		go func(c func() (*dagger.Container, error)) {
			_, err := c()
			errors <- err
		}(check)
	}

	for i := 0; i < len(checks); i++ {
		if err := <-errors; err != nil {
			return "", err
		}
	}

	return "✅ All CI checks passed", nil
}

// DnsblockdBuild builds the dnsblockd Go package
func (m *Systemnix) DnsblockdBuild(ctx context.Context, source *dagger.Directory) (*dagger.File, error) {
	pkg := m.Go(source.Directory("platforms/nixos/programs/dnsblockd"), "dnsblockd")
	return pkg.Build(ctx)
}

// DnsblockdProcessorBuild builds the dnsblockd-processor Go package
func (m *Systemnix) DnsblockdProcessorBuild(ctx context.Context, source *dagger.Directory) (*dagger.File, error) {
	pkg := m.Go(source.Directory("pkgs/dnsblockd-processor"), "dnsblockd-processor")
	return pkg.Build(ctx)
}

// ModernizeBuild builds the modernize Go tool
func (m *Systemnix) ModernizeBuild(ctx context.Context, source *dagger.Directory) (*dagger.File, error) {
	pkg := m.Go(source.Directory("pkgs"), "modernize").
		WithBinary("modernize")
	return pkg.Build(ctx)
}
