# Alert Runbooks

Every alert in [`prometheus/rules/`](../prometheus/rules) links here through its
`runbook_url` annotation. Each entry answers three questions: **what it means**,
**how to investigate**, and **how to fix it**.

Severity levels:

| Severity   | Meaning                                                     | Expected response   |
|------------|-------------------------------------------------------------|---------------------|
| `critical` | User-facing impact now, or data loss is imminent            | Act immediately     |
| `warning`  | Something is degrading and will become critical if ignored  | Act within hours    |
| `none`     | Informational (heartbeat)                                   | No action           |

---

## Host

### HostHighCpuUsage

**Meaning:** Average CPU utilisation across all cores is above 85% (warning, 10m) or 95% (critical, 5m).

**Investigate**
- *Host Overview → CPU usage by mode*: is the time spent in `user`, `system` or `iowait`?
  High `iowait` means the bottleneck is disk, not CPU — see [HostDiskSpaceLow](#hostdiskspacelow) and the *Disk I/O utilisation* panel.
- *Docker Containers → CPU usage*: which container is responsible?
- On the host: `top -o %CPU` or `docker stats --no-stream`.

**Fix**
- Restart or scale the offending service; set `deploy.resources.limits.cpus` so one container cannot starve the others.
- If load is legitimate and sustained, add CPU capacity.

### HostHighMemoryUsage

**Meaning:** Less than 15% (warning) or 5% (critical) of memory is available. The kernel will start reclaiming page cache aggressively and may invoke the OOM killer.

**Investigate**
- *Docker Containers → Memory usage*: look for a container whose working set grows steadily (memory leak).
- On the host: `free -h`, `ps aux --sort=-rss | head`.

**Fix**
- Restart the leaking service and set a memory limit so it is OOM-killed on its own instead of taking the host down.
- Add swap as a safety buffer, or add RAM.

### HostDiskSpaceLow

**Meaning:** A writable filesystem is more than 80% (warning) or 90% (critical) full.

**Investigate**
- *Host Overview → Filesystem usage* shows which mount.
- `df -h` and `sudo du -xh --max-depth=1 <mountpoint> | sort -h | tail`.
- Docker is a common culprit: `docker system df`.

**Fix**
- `docker system prune` (unused images/containers/networks) and `docker builder prune`.
- Rotate logs — this stack already caps container logs at 3 × 10 MB per service.
- Lower Prometheus retention with `PROMETHEUS_RETENTION_TIME` / `PROMETHEUS_RETENTION_SIZE` in `.env`.
- Grow the volume.

### HostDiskWillFillIn24Hours

**Meaning:** Based on the last 6 hours of writes (`predict_linear`), the filesystem will be full within 24 hours. This fires *before* the static thresholds do.

**Investigate:** Find what is writing — `sudo iotop -o`, or `sudo find <mountpoint> -xdev -mmin -60 -size +100M`.

**Fix:** Same as [HostDiskSpaceLow](#hostdiskspacelow). If the growth is expected (e.g. a backup job), the alert resolves once the write rate drops.

### HostOutOfInodes

**Meaning:** Fewer than 10% of inodes are free. Writes fail with `No space left on device` even though `df -h` shows free space.

**Investigate:** `df -i`, then find directories with huge numbers of small files:
`sudo find <mountpoint> -xdev -type f | cut -d/ -f2-3 | sort | uniq -c | sort -n | tail`.

**Fix:** Delete the small files (caches, session files, mail queues). Long term, reformat with a higher inode count.

### HostHighLoad

**Meaning:** The 5-minute load average has been more than twice the number of CPU cores for 15 minutes. Processes are queuing for CPU or blocked on I/O.

**Investigate:** Compare with [HostHighCpuUsage](#hosthighcpuusage). High load with low CPU usage usually means processes stuck in uninterruptible I/O (`ps -eo state,pid,cmd | grep '^D'`).

**Fix:** Address the CPU or I/O bottleneck identified above.

### HostOomKillDetected

**Meaning:** The kernel OOM killer terminated at least one process in the last 5 minutes.

**Investigate:** `sudo dmesg -T | grep -i -E 'killed process|out of memory'` shows which process was killed and how much memory it used.

**Fix:** See [HostHighMemoryUsage](#hosthighmemoryusage). Set container memory limits so the right process is killed.

---

## Containers

### ContainerDown

**Meaning:** A container that was running in the last 15 minutes is no longer reported by cAdvisor. It crashed, was stopped, or was removed. The alert resolves automatically 15 minutes after the container is gone, or as soon as it comes back.

**Investigate**
- `docker ps -a --filter name=<name>` — check `STATUS` and the exit code.
- `docker logs --tail 100 <name>`.
- `docker inspect <name> --format '{{.State.OOMKilled}} {{.State.ExitCode}} {{.State.Error}}'`.

**Fix:** Address the root cause in the logs, then `docker start <name>`. Use `restart: unless-stopped` for services that should always run. If you stopped it on purpose, ignore or silence the alert in Alertmanager.

### ContainerHighCpuUsage

**Meaning:** A container has used more than 80% of one CPU core for 10 minutes.

**Investigate:** *Docker Containers → CPU usage*. Correlate with traffic or a recent deploy.

**Fix:** Profile the application, scale horizontally, or raise its CPU limit.

### ContainerHighMemoryUsage

**Meaning:** A container is using more than 85% of its configured memory limit. Containers without a limit are intentionally not evaluated.

**Investigate:** *Docker Containers → Memory usage* — a steadily rising line is a leak; a flat line close to the limit means the limit is too low.

**Fix:** Raise the limit (`deploy.resources.limits.memory`) or fix the leak. If nothing changes, expect [ContainerOomKilled](#containeroomkilled).

### ContainerOomKilled

**Meaning:** A container hit its memory limit and the kernel killed it.

**Investigate:** `docker inspect <name> --format '{{.State.OOMKilled}}'` and the memory panel just before the event.

**Fix:** See [ContainerHighMemoryUsage](#containerhighmemoryusage).

---

## Endpoints

### EndpointDown

**Meaning:** The Blackbox Exporter probe for an endpoint has failed for 2 minutes (connection error, timeout, TLS error, or a non-2xx status code).

**Investigate**
- *Endpoints & Uptime → Endpoints* table shows the HTTP status code.
- Debug the probe directly — the response explains which step failed:
  `docker compose exec prometheus wget -qO- 'http://blackbox-exporter:9115/probe?module=http_2xx&target=<url>&debug=true'`
- From the host: `curl -sv <url>`.

**Fix:** Restore the service. If the endpoint was intentionally retired, remove it from `prometheus/targets/blackbox-http.yml`.

### EndpointSlowResponse

**Meaning:** The average probe duration over 5 minutes is above 2 seconds.

**Investigate:** *Endpoints & Uptime → HTTP request phases* shows where the time is spent: `resolve` (DNS), `connect` (network), `tls`, `processing` (server), or `transfer`.

**Fix:** Depends on the phase — DNS provider, network path, TLS termination, or application performance.

### SslCertificateExpiringSoon

**Meaning:** The TLS certificate served by an endpoint expires in less than 14 days (warning) or 3 days (critical).

**Investigate:** `echo | openssl s_client -connect <host>:443 -servername <host> 2>/dev/null | openssl x509 -noout -dates -issuer`.

**Fix:** Renew the certificate. With Let's Encrypt, check why auto-renewal failed: `sudo certbot renew --dry-run`.

---

## Monitoring stack

### Watchdog

**Meaning:** This alert is **always firing** by design. It proves the whole pipeline — Prometheus → rules → Alertmanager → receiver — works end to end.

**Action:** Route it to a dead man's switch such as [Healthchecks.io](https://healthchecks.io) or [Dead Man's Snitch](https://deadmanssnitch.com) using the `watchdog` receiver in `alertmanager/alertmanager.yml`. That service pages you when the heartbeat *stops*. Never route it to humans.

### TargetDown

**Meaning:** Prometheus could not scrape a target for 2 minutes. Every other alert for that instance is inhibited, because its data is missing.

**Investigate**
- Prometheus UI → *Status → Targets* shows the scrape error.
- `docker compose ps` — is the container running and healthy?
- `docker compose logs <service>`.

**Fix:** `docker compose up -d <service>`. For your own apps, check that `/metrics` is reachable from the `monitoring` network.

### PrometheusConfigReloadFailed

**Meaning:** A configuration reload was rejected. Prometheus keeps running with the previous configuration, so your change is **not** active.

**Investigate:** `docker compose logs prometheus | grep -i error`, or run `./scripts/validate.sh`.

**Fix:** Correct the configuration and run `./scripts/reload.sh` (it validates before reloading).

### PrometheusRuleEvaluationFailures

**Meaning:** Rules are failing to evaluate, so alerts that depend on them cannot fire.

**Investigate:** Prometheus UI → *Status → Rule health* shows the failing rule and its error (commonly a many-to-many matching error after adding new targets).

**Fix:** Correct the expression, add a test case to `prometheus/tests/alerts_test.yml`, and reload.

### PrometheusAlertmanagerUnreachable

**Meaning:** Prometheus has no Alertmanager to send alerts to. **No notifications are being delivered.**

**Investigate:** `docker compose ps alertmanager` and `docker compose logs alertmanager`.

**Fix:** `docker compose up -d alertmanager`.

### AlertmanagerConfigReloadFailed

**Meaning:** Alertmanager rejected a new configuration and is still running the previous one.

**Investigate:** `docker compose exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml`.

**Fix:** Correct the file and run `./scripts/reload.sh`.

### AlertmanagerNotificationsFailing

**Meaning:** Alertmanager cannot deliver notifications through an integration (Slack, email, webhook).

**Investigate:** `docker compose logs alertmanager | grep -i -E 'notify|error'` — common causes are a revoked Slack webhook, wrong SMTP credentials, or a secret file that the `nobody` user cannot read.

**Fix:** Update the secret in `alertmanager/secrets/` and run `./scripts/reload.sh`.
