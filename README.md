# 📊 Docker Monitoring Stack

![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)
![Prometheus](https://img.shields.io/badge/Prometheus-v2.51-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-v10.4-F46800?logo=grafana)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Production--Ready-brightgreen)

A complete, production-ready monitoring stack using **Prometheus**, **Grafana**, **Alertmanager**, **Node Exporter**, **cAdvisor**, and **Blackbox Exporter** — all orchestrated with Docker Compose.

Spin up full observability in under 2 minutes.

---

## 🧱 Stack Components

| Service | Image | Port | Purpose |
|---|---|---|---|
| **Prometheus** | `prom/prometheus:v2.51.0` | `9090` | Metrics collection & storage |
| **Grafana** | `grafana/grafana:10.4.2` | `3000` | Visualization & dashboards |
| **Alertmanager** | `prom/alertmanager:v0.27.0` | `9093` | Alert routing & deduplication |
| **Node Exporter** | `prom/node-exporter:v1.7.0` | `9100` | Host system metrics (CPU, RAM, Disk) |
| **cAdvisor** | `gcr.io/cadvisor/cadvisor:v0.49.1` | `8080` | Container resource metrics |
| **Blackbox Exporter** | `prom/blackbox-exporter:v0.24.0` | `9115` | HTTP/TCP endpoint probing |

---

## 🏗️ Architecture

```
                        ┌─────────────────┐
                        │    Grafana :3000 │◄──── You (browser)
                        └────────┬────────┘
                                 │ queries
                                 ▼
                        ┌─────────────────┐
          ┌─────────────│  Prometheus:9090 │─────────────┐
          │             └────────┬────────┘             │
          │ scrapes              │ fires alerts          │ scrapes
          ▼                     ▼                       ▼
  ┌───────────────┐   ┌──────────────────┐   ┌─────────────────────┐
  │ Node Exporter │   │  Alertmanager    │   │ cAdvisor + Blackbox  │
  │ :9100         │   │  :9093           │   │ :8080 / :9115        │
  │ (host metrics)│   │  (Slack / email) │   │ (containers/probing) │
  └───────────────┘   └──────────────────┘   └─────────────────────┘
```

---

## ✅ Features

- **Pre-built Host Overview dashboard** auto-provisioned in Grafana
- **Alert rules** for CPU, memory, disk, container health, and endpoint uptime
- **Alertmanager** with routing tree: critical vs warning, inhibition rules, Slack/email stubs
- **Blackbox Exporter** for HTTP probe monitoring of external URLs
- **Hot-reload** support — update Prometheus config without restarting
- **Data retention**: 30 days in Prometheus (configurable)
- **Persistent volumes** — data survives container restarts

---

## 🚀 Quick Start

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) ≥ 24.x
- [Docker Compose](https://docs.docker.com/compose/install/) v2 plugin

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/docker-monitoring-stack.git
cd docker-monitoring-stack
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env and set GRAFANA_ADMIN_PASSWORD
```

### 3. Start the stack
```bash
./scripts/start.sh
# or manually:
docker compose up -d
```

### 4. Open Grafana
Visit [http://localhost:3000](http://localhost:3000)
- **Username**: `admin`
- **Password**: value from `.env` (default: `changeme`)

The **Host Overview** dashboard is auto-provisioned under `Dashboards → Monitoring`.

---

## 📂 Project Structure

```
docker-monitoring-stack/
├── docker-compose.yml
├── .env.example
├── .gitignore
│
├── prometheus/
│   ├── prometheus.yml          # Scrape configs & alerting connection
│   ├── blackbox.yml            # Blackbox exporter module config
│   └── rules/
│       └── alerts.yml          # Alert rules (CPU, memory, disk, containers)
│
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml  # Auto-configure Prometheus datasource
│   │   └── dashboards/
│   │       └── dashboards.yml  # Auto-load dashboard files
│   └── dashboards/
│       └── host-overview.json  # Pre-built host metrics dashboard
│
├── alertmanager/
│   └── alertmanager.yml        # Routing tree, receivers (Slack/email stubs)
│
└── scripts/
    ├── start.sh                # Start stack + print URLs
    ├── stop.sh                 # Stop stack (preserve volumes)
    └── reload-prometheus.sh    # Hot-reload config without restart
```

---

## 🔔 Configuring Alerts

### Slack
1. Create an [Incoming Webhook](https://api.slack.com/messaging/webhooks) in your Slack workspace
2. Add to `.env`:
   ```env
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
   ```
3. Uncomment the `slack_configs` section in `alertmanager/alertmanager.yml`
4. Run `./scripts/reload-prometheus.sh`

### Email
Uncomment and fill in the `smtp_*` globals and `email_configs` sections in `alertmanager/alertmanager.yml`.

---

## 📈 Adding Custom Scrape Targets

Edit `prometheus/prometheus.yml` and add a new job:

```yaml
- job_name: "my-app"
  static_configs:
    - targets: ["my-app-host:8080"]
  metrics_path: /metrics
```

Then hot-reload:
```bash
./scripts/reload-prometheus.sh
```

---

## 🧹 Stopping & Cleanup

```bash
# Stop containers (preserve data volumes)
./scripts/stop.sh

# Stop AND delete all volumes (full reset)
docker compose down -v
```

---

## 📄 License

MIT © [Your Name](https://github.com/YOUR_USERNAME)
