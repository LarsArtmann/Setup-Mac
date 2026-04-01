// Package main provides a DNS block list processor that converts hosts files
// into Unbound local-data entries and a domain-to-list mapping JSON file.
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func loadWhitelist(path string) map[string]bool {
	whitelist := make(map[string]bool)

	f, err := os.Open(path)
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

func processHostsFile(
	path, name, blockIP string,
	whitelist, seen map[string]bool,
	unboundEntries *[]string,
	mapping map[string]string,
) {
	f, err := os.Open(path)
	if err != nil {
		fmt.Fprintf(
			os.Stderr,
			"warning: cannot open %s: %v\n",
			path,
			err,
		)
		return
	}
	defer func() { _ = f.Close() }()

	scanner := bufio.NewScanner(f)
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}

		domain := fields[1]
		if domain == "localhost" || domain == "localhost.localdomain" {
			continue
		}

		if strings.HasSuffix(domain, ".lan") {
			continue
		}

		if whitelist[domain] || seen[domain] {
			continue
		}

		seen[domain] = true
		*unboundEntries = append(
			*unboundEntries,
			fmt.Sprintf(`local-data: "%s A %s"`, domain, blockIP),
		)
		mapping[domain] = name
	}
}

func writeUnbound(path string, entries []string) error {
	f, err := os.Create(path)
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
	f, err := os.Create(path)
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

// exitOnError checks err and exits with code 1 if error is not nil.
func exitOnError(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func main() {
	if len(os.Args) < 5 {
		fmt.Fprintf(
			os.Stderr,
			"Usage: %s BLOCK_IP WHITELIST_FILE UNBOUND_OUTPUT MAPPING_OUTPUT [HOSTS_FILE NAME]...\n",
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
