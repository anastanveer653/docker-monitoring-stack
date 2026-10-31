# Security Policy

## Reporting a vulnerability

Please **do not open a public issue** for security problems. Report them
privately through [GitHub Security Advisories](https://github.com/anastanveer653/docker-monitoring-stack/security/advisories/new).
You can expect an initial response within 72 hours.

## Security model of this stack

The defaults are chosen to be safe on a single host:

| Area | Default |
|---|---|
| Network exposure | Grafana, Prometheus and Alertmanager bind to `127.0.0.1` only. Exporters are not published on the host at all. |
| Grafana | Admin password must be set (`scripts/setup.sh` generates a random one); sign-up and anonymous access are disabled. |
| Prometheus | Admin API disabled. The lifecycle API (`/-/reload`) is enabled and therefore only reachable from localhost. |
| Secrets | Read from gitignored files in `alertmanager/secrets/`, never from the committed config. |
| Containers | `no-new-privileges`, CPU/memory limits, read-only root filesystems for the exporters. |
| Images | Pinned versions, updated weekly by Dependabot. |

**cAdvisor runs privileged** because it must read cgroup data for every container
on the host. It is not published on any host port.

## Before exposing the stack to a network

Prometheus and Alertmanager have **no authentication** of their own. If you set
`BIND_ADDRESS=0.0.0.0`, put the stack behind a reverse proxy (Traefik, Caddy,
Nginx) that provides TLS and authentication, or restrict access with a firewall.
