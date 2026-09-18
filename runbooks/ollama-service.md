# Ollama Service Runbook

This project manages Ollama as a **systemd user service**.

Service file location (managed by stow):
- `~/.config/systemd/user/ollama.service`

## Health checks

Check service status:

```bash
systemctl --user status ollama.service
```

Follow service logs:

```bash
journalctl --user -u ollama.service -f
```

Check API health:

```bash
curl http://localhost:11434/api/tags
```

Expected: JSON response with available local models.

## Lifecycle commands

Stop service:

```bash
systemctl --user stop ollama.service
```

Start service:

```bash
systemctl --user start ollama.service
```

Restart service:

```bash
systemctl --user restart ollama.service
```

Enable on login:

```bash
systemctl --user enable ollama.service
```

## After model installation or changes

If you install/update models (for example `ollama pull <model>`), restart the service to ensure a clean runtime state:

```bash
systemctl --user restart ollama.service
```

Then re-check:

```bash
ollama ls
curl http://localhost:11434/api/tags
```
