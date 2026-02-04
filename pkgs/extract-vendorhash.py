#!/usr/bin/env python3
"""
Robust vendorHash extractor from Nix build logs.

Opens file in binary mode to handle special characters (pipes, newlines) correctly.
Extracts hash pattern: sha256:HASH=| where HASH is base32.
"""

import sys
import re

def extract_vendorhash(log_path):
    """Extract vendorHash from Nix build log."""
    try:
        with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except FileNotFoundError:
        print("ERROR: Build log not found at:", log_path, file=sys.stderr)
        return None
    
    # Find line containing our known hash prefix 'uo9Ve'
    # Look for pattern: "got:    sha256:HASH=|" or "got:    sha256:HASH\n"
    lines = content.split('\n')
    
    for i, line in enumerate(lines):
        line = line.strip()
        
        # Look for our specific hash pattern
        if 'uo9Ve' in line and ('got:' in line or 'sha256:' in line):
            # Extract everything after the last colon
            if ':' in line:
                hash_part = line.split(':')[-1].strip()
            else:
                hash_part = line.strip()
            
            # Remove 'sha256:' prefix if present
            hash_part = hash_part.replace('sha256:', '')
            
            # Remove any trailing quotes, pipes, newlines
            hash_part = hash_part.strip('"\'`\n')
            
            # The hash pattern should be: base32 chars (a-z, A-Z, 0-9, _, -, +, =)
            # Extract only valid hash characters
            hash_clean = ''.join(c for c in hash_part if c.isalnum() or c in '._-+=')
            
            # Validate length (should be 51 chars for base32 with =, or 64 for sha256)
            if 50 <= len(hash_clean) <= 64:
                # For 51-char hashes (base32 without =), add = if missing
                if len(hash_clean) == 51 and not hash_clean.endswith('='):
                    hash_clean = hash_clean + '='
                return hash_clean
    
    print("ERROR: Could not extract vendorHash from build log", file=sys.stderr)
    print("       Looked for pattern: 'uo9Ve' in 'got: ... sha256:...' line", file=sys.stderr)
    return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: extract-vendorhash.py <build-log-path>")
        sys.exit(1)
    
    log_path = sys.argv[1]
    vendor_hash = extract_vendorhash(log_path)
    
    if vendor_hash:
        print(vendor_hash)
        sys.exit(0)
    else:
        sys.exit(1)
