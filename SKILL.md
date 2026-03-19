---
name: opencode-sidecar
description: Use when you want to offload bounded, read-only analysis to a persistent OpenCode sidecar to save primary-agent context and coordination overhead. Best for repo search summaries, log triage, docs/API lookup, and implementation mapping. Do not use for file edits, destructive commands, or tightly coupled coding loops.
---

# OpenCode Sidecar

Use this sidecar for bounded read-only analysis that is cheaper to isolate than to carry in the main agent context.

## When to use

- Search a repo and return a short implementation map
- Triage logs and identify the first concrete failing step
- Compare config or API shapes and summarize mismatches
- Read a few files and return findings with paths and line references
- Summarize external docs or recent news into a short result

## When not to use

- Editing files
- Running destructive commands
- Large open-ended coding tasks
- Multi-step debugging loops that need deep shared context with the main agent
- Tasks where the main agent already has all relevant context loaded

## Workflow

1. Start the sidecar server:

```bash
./start-opencode-sidecar.sh
```

Defaults:

- host: `127.0.0.1`
- port: `4096`

2. Send one bounded task:

```bash
./opencode-sidecar-run.sh /path/to/repo "Search for auth config loading and summarize the entrypoints."
```

3. Consume only the returned summary. Do not pull raw intermediate context back into the main agent unless necessary.

## Output contract

The runner already constrains the prompt. Expect output to be:

- read-only
- at most 8 concise bullets
- explicit about uncertainty
- path-oriented, with line numbers when possible

Design your task prompt so the answer can stay short.

Good prompt shapes:

- `Find the entrypoints for X and summarize them in 5 bullets.`
- `Read these logs and identify the first failing step.`
- `Compare these two payload shapes and list material mismatches only.`

Bad prompt shapes:

- `Fix this bug.`
- `Refactor this subsystem.`
- `Investigate everything related to auth.`

## Session behavior

- The runner uses one reusable OpenCode session per target directory.
- Session IDs are cached in `./state/`.
- If a cached session is stale, the runner recreates it automatically.
- `./state/` is only local sidecar session state. It is not repo data.

## Files

- `./start-opencode-sidecar.sh` starts the headless OpenCode server
- `./opencode-sidecar-run.sh` sends bounded read-only tasks to the server

## Quality rules

- Keep delegation narrow and concrete.
- Prefer findings, summaries, and mappings over prose.
- Ask for exact paths and line numbers when useful.
- Keep final integration, decisions, and edits in the primary agent.
