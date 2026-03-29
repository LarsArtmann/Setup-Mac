package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func main() {
	if len(os.Args) < 5 {
		fmt.Fprintf(os.Stderr, "Usage: %s BLOCK_IP WHITELIST_FILE UNBOUND_OUTPUT MAPPING_OUTPUT [HOSTS_FILE NAME]...\n", os.Args[0])
		os.Exit(1)
	}

	blockIP := os.Args[1]
	whitelistFile := os.Args[2]
	unboundOutput := os.Args[3]
	mappingOutput := os.Args[4]

	whitelist := make(map[string]bool)
	if f, err := os.Open(whitelistFile); err == nil {
		scanner := bufio.NewScanner(f)
		for scanner.Scan() {
			if d := strings.TrimSpace(scanner.Text()); d != "" {
				whitelist[d] = true
			}
		}
		f.Close()
	}

	seen := make(map[string]bool)
	var unboundEntries []string
	mapping := make(map[string]string)

	args := os.Args[5:]
	for i := 0; i+1 < len(args); i += 2 {
		hostsFile := args[i]
		name := args[i+1]

		f, err := os.Open(hostsFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "warning: cannot open %s: %v\n", hostsFile, err)
			continue
		}

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
                if whitelist[domain] || seen[domain] {
                        continue
                }

                seen[domain] = true
                unboundEntries = append(unboundEntries, fmt.Sprintf(`local-data: "%s A %s"`, domain, blockIP))
                mapping[domain] = name
        }
        f.Close()
	}

	uf, err := os.Create(unboundOutput)
	if err != nil {
        fmt.Fprintf(os.Stderr, "error: creating %s: %v\n", unboundOutput, err)
        os.Exit(1)
  }
	for _, entry := range unboundEntries {
        fmt.Fprintln(uf, entry)
  }
	uf.Close()

	mf, err := os.Create(mappingOutput)
	if err != nil {
        fmt.Fprintf(os.Stderr, "error: creating %s: %v\n", mappingOutput, err)
        os.Exit(1)
  }
        enc := json.NewEncoder(mf)
        enc.SetEscapeHTML(false)
        if err := enc.Encode(mapping); err != nil {
        fmt.Fprintf(os.Stderr, "error: encoding mapping JSON: %v\n", err)
        os.Exit(1)
  }
        mf.Close()

        fmt.Fprintf(os.Stderr, "processed %d unique domains\n", len(unboundEntries))
}
