# Alertmanager secrets

Files in this directory are mounted read-only at `/etc/alertmanager/secrets/`
and are **gitignored** (only this README and `.gitkeep` are tracked).

Alertmanager does not expand environment variables in its config, so secrets
are passed as files and referenced with the `*_file` options:

| File                | Used by                                   |
|---------------------|-------------------------------------------|
| `slack-webhook-url` | `slack_configs[].api_url_file`            |
| `smtp-password`     | `global.smtp_auth_password_file`          |
| `watchdog-url`      | `webhook_configs[].url_file` (heartbeat)  |

Example:

```bash
printf '%s' 'https://hooks.slack.com/services/XXX/YYY/ZZZ' > alertmanager/secrets/slack-webhook-url
./scripts/reload.sh
```

Then uncomment the matching `slack_configs` block in `alertmanager/alertmanager.yml`.

> The Alertmanager container runs as `nobody`, so the file must be readable by
> that user (the default `644` works; `600` owned by your user does not).
