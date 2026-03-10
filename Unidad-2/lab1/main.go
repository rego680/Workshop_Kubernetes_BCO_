package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"
)

var startTime = time.Now()

func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/info", infoHandler)

	port := "8080"
	log.Printf("Go server starting on port %s", port)
	log.Printf("Multi-stage build demo - Unidad 2, Lab 1")
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	uptime := time.Since(startTime).Round(time.Second)

	html := fmt.Sprintf(`<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Lab 1 - Multi-Stage Go</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: 'Segoe UI', sans-serif;
    background: linear-gradient(135deg, #1a1a2e, #16213e, #0f3460);
    color: #fff;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .card {
    background: rgba(255,255,255,0.06);
    border: 1px solid rgba(255,255,255,0.12);
    border-radius: 16px;
    padding: 40px;
    max-width: 520px;
    text-align: center;
    backdrop-filter: blur(10px);
  }
  .icon { font-size: 3.5rem; margin-bottom: 10px; }
  h1 { font-size: 1.6rem; margin-bottom: 6px; color: #00d2ff; }
  .sub { color: #888; font-size: 0.85rem; margin-bottom: 24px; }
  .info {
    background: rgba(0,0,0,0.3);
    border-radius: 8px;
    padding: 16px;
    text-align: left;
    font-family: monospace;
    font-size: 0.85rem;
    line-height: 2;
  }
  .label { color: #888; }
  .value { color: #00d2ff; }
  .highlight { color: #00ff88; font-weight: bold; }
  .footer { margin-top: 20px; color: #555; font-size: 0.7rem; }
</style>
</head>
<body>
<div class="card">
  <div class="icon">&#x1F680;</div>
  <h1>Multi-Stage Build</h1>
  <div class="sub">Unidad 2 - Lab 1 | Go + scratch</div>
  <div class="info">
    <span class="label">Hostname:</span> <span class="value">%s</span><br>
    <span class="label">Go Version:</span> <span class="value">%s</span><br>
    <span class="label">OS/Arch:</span> <span class="value">%s/%s</span><br>
    <span class="label">Uptime:</span> <span class="value">%s</span><br>
    <span class="label">Base Image:</span> <span class="highlight">scratch (0 bytes)</span><br>
    <span class="label">Final Size:</span> <span class="highlight">~10-15 MB</span>
  </div>
  <div class="footer">Build: golang:1.22-alpine → scratch</div>
</div>
</body>
</html>`, hostname, runtime.Version(), runtime.GOOS, runtime.GOARCH, uptime)

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, html)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprint(w, `{"status":"ok","service":"go-server-lab1"}`)
}

func infoHandler(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	uptime := time.Since(startTime).Round(time.Second)
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"hostname":"%s","go_version":"%s","os":"%s","arch":"%s","uptime":"%s"}`,
		hostname, runtime.Version(), runtime.GOOS, runtime.GOARCH, uptime)
}
