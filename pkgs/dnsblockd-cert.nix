# Generate CA certificate and key for dnsblockd HTTPS server
# Go dynamically generates server certs for each blocked domain signed by this CA
{
  runCommand,
  openssl,
  ...
}:
runCommand "dnsblockd-cert" {
  nativeBuildInputs = [openssl];
} ''
  mkdir -p $out

  # Generate CA private key (kept in output for Go to use)
  openssl genrsa -out $out/dnsblockd-ca.key 2048

  # Generate CA certificate (CA:TRUE, trusted by browsers)
  openssl req -x509 -new -nodes -key $out/dnsblockd-ca.key \
    -sha256 -days 3650 \
    -out $out/dnsblockd-ca.crt \
    -subj "/CN=dnsblockd-CA/O=DNS Blocker"

  # Set permissions
  chmod 644 $out/dnsblockd-ca.crt
  chmod 600 $out/dnsblockd-ca.key
''
