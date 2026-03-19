# OpenCode Sidecar

This folder contains a minimal OpenCode sidecar setup for bounded read-only analysis.

## Start the sidecar

```bash
./start-opencode-sidecar.sh
```

Defaults:

- host: `127.0.0.1`
- port: `4096`

Override with:

```bash
OPENCODE_SIDECAR_PORT=4097 ./start-opencode-sidecar.sh
```

## Run a bounded task

```bash
./opencode-sidecar-run.sh /path/to/repo "Search for auth config loading and summarize the entrypoints."
```

The runner:

- talks to the headless OpenCode server over HTTP
- creates or reuses one session per target directory
- forces a read-only prompt shape
- prints only assistant text

Session state is stored in `./state/` by default.
# opencode-sidecar
