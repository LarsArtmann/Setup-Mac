# Generate a self-signed certificate for dnsblockd HTTPS server
# This cert is added to the system trust store so browsers don't show warnings
{
  runCommand,
  openssl,
  ...
}:
runCommand "dnsblockd-cert" {
  nativeBuildInputs = [openssl];
} ''
  mkdir -p $out

  # Generate ECDSA key and self-signed cert
  openssl req -x509 -newkey ec:<(openssl ecparam -name prime256v1) \
    -keyout $out/dnsblockd.key -out $out/dnsblockd.crt \
    -days 3650 -nodes -subj "/CN=dnsblockd/O=DNS Blocker" \
    -addext "subjectAltName=IP:127.0.0.2"

  # Set permissions
  chmod 644 $out/dnsblockd.crt
  chmod 600 $out/dnsblockd.key
''
