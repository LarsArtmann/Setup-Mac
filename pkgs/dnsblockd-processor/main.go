// Package main provides a DNS block list processor that converts blocklists
// (hosts, domains, dnsmasq, or adblock format) into Unbound local-data
// entries and a domain-to-list mapping JSON file.
package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func isValidPath(path string) error {
	if strings.Contains(path, "..") {
		return errors.New("path traversal not allowed")
	}
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("cannot resolve path: %w", err)
	}
	if !filepath.IsAbs(absPath) {
		return errors.New("relative path not allowed")
	}
	return nil
}

func safeOpenFile(path string) (*os.File, error) {
	if err := isValidPath(path); err != nil {
		return nil, fmt.Errorf("invalid path %q: %w", path, err)
	}
	//nolint:gosec // G304: path validated by isValidPath()
	return os.Open(path)
}

func safeCreateFile(path string) (*os.File, error) {
	if err := isValidPath(path); err != nil {
		return nil, fmt.Errorf("invalid path %q: %w", path, err)
	}
	//nolint:gosec // G304: path validated by isValidPath()
	return os.Create(path)
}

func loadWhitelist(path string) map[string]bool {
	whitelist := make(map[string]bool)

	f, err := safeOpenFile(path)
	if err != nil {
		return whitelist
	}
	defer func() { _ = f.Close() }()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		if d := strings.TrimSpace(scanner.Text()); d != "" {
			whitelist[d] = true
		}
	}

	return whitelist
}

func extractDomain(line string) string {
	if strings.HasPrefix(line, "||") {
		domain := line[2:]
		if idx := strings.Index(domain, "^"); idx > 0 {
			domain = domain[:idx]
		}
		return domain
	}

	if strings.HasPrefix(line, "local=/") || strings.HasPrefix(line, "address=/") {
		var rest string
		if strings.HasPrefix(line, "local=/") {
			rest = line[len("local=/"):]
		} else {
			rest = line[len("address=/"):]
		}
		if idx := strings.Index(rest, "/"); idx > 0 {
			return rest[:idx]
		}
		return ""
	}

	fields := strings.Fields(line)
	if len(fields) == 1 {
		return fields[0]
	}
	if len(fields) >= 2 {
		return fields[1]
	}

	return ""
}

func isCommentOrEmpty(line string) bool {
	if line == "" {
		return true
	}
	return line[0] == '#' || line[0] == '!' || line[0] == '[' || strings.HasPrefix(line, "@@")
}

func isLocalhostOrLAN(domain string) bool {
	return domain == "localhost" || domain == "localhost.localdomain" ||
		strings.HasSuffix(domain, ".lan")
}

func shouldSkipDomain(domain string, whitelist, seen map[string]bool) bool {
	if domain == "" {
		return true
	}
	return whitelist[domain] || seen[domain]
}

func processLine(
	line, name, blockIP string,
	whitelist, seen map[string]bool,
	unboundEntries *[]string,
	mapping map[string]string,
) bool {
	if isCommentOrEmpty(line) {
		return false
	}

	domain := extractDomain(line)
	if shouldSkipDomain(domain, whitelist, seen) {
		return false
	}

	if isLocalhostOrLAN(domain) {
		return false
	}

	seen[domain] = true
	*unboundEntries = append(
		*unboundEntries,
		fmt.Sprintf(`local-data: "%s A %s"`, domain, blockIP),
	)
	mapping[domain] = name
	return true
}

func processHostsFile(
	path, name, blockIP string,
	whitelist, seen map[string]bool,
	unboundEntries *[]string,
	mapping map[string]string,
) {
	f, err := safeOpenFile(path)
	if err != nil {
		//nolint:gosec // G705: CLI tool writing to stderr, not HTML
		fmt.Fprintf(os.Stderr, "warning: cannot open %s: %v\n", path, err)
		return
	}
	defer func() { _ = f.Close() }()

	scanner := bufio.NewScanner(f)
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		processLine(line, name, blockIP, whitelist, seen, unboundEntries, mapping)
	}
}

func writeUnbound(path string, entries []string) error {
	f, err := safeCreateFile(path)
	if err != nil {
		return fmt.Errorf("creating %s: %w", path, err)
	}
	defer func() { _ = f.Close() }()

	for _, entry := range entries {
		if _, err := fmt.Fprintln(f, entry); err != nil {
			return fmt.Errorf("writing unbound output to %s: %w", path, err)
		}
	}

	return nil
}

func writeMapping(path string, mapping map[string]string) error {
	f, err := safeCreateFile(path)
	if err != nil {
		return fmt.Errorf("creating %s: %w", path, err)
	}
	defer func() { _ = f.Close() }()

	enc := json.NewEncoder(f)
	enc.SetEscapeHTML(false)

	if err := enc.Encode(mapping); err != nil {
		return fmt.Errorf("encoding mapping JSON to %s: %w", path, err)
	}

	return nil
}

func exitOnError(err error) {
	if err != nil {
		//nolint:gosec // G705: CLI tool writing to stderr, not HTML
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func main() {
	if len(os.Args) < 5 {
		fmt.Fprintf(
			os.Stderr,
			"Usage: %s BLOCK_IP WHITELIST_FILE UNBOUND_OUTPUT MAPPING_OUTPUT [LIST_FILE NAME]...\n",
			os.Args[0],
		)
		os.Exit(1)
	}

	blockIP := os.Args[1]
	whitelistFile := os.Args[2]
	unboundOutput := os.Args[3]
	mappingOutput := os.Args[4]

	whitelist := loadWhitelist(whitelistFile)

	seen := make(map[string]bool)
	var unboundEntries []string
	mapping := make(map[string]string)

	args := os.Args[5:]
	for i := 0; i+1 < len(args); i += 2 {
		processHostsFile(
			args[i], args[i+1], blockIP,
			whitelist, seen, &unboundEntries, mapping,
		)
	}

	exitOnError(writeUnbound(unboundOutput, unboundEntries))
	exitOnError(writeMapping(mappingOutput, mapping))

	fmt.Fprintf(os.Stderr, "processed %d unique domains\n", len(unboundEntries))
}
