# Contributing

Thanks for taking the time to improve this project! Bug reports, new dashboards,
alerts and documentation fixes are all welcome.

## Development workflow

1. Fork the repository and create a branch: `git checkout -b feat/my-change`.
2. Start the stack: `./scripts/start.sh` (or `make up`).
3. Make your change.
4. Validate everything — this is exactly what CI runs:

   ```bash
   ./scripts/validate.sh     # compose, promtool (config + unit tests), amtool, dashboards
   ./scripts/smoke-test.sh   # end-to-end checks against the running stack
   make lint                 # ShellCheck + yamllint (in containers)
   ```

5. Open a pull request and fill in the checklist.

The only local requirement is Docker — every tool runs in a container pinned to
the same version as `docker-compose.yml`.

## Adding or changing an alert

- Put it in the matching file in `prometheus/rules/`.
- Give warning and critical variants **the same alert name** with different
  `severity` labels, so Alertmanager inhibits the warning when critical fires.
- Add `summary`, `description` and `runbook_url` annotations.
- Add a section to [`docs/runbooks.md`](docs/runbooks.md) (the anchor is the alert
  name in lower case).
- Add a test case to [`prometheus/tests/alerts_test.yml`](prometheus/tests/alerts_test.yml).

## Changing a dashboard

Dashboards are provisioned read-only. To edit one:

1. In Grafana, open the dashboard → **Edit** → make your changes.
2. **Export → Export as JSON** (keep "Export for sharing externally" off).
3. Replace the file in `grafana/dashboards/`, keeping the same `uid`.
4. Use the `${datasource}` variable instead of a hard-coded datasource.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):
`feat: add Redis exporter`, `fix: ContainerDown label`, `docs: runbook for X`.
