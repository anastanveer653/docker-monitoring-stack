# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [2.0.1] - 2026-10-31

### Added
- Unit tests for the 13 alerts that had none. All 21 alerts are now covered by `promtool` tests, and many include a healthy series that must not alert.
- Alert coverage check in `scripts/validate.sh` and CI: the build fails if an alert has no unit test or no runbook section.

### Fixed
- The README and repository description claimed every alert was tested, but only 8 of 21 were.

## [2.0.0] - 2026-10-31

### Added
- **Dashboards:** *Docker Containers*, *Endpoints & Uptime* and *Monitoring Stack Health*, plus a rebuilt *Host Overview* with host and datasource selectors.
- **Recording rules** for CPU, memory and container usage (`prometheus/rules/recording.yml`).
- **New alerts:** `HostDiskWillFillIn24Hours` (predictive), `HostOutOfInodes`, `HostHighLoad`, `HostOomKillDetected`, `ContainerOomKilled`, `SslCertificateExpiringSoon`, `TargetDown`, `Watchdog`, and self-monitoring alerts for Prometheus and Alertmanager.
- **Alert unit tests** with `promtool test rules` (`prometheus/tests/alerts_test.yml`).
- **Runbooks** for every alert (`docs/runbooks.md`), linked from each alert's `runbook_url`.
- **CI pipeline:** ShellCheck, yamllint, config validation, rule unit tests and an end-to-end smoke test that boots the full stack.
- **Dependabot** for container images and GitHub Actions.
- **File-based service discovery:** add scrape and probe targets in `prometheus/targets/` without restarting.
- Grafana and Blackbox Exporter are now scraped; Alertmanager is provisioned as a Grafana datasource.
- Healthchecks for every service; `docker compose up --wait` starts services in dependency order.
- `Makefile`, `scripts/setup.sh` (random Grafana password), `scripts/validate.sh`, `scripts/smoke-test.sh`.
- Slack notification template and file-based secrets for Alertmanager.
- `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, issue and PR templates.

### Changed
- Upgraded Prometheus 2.51 → 3.15, Grafana 10.4 → 13.3, Alertmanager 0.27 → 0.34, Node Exporter 1.7 → 1.12, cAdvisor 0.49 → 0.60 (now on `ghcr.io`), Blackbox Exporter 0.24 → 0.29.
- UIs bind to `127.0.0.1` by default (`BIND_ADDRESS`); exporters are no longer published on the host.
- Warning and critical variants of an alert share one name so inhibition works.
- Alertmanager config uses the `matchers` syntax.
- Resource limits, `no-new-privileges` and log rotation on all services.
- Dashboards are read-only in the UI and managed as code.

### Fixed
- `start.sh` exited with an error when `.env` contained inline comments.
- `reload-prometheus.sh` expanded the rules glob on the host, so `promtool check rules` always failed. Replaced by `reload.sh`, which also reloads Alertmanager.
- `ContainerHighMemory` fired for every container without a memory limit (division by a limit of 0).
- `ContainerDown` used `absent()`, which only fired when *no* container existed at all, without a container name.
- The critical → warning inhibition rule never matched because the alerts had different names.
- Slack configuration used `${SLACK_WEBHOOK_URL}`, which Alertmanager does not expand.
- Scripts were not executable in git.

### Removed
- `--web.enable-admin-api` (allowed unauthenticated deletion of TSDB data).
- The `icmp_ping` Blackbox module (needs `NET_RAW` and did not work as an unprivileged user).
- The obsolete Compose `version` key.

## [1.0.0] - 2026-04-02

### Added
- Initial release: Prometheus, Grafana, Alertmanager, Node Exporter, cAdvisor and Blackbox Exporter with Docker Compose.

[2.0.1]: https://github.com/anastanveer653/docker-monitoring-stack/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/anastanveer653/docker-monitoring-stack/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/anastanveer653/docker-monitoring-stack/releases/tag/v1.0.0
