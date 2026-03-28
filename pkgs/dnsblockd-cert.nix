# Generate a proper CA + server certificate for dnsblockd HTTPS server
# Firefox rejects CA certs used as end-entity, so we need:
# 1. CA cert (trusted) -> 2. Server cert (signed by CA)
{
  runCommand,
  openssl,
  ...
}:
runCommand "dnsblockd-cert" {
  nativeBuildInputs = [openssl];
} ''
  mkdir -p $out

  # 1. Generate CA private key
  openssl genrsa -out ca.key 2048

  # 2. Create CA certificate (CA:TRUE)
  openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
    -out $out/dnsblockd-ca.crt \
    -subj "/CN=dnsblockd-CA/O=DNS Blocker"

  # 3. Generate server private key
  openssl genrsa -out $out/dnsblockd.key 2048

  # 4. Create server CSR
  openssl req -new -key $out/dnsblockd.key \
    -out server.csr \
    -subj "/CN=dnsblockd/O=DNS Blocker"

  # 5. Create server cert extension config (CA:FALSE, server auth)
  cat > server.ext <<EOF
  authorityKeyIdentifier=keyid,issuer
  basicConstraints=CA:FALSE
  keyUsage=digitalSignature,keyEncipherment
  extendedKeyUsage=serverAuth
  subjectAltName=IP:127.0.0.2
  EOF

  # 6. Sign server cert with CA
  openssl x509 -req -in server.csr -CA $out/dnsblockd-ca.crt -CAkey ca.key \
    -CAcreateserial -out $out/dnsblockd.crt -days 3650 -sha256 \
    -extfile server.ext

  # Set permissions
  chmod 644 $out/dnsblockd.crt $out/dnsblockd-ca.crt
  chmod 600 $out/dnsblockd.key
''
