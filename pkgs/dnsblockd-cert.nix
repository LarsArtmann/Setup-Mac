{
  runCommand,
  openssl,
  ...
}:
runCommand "dnsblockd-cert" {
  nativeBuildInputs = [openssl];
} ''
  mkdir -p $out

  openssl genrsa -out $out/dnsblockd-ca.key 2048

  openssl req -x509 -new -nodes -key $out/dnsblockd-ca.key \
    -sha256 -days 3650 \
    -out $out/dnsblockd-ca.crt \
    -subj "/CN=dnsblockd-CA/O=DNS Blocker"

  openssl genrsa -out $out/dnsblockd-server.key 2048

  openssl req -new -key $out/dnsblockd-server.key \
    -out $out/dnsblockd-server.csr \
    -subj "/CN=*.lan/O=DNS Blocker"

  cat > $out/san.ext <<EOF
  authorityKeyIdentifier=keyid,issuer
  basicConstraints=CA:FALSE
  keyUsage = digitalSignature, keyEncipherment
  subjectAltName = @alt_names

  [alt_names]
  DNS.1 = *.lan
  DNS.2 = immich.lan
  DNS.3 = gitea.lan
  DNS.4 = grafana.lan
  DNS.5 = home.lan
  EOF

  openssl x509 -req -in $out/dnsblockd-server.csr \
    -CA $out/dnsblockd-ca.crt -CAkey $out/dnsblockd-ca.key \
    -CAcreateserial -days 3650 -sha256 \
    -extfile $out/san.ext \
    -out $out/dnsblockd-server.crt

  chmod 644 $out/dnsblockd-ca.crt $out/dnsblockd-server.crt
  chmod 600 $out/dnsblockd-ca.key $out/dnsblockd-server.key
  rm $out/dnsblockd-server.csr $out/san.ext $out/dnsblockd-ca.srl
''
