package main

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
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
	"strings"
	"sync"
	"sync/atomic"
	"text/template"
	"time"
)

type Config struct {
	ListenAddr  string
	Port        int
	TLSPort     int
	StatsAddr   string
	StatsPort   int
	CertFile    string
	KeyFile     string
	Categories  map[string]string
}

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

type BlockPageData struct {
	Domain    string
	Category  string
	Timestamp string
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
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#0f0f1a;color:#e0e0e0;display:flex;align-items:center;justify-content:center;min-height:100vh}
.container{max-width:560px;padding:2rem;text-align:center}
.shield{font-size:4rem;margin-bottom:1rem;opacity:0.8}
h1{font-size:1.5rem;font-weight:600;margin-bottom:0.5rem;color:#f38ba8}
.domain{font-family:monospace;font-size:1.1rem;padding:0.5rem 1rem;background:#1e1e2e;border-radius:8px;margin:1rem 0;word-break:break-all;color:#cdd6f4}
.category{display:inline-block;padding:0.25rem 0.75rem;background:#313244;border-radius:999px;font-size:0.85rem;margin-bottom:1.5rem;color:#a6adc8}
p{color:#6c7086;line-height:1.6;margin-bottom:1rem}
.meta{font-size:0.75rem;color:#45475a;margin-top:2rem}
a{color:#89b4fa;text-decoration:none}
</style>
</head>
<body>
<div class="container">
<div class="shield">&#x1F6E1;</div>
<h1>Domain Blocked</h1>
<div class="domain">{{.Domain}}</div>
{{ if .Category }}<div class="category">{{.Category}}</div>{{ end }}
<p>This domain has been blocked by your DNS filter. If you believe this is an error, you can whitelist it in your dns-blocker configuration.</p>
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

	cfgVal := r.Context().Value(contextKey{})
	cfg, ok := cfgVal.(*Config)
	if !ok {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	category := categorize(host, cfg.Categories)

	recordBlock(host, category)

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)

	data := BlockPageData{
		Domain:    host,
		Category:  category,
		Timestamp: time.Now().Format("2006-01-02 15:04:05 MST"),
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

func generateSelfSignedCert(certFile, keyFile string) error {
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return fmt.Errorf("failed to generate private key: %v", err)
	}

	template := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject: pkix.Name{
			Organization: []string{"dnsblockd"},
			CommonName:   "dnsblockd",
		},
		NotBefore:             time.Now(),
		NotAfter:              time.Now().Add(10 * 365 * 24 * time.Hour),
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		DNSNames:              []string{"*"},
		IPAddresses:           []net.IP{net.ParseIP("127.0.0.2")},
	}

	certDER, err := x509.CreateCertificate(rand.Reader, template, template, &priv.PublicKey, priv)
	if err != nil {
		return fmt.Errorf("failed to create certificate: %v", err)
	}

	certOut, err := os.Create(certFile)
	if err != nil {
		return fmt.Errorf("failed to create cert file: %v", err)
	}
	defer certOut.Close()
	pem.Encode(certOut, &pem.Block{Type: "CERTIFICATE", Bytes: certDER})

	keyOut, err := os.Create(keyFile)
	if err != nil {
		return fmt.Errorf("failed to create key file: %v", err)
	}
	defer keyOut.Close()
	privBytes, _ := x509.MarshalECPrivateKey(priv)
	pem.Encode(keyOut, &pem.Block{Type: "EC PRIVATE KEY", Bytes: privBytes})

	return nil
}

func main() {
	cfg := &Config{
		Categories: map[string]string{
			".doubleclick.net":     "Advertising",
			".googlesyndication.com": "Advertising",
			".googleadservices.com":  "Advertising",
			".adnxs.com":            "Advertising",
			".adsrvr.org":           "Advertising",
			".facebook.net":         "Tracking",
			".analytics.google.com": "Analytics",
			".google-analytics.com": "Analytics",
		},
	}

	flag.StringVar(&cfg.ListenAddr, "addr", "0.0.0.0", "HTTP listen address")
	flag.IntVar(&cfg.Port, "port", 80, "HTTP listen port")
	flag.IntVar(&cfg.TLSPort, "tls-port", 443, "HTTPS listen port (0 to disable)")
	flag.StringVar(&cfg.StatsAddr, "stats-addr", "127.0.0.1", "Stats API listen address")
	flag.IntVar(&cfg.StatsPort, "stats-port", 9090, "Stats API listen port")
	flag.StringVar(&cfg.CertFile, "cert", "", "TLS certificate file (auto-generated if not provided)")
	flag.StringVar(&cfg.KeyFile, "key", "", "TLS key file (auto-generated if not provided)")

	categoriesFile := flag.String("categories", "", "JSON file with domain->category mappings")
	flag.Parse()

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

	done := make(chan error, 3)

	// HTTP server
	go func() {
		addr := net.JoinHostPort(cfg.ListenAddr, fmt.Sprintf("%d", cfg.Port))
		log.Printf("dnsblockd %s listening on %s (HTTP block page)", version, addr)
		done <- http.ListenAndServe(addr, mux)
	}()

	// HTTPS server (for blocked HTTPS sites)
	if cfg.TLSPort > 0 {
		go func() {
			certFile := cfg.CertFile
			keyFile := cfg.KeyFile

			if certFile == "" || keyFile == "" {
				certFile = "/tmp/dnsblockd.crt"
				keyFile = "/tmp/dnsblockd.key"
				if err := generateSelfSignedCert(certFile, keyFile); err != nil {
					log.Printf("failed to generate cert: %v, skipping HTTPS", err)
					return
				}
				log.Printf("generated self-signed certificate for HTTPS")
			}

			addr := net.JoinHostPort(cfg.ListenAddr, fmt.Sprintf("%d", cfg.TLSPort))
			log.Printf("dnsblockd listening on %s (HTTPS block page)", addr)

			server := &http.Server{
				Addr:    addr,
				Handler: mux,
				TLSConfig: &tls.Config{
					MinVersion: tls.VersionTLS12,
				},
			}
			done <- server.ListenAndServeTLS(certFile, keyFile)
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
