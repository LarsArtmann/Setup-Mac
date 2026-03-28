package main

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"flag"
	"fmt"
	"log"
	"math/big"
	"net"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync"
	"sync/atomic"
	"text/template"
	"time"
)

type Config struct {
	ListenAddr        string
	Port              int
	TLSPort           int
	StatsAddr         string
	StatsPort         int
	CACertFile        string
	CAKeyFile         string
	Categories        map[string]string
	BlocklistMapping  map[string]string // domain -> source
	TempAllowlistPath string            // path to persist temp allowlist
}

type CertCache struct {
	caCert *x509.Certificate
	caKey  *rsa.PrivateKey
	mu     sync.RWMutex
	certs  map[string]*tls.Certificate
}

var certCache CertCache

type Stats struct {
	TotalBlocked atomic.Int64 `json:"total_blocked"`
	TopDomains   []DomainHit  `json:"top_domains"`
	RecentBlocks []BlockEntry `json:"recent_blocks"`
	Start        time.Time    `json:"start_time"`
}

type DomainHit struct {
	Domain string `json:"domain"`
	Count  int64  `json:"count"`
}

type BlockEntry struct {
	Domain   string `json:"domain"`
	Category string `json:"category"`
	Time     string `json:"time"`
}

type TempAllowEntry struct {
	Domain    string    `json:"domain"`
	ExpiresAt time.Time `json:"expires_at"`
}

var (
	tempAllowlist     map[string]TempAllowEntry
	tempAllowlistMu   sync.RWMutex
	tempAllowlistPath string
)

type BlockPageData struct {
	Domain          string
	Category        string
	BlocklistSource string
	Timestamp       string
}

type contextKey struct{}

var (
	stats      Stats
	domainHits sync.Map
	version    = "dev"
)

const blockPageHTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Blocked - {{.Domain}}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:100dvw;height:100dvh}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#0f0f1a;color:#e0e0e0;display:flex;align-items:center;justify-content:center}
.container{max-width:min(90dvw,700px);padding:3rem;text-align:center}
.shield{font-size:clamp(4rem,10dvw,8rem);margin-bottom:1.5rem;opacity:0.8}
h1{font-size:clamp(1.5rem,4dvw,2.5rem);font-weight:600;margin-bottom:0.5rem;color:#f38ba8}
.domain{font-family:monospace;font-size:clamp(1rem,2.5dvw,1.4rem);padding:0.75rem 1.5rem;background:#1e1e2e;border-radius:12px;margin:1.5rem 0;word-break:break-all;color:#cdd6f4}
.source{font-family:monospace;font-size:clamp(0.8rem,2dvw,1rem);color:#74c7ec;margin-bottom:1rem}
.category{display:inline-block;padding:0.4rem 1rem;background:#313244;border-radius:999px;font-size:clamp(0.85rem,2dvw,1.1rem);margin-bottom:2rem;color:#a6adc8}
p{font-size:clamp(1rem,2.5dvw,1.2rem);color:#6c7086;line-height:1.7;margin-bottom:1.5rem}
.meta{font-size:clamp(0.75rem,1.5dvw,0.9rem);color:#45475a;margin-top:2.5rem}
a{color:#89b4fa;text-decoration:none}
.bypass{margin-top:2rem;display:flex;gap:0.5rem;flex-wrap:wrap;justify-content:center}
.bypass form{display:inline}
.bypass-btn{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;border:none;padding:0.6rem 1.2rem;border-radius:8px;font-size:clamp(0.8rem,2dvw,1rem);cursor:pointer;transition:transform 0.2s,box-shadow 0.2s}
.bypass-btn:hover{transform:translateY(-2px);box-shadow:0 4px 12px rgba(102,126,234,0.4)}
.bypass-btn:active{transform:translateY(0)}
</style>
</head>
<body>
<div class="container">
<div class="shield">&#x1F6E1;</div>
<h1>Domain Blocked</h1>
<div class="domain">{{.Domain}}</div>
{{ if .BlocklistSource }}<div class="source">{{.BlocklistSource}}</div>{{ end }}
{{ if .Category }}<div class="category">{{.Category}}</div>{{ end }}
<p>This domain has been blocked by your DNS filter. If you believe this is an error, you can whitelist it in your dns-blocker configuration.</p>
<div class="bypass">
<form action="/api/allow" method="post">
<input type="hidden" name="domain" value="{{.Domain}}">
<button type="submit" class="bypass-btn">Allow 5m</button>
</form>
<form action="/api/allow" method="post">
<input type="hidden" name="domain" value="{{.Domain}}">
<input type="hidden" name="duration" value="15m">
<button type="submit" class="bypass-btn">Allow 15m</button>
</form>
<form action="/api/allow" method="post">
<input type="hidden" name="domain" value="{{.Domain}}">
<input type="hidden" name="duration" value="60m">
<button type="submit" class="bypass-btn">Allow 1h</button>
</form>
</div>
<div class="meta">{{.Timestamp}} &middot; dnsblockd/{{ .Version }}</div>
</div>
</body>
</html>`

var tmpl *template.Template

func init() {
	var err error
	tmpl, err = template.New("blockpage").Parse(blockPageHTML)
	if err != nil {
		log.Fatalf("failed to parse template: %v", err)
	}
	stats.Start = time.Now()
	certCache.certs = make(map[string]*tls.Certificate)
	tempAllowlist = make(map[string]TempAllowEntry)
}

func loadTempAllowlist(path string) {
	data, err := os.ReadFile(path)
	if err != nil {
		if !os.IsNotExist(err) {
			return
		}
		log.Printf("failed to read temp allowlist: %v", err)
		return
	}
	var entries []TempAllowEntry
	if err := json.Unmarshal(data, &entries); err != nil {
		log.Printf("failed to parse temp allowlist: %v", err)
		return
	}
	now := time.Now()
	tempAllowlistMu.Lock()
	defer tempAllowlistMu.Unlock()
	for _, e := range entries {
		if e.ExpiresAt.After(now) {
			tempAllowlist[e.Domain] = e
		}
	}
	log.Printf("loaded %d temp allowlist entries", len(tempAllowlist))
}

func saveTempAllowlist(path string) {
	tempAllowlistMu.RLock()
	entries := make([]TempAllowEntry, 0, len(tempAllowlist))
	for _, e := range tempAllowlist {
		entries = append(entries, e)
	}
	tempAllowlistMu.RUnlock()

	data, err := json.MarshalIndent(entries, "", "  ")
	if err != nil {
		log.Printf("failed to marshal temp allowlist: %v", err)
		return
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		log.Printf("failed to write temp allowlist: %v", err)
	}
}

func addTempAllow(domain string, duration time.Duration) {
	expiresAt := time.Now().Add(duration)
	tempAllowlistMu.Lock()
	tempAllowlist[domain] = TempAllowEntry{
		Domain:    domain,
		ExpiresAt: expiresAt,
	}
	tempAllowlistMu.Unlock()

	if tempAllowlistPath != "" {
		saveTempAllowlist(tempAllowlistPath)
		if err := generateUnboundAllowlist(); err != nil {
			log.Printf("failed to generate unbound allowlist: %v", err)
		}
		if err := reloadUnbound(); err != nil {
			log.Printf("failed to reload unbound: %v", err)
		}
	}
}

func isTempAllowed(domain string) bool {
	tempAllowlistMu.RLock()
	defer tempAllowlistMu.RUnlock()
	entry, ok := tempAllowlist[domain]
	if !ok {
		return false
	}
	return time.Now().Before(entry.ExpiresAt)
}

func cleanupExpiredTempAllows() {
	now := time.Now()
	changed := false

	tempAllowlistMu.Lock()
	defer tempAllowlistMu.Unlock()

	for domain, entry := range tempAllowlist {
		if now.After(entry.ExpiresAt) {
			delete(tempAllowlist, domain)
			changed = true
		}
	}

	if changed && tempAllowlistPath != "" {
		saveTempAllowlist(tempAllowlistPath)
		if err := generateUnboundAllowlist(); err != nil {
			log.Printf("failed to regenerate unbound allowlist: %v", err)
		}
		if err := reloadUnbound(); err != nil {
			log.Printf("failed to reload unbound: %v", err)
		}
	}
}

func generateUnboundAllowlist() error {
	if tempAllowlistPath == "" {
		return nil
	}
	allowlistConf := tempAllowlistPath + ".conf"

	tempAllowlistMu.RLock()
	var lines []string
	for domain, entry := range tempAllowlist {
		if time.Now().Before(entry.ExpiresAt) {
			lines = append(lines, fmt.Sprintf("local-zone: \"%s\" transparent", domain))
		}
	}
	tempAllowlistMu.RUnlock()

	content := "# Auto-generated by dnsblockd - DO NOT EDIT\n"
	if len(lines) > 0 {
		content += strings.Join(lines, "\n") + "\n"
	}

	return os.WriteFile(allowlistConf, []byte(content), 0644)
}

func reloadUnbound() error {
	cmd := exec.Command("unbound-control", "reload")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("unbound-control reload failed: %v\n%s", err, output)
	}
	log.Printf("reloaded unbound with temp allowlist")
	return nil
}

func loadCA(certFile, keyFile string) error {
	certPEM, err := os.ReadFile(certFile)
	if err != nil {
		return fmt.Errorf("failed to read CA cert: %v", err)
	}

	keyPEM, err := os.ReadFile(keyFile)
	if err != nil {
		return fmt.Errorf("failed to read CA key: %v", err)
	}

	block, _ := pem.Decode(certPEM)
	if block == nil {
		return fmt.Errorf("failed to decode CA cert PEM")
	}
	certCache.caCert, err = x509.ParseCertificate(block.Bytes)
	if err != nil {
		return fmt.Errorf("failed to parse CA cert: %v", err)
	}

	block, _ = pem.Decode(keyPEM)
	if block == nil {
		return fmt.Errorf("failed to decode CA key PEM")
	}

	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		key, err = x509.ParsePKCS1PrivateKey(block.Bytes)
		if err != nil {
			return fmt.Errorf("failed to parse CA key: %v", err)
		}
	}

	var ok bool
	certCache.caKey, ok = key.(*rsa.PrivateKey)
	if !ok {
		return fmt.Errorf("CA key is not RSA")
	}

	return nil
}

func getCertForDomain(domain string) (*tls.Certificate, error) {
	certCache.mu.RLock()
	if cert, ok := certCache.certs[domain]; ok {
		certCache.mu.RUnlock()
		return cert, nil
	}
	certCache.mu.RUnlock()

	certCache.mu.Lock()
	defer certCache.mu.Unlock()

	if cert, ok := certCache.certs[domain]; ok {
		return cert, nil
	}

	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, fmt.Errorf("failed to generate key: %v", err)
	}

	serial, err := rand.Int(rand.Reader, new(big.Int).Lsh(big.NewInt(1), 128))
	if err != nil {
		return nil, fmt.Errorf("failed to generate serial: %v", err)
	}

	template := &x509.Certificate{
		SerialNumber: serial,
		Subject: pkix.Name{
			Organization: []string{"dnsblockd"},
			CommonName:   domain,
		},
		NotBefore:             time.Now(),
		NotAfter:              time.Now().Add(365 * 24 * time.Hour),
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		DNSNames:              []string{domain, "*." + domain},
	}

	if net.ParseIP(domain) != nil {
		template.IPAddresses = []net.IP{net.ParseIP(domain)}
	}

	certDER, err := x509.CreateCertificate(rand.Reader, template, certCache.caCert, &priv.PublicKey, certCache.caKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create cert: %v", err)
	}

	certPEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: certDER})
	keyPEM := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(priv)})

	cert, err := tls.X509KeyPair(certPEM, keyPEM)
	if err != nil {
		return nil, fmt.Errorf("failed to load cert: %v", err)
	}

	certCache.certs[domain] = &cert
	log.Printf("generated certificate for %s", domain)

	return &cert, nil
}

func getCertificate(hello *tls.ClientHelloInfo) (*tls.Certificate, error) {
	domain := hello.ServerName
	if domain == "" {
		domain = "127.0.0.2"
	}

	domain = strings.TrimPrefix(domain, "www.")
	domain = strings.Split(domain, ":")[0]

	return getCertForDomain(domain)
}

func categorize(domain string, categories map[string]string) string {
	for suffix, cat := range categories {
		if strings.HasSuffix(domain, suffix) || domain == suffix {
			return cat
		}
	}
	return "blocked"
}

func recordBlock(domain, category string) {
	stats.TotalBlocked.Add(1)

	if val, ok := domainHits.Load(domain); ok {
		hit := val.(*DomainHit)
		hit.Count++
		domainHits.Store(domain, hit)
	} else {
		domainHits.Store(domain, &DomainHit{Domain: domain, Count: 1})
	}

	entry := BlockEntry{
		Domain:   domain,
		Category: category,
		Time:     time.Now().Format(time.RFC3339),
	}

	stats.RecentBlocks = append(stats.RecentBlocks, entry)
	if len(stats.RecentBlocks) > 100 {
		stats.RecentBlocks = stats.RecentBlocks[len(stats.RecentBlocks)-100:]
	}
}

func blockHandler(w http.ResponseWriter, r *http.Request) {
	host := r.Host
	if host == "" {
		host = r.URL.Host
	}

	host = strings.TrimPrefix(host, "www.")
	host = strings.Split(host, ":")[0]

	// Check if domain is temporarily allowed
	if isTempAllowed(host) {
		// Redirect to the actual domain
		http.Redirect(w, r, "https://"+host, http.StatusTemporaryRedirect)
		return
	}

	cfgVal := r.Context().Value(contextKey{})
	cfg, ok := cfgVal.(*Config)
	if !ok {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	category := categorize(host, cfg.Categories)
	source := ""
	if cfg.BlocklistMapping != nil {
		source = cfg.BlocklistMapping[host]
	}

	recordBlock(host, category)

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)

	data := BlockPageData{
		Domain:          host,
		Category:        category,
		BlocklistSource: source,
		Timestamp:       time.Now().Format("2006-01-02 15:04:05 MST"),
	}

	type ExtendedData struct {
		BlockPageData
		Version string
	}

	if err := tmpl.Execute(w, ExtendedData{BlockPageData: data, Version: version}); err != nil {
		log.Printf("template error: %v", err)
	}
}

func statsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	topDomains := make([]DomainHit, 0)
	domainHits.Range(func(key, value any) bool {
		topDomains = append(topDomains, *value.(*DomainHit))
		return true
	})

	type StatsResponse struct {
		TotalBlocked int64        `json:"total_blocked"`
		TopDomains   []DomainHit  `json:"top_domains"`
		RecentBlocks []BlockEntry `json:"recent_blocks"`
		Start        time.Time    `json:"start_time"`
	}

	resp := StatsResponse{
		TotalBlocked: stats.TotalBlocked.Load(),
		TopDomains:   topDomains,
		RecentBlocks: stats.RecentBlocks,
		Start:        stats.Start,
	}

	statsJSON, err := json.MarshalIndent(resp, "", "  ")
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	w.Write(statsJSON)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"ok","blocked":%d,"uptime":"%s"}`,
		stats.TotalBlocked.Load(),
		time.Since(stats.Start).Truncate(time.Second).String(),
	)
}

func allowHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	domain := r.FormValue("domain")
	if domain == "" {
		http.Error(w, "domain required", http.StatusBadRequest)
		return
	}

	// Parse duration (default 5m)
	durationStr := r.FormValue("duration")
	duration := 5 * time.Minute
	switch durationStr {
	case "15m":
		duration = 15 * time.Minute
	case "60m":
		duration = 60 * time.Minute
	case "24h":
		duration = 24 * time.Hour
	}

	addTempAllow(domain, duration)

	expiresAt := time.Now().Add(duration)
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprintf(w, `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Allowed - %s</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:100dvw;height:100dvh}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:linear-gradient(135deg,#1a1a2a 0%%2d1d3a 100%%3a3f4a);color:#e0e0e0;display:flex;align-items:center;justify-content:center}
.container{max-width:min(90dvw,700px);padding:3rem;text-align:center}
.icon{font-size:clamp(4rem,10dvw,6rem);margin-bottom:1.5rem}
h1{font-size:clamp(1.5rem,4dvw,2.5rem);font-weight:600;margin-bottom:0.5rem;color:#22c55e}
.domain{font-family:monospace;font-size:clamp(1rem,2.5dvw,1.4rem);padding:0.75rem 1.5rem;background:rgba(34,197,94,0.2);border-radius:12px;margin:1.5rem 0;color:#86efac}
.info{font-size:clamp(0.9rem,2dvw,1.1rem);color:#9ca3af}
.meta{margin-top:2rem;font-size:clamp(0.75rem,1.5dvw,0.9rem);color:#64748b}
a{color:#89b4fa;text-decoration:none}
</style>
</head>
<body>
<div class="container">
<div class="icon">✅</div>
<h1>Temporarily Allowed</h1>
<div class="domain">%s</div>
<p class="info">This domain has been allowed for <strong>%s</strong>.</p>
<p class="info">Blocklist bypass expires at <strong>%s</strong>.</p>
<p class="meta"><a href="https://%s">Continue to %s →</a></p>
</div>
</body>
</html>
`, domain, domain, durationStr, expiresAt.Format("3:04 PM"), domain, domain)
}

func tempAllowlistHandler(w http.ResponseWriter, r *http.Request) {
	tempAllowlistMu.RLock()
	defer tempAllowlistMu.RUnlock()

	entries := make([]TempAllowEntry, 0, len(tempAllowlist))
	for _, e := range tempAllowlist {
		entries = append(entries, e)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entries)
}

func main() {
	cfg := &Config{
		Categories: map[string]string{
			".doubleclick.net":       "Advertising",
			".googlesyndication.com": "Advertising",
			".googleadservices.com":  "Advertising",
			".adnxs.com":             "Advertising",
			".adsrvr.org":            "Advertising",
			".facebook.net":          "Tracking",
			".analytics.google.com":  "Analytics",
			".google-analytics.com":  "Analytics",
		},
	}

	flag.StringVar(&cfg.ListenAddr, "addr", "0.0.0.0", "HTTP listen address")
	flag.IntVar(&cfg.Port, "port", 80, "HTTP listen port")
	flag.IntVar(&cfg.TLSPort, "tls-port", 443, "HTTPS listen port (0 to disable)")
	flag.StringVar(&cfg.StatsAddr, "stats-addr", "127.0.0.1", "Stats API listen address")
	flag.IntVar(&cfg.StatsPort, "stats-port", 9090, "Stats API listen port")
	flag.StringVar(&cfg.CACertFile, "ca-cert", "", "CA certificate file for signing dynamic certs")
	flag.StringVar(&cfg.CAKeyFile, "ca-key", "", "CA private key file for signing dynamic certs")
	flag.StringVar(&tempAllowlistPath, "temp-allowlist", "", "Path to temp allowlist JSON file")

	categoriesFile := flag.String("categories", "", "JSON file with domain->category mappings")
	blocklistMappingFile := flag.String("blocklist-mapping", "", "JSON file mapping domains to their blocklist source")
	flag.Parse()

	if tempAllowlistPath != "" {
		loadTempAllowlist(tempAllowlistPath)
		go func() {
			for range time.Tick(time.Minute) {
				cleanupExpiredTempAllows()
			}
		}()
	}

	if *categoriesFile != "" {
		data, err := os.ReadFile(*categoriesFile)
		if err != nil {
			log.Fatalf("failed to read categories file: %v", err)
		}
		if err := json.Unmarshal(data, &cfg.Categories); err != nil {
			log.Fatalf("failed to parse categories file: %v", err)
		}
		log.Printf("loaded %d category rules from %s", len(cfg.Categories), *categoriesFile)
	}

	if *blocklistMappingFile != "" {
		data, err := os.ReadFile(*blocklistMappingFile)
		if err != nil {
			log.Fatalf("failed to read blocklist mapping file: %v", err)
		}
		cfg.BlocklistMapping = make(map[string]string)
		if err := json.Unmarshal(data, &cfg.BlocklistMapping); err != nil {
			log.Fatalf("failed to parse blocklist mapping file: %v", err)
		}
		log.Printf("loaded %d domain->source mappings from %s", len(cfg.BlocklistMapping), *blocklistMappingFile)
	}

	if cfg.TLSPort > 0 && (cfg.CACertFile == "" || cfg.CAKeyFile == "") {
		log.Fatalf("-ca-cert and -ca-key are required when -tls-port > 0")
	}

	if cfg.TLSPort > 0 {
		if err := loadCA(cfg.CACertFile, cfg.CAKeyFile); err != nil {
			log.Fatalf("failed to load CA: %v", err)
		}
		log.Printf("loaded CA certificate from %s", cfg.CACertFile)
	}

	if cfg.Port == 80 || cfg.Port == 443 || cfg.TLSPort == 443 {
		log.Printf("WARNING: low ports require root. Consider using high ports with reverse proxy.")
	}

	mux := http.NewServeMux()

	handler := func(h http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			ctx := context.WithValue(r.Context(), contextKey{}, cfg)
			h(w, r.WithContext(ctx))
		}
	}

	mux.HandleFunc("/", handler(blockHandler))

	statsMux := http.NewServeMux()
	statsMux.HandleFunc("/stats", statsHandler)
	statsMux.HandleFunc("/health", healthHandler)
	statsMux.HandleFunc("/api/allow", allowHandler)
	statsMux.HandleFunc("/api/temp-allowlist", tempAllowlistHandler)

	done := make(chan error, 3)

	// HTTP server
	go func() {
		addr := net.JoinHostPort(cfg.ListenAddr, fmt.Sprintf("%d", cfg.Port))
		log.Printf("dnsblockd %s listening on %s (HTTP block page)", version, addr)
		done <- http.ListenAndServe(addr, mux)
	}()

	// HTTPS server with dynamic cert generation
	if cfg.TLSPort > 0 {
		go func() {
			addr := net.JoinHostPort(cfg.ListenAddr, fmt.Sprintf("%d", cfg.TLSPort))
			log.Printf("dnsblockd listening on %s (HTTPS block page, dynamic certs)", addr)

			server := &http.Server{
				Addr:    addr,
				Handler: mux,
				TLSConfig: &tls.Config{
					MinVersion:     tls.VersionTLS12,
					GetCertificate: getCertificate,
				},
			}
			done <- server.ListenAndServeTLS("", "")
		}()
	}

	// Stats API
	go func() {
		addr := net.JoinHostPort(cfg.StatsAddr, fmt.Sprintf("%d", cfg.StatsPort))
		log.Printf("dnsblockd stats API on %s", addr)
		done <- http.ListenAndServe(addr, statsMux)
	}()

	if err := <-done; err != nil && err != http.ErrServerClosed {
		log.Fatalf("server error: %v", err)
	}
}
