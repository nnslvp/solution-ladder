# Solution Ladder

An architecture-refinement **skill** for AI coding agents. When you hit a task that
involves refactoring, configuration, or "how should this be wired" decisions, it stops
the agent from shipping the first thing that works and forces a structured climb:

- **Level 1 — Patch** — conditionals / flags that suppress the unwanted behavior.
- **Level 2 — Escape Hatch** — a proper opt-out API per consumer.
- **Level 3 — Right Default** — flip the model, make the behavior opt-in.
- **Lateral — Wildcard** — anything outside the ladder (move boundaries, fix the data model, reuse existing infra).

Each level is developed by a **separate blind subagent** that doesn't know the other
levels exist, then a **blind judge** ranks the unlabeled solutions by fit to *your*
codebase — flagging which are insufficient and which are overkill. No level is "always
right"; the consumer census decides.

The skill is a single, portable `SKILL.md` (plus its `agents/` mandate files) and works
in **Claude Code**, **Codex CLI**, and **OpenCode** — same content, three install paths.

---

## Repository layout

```
solution-ladder/
├── .claude-plugin/
│   ├── plugin.json          # Claude Code plugin manifest
│   └── marketplace.json     # this repo doubles as its own marketplace
├── skills/
│   └── solution-ladder/
│       ├── SKILL.md         # the skill
│       └── agents/          # mandate files for the explorer/judge subagents
├── install.sh               # symlinks the skill into Codex / OpenCode
└── README.md
```

---

## Install

### Claude Code (plugin marketplace — recommended)

The repository is its own single-plugin marketplace. Inside Claude Code:

```text
/plugin marketplace add nnslvp/solution-ladder
/plugin install solution-ladder@solution-ladder
```

Then start a new session (or run `/reload-plugins`). The skill is namespaced as
`solution-ladder` and triggers automatically on matching tasks; you can also invoke it
explicitly.

> Non-interactive equivalent:
> ```bash
> claude plugin marketplace add nnslvp/solution-ladder
> claude plugin install solution-ladder@solution-ladder
> ```

### Codex CLI

Codex reads skills from `~/.codex/skills/<name>/`. Clone once, then symlink (so
`git pull` keeps it current):

```bash
git clone https://github.com/nnslvp/solution-ladder.git
cd solution-ladder
./install.sh                 # detects Codex/OpenCode and links the skill
```

Or do it manually:

```bash
ln -sfn "$PWD/skills/solution-ladder" ~/.codex/skills/solution-ladder
```

Start a new Codex session and confirm with `/skills`. Invoke explicitly with
`$solution-ladder ...`, or let Codex pick it up implicitly from the description.

### OpenCode

OpenCode reads skills from `~/.config/opencode/skills/<name>/`. The same `install.sh`
covers it:

```bash
git clone https://github.com/nnslvp/solution-ladder.git
cd solution-ladder
./install.sh
```

Or manually:

```bash
ln -sfn "$PWD/skills/solution-ladder" ~/.config/opencode/skills/solution-ladder
```

> OpenCode also reads `~/.claude/skills/`, so a Claude Code personal-skill install is
> picked up automatically too.

### Any other agent (manual)

The skill is just a folder. Drop or symlink `skills/solution-ladder/` into whatever
skills directory your agent scans (e.g. the vendor-neutral `~/.agents/skills/`).

---

## `install.sh` options

| Invocation | Effect |
|---|---|
| `./install.sh` | Symlink the skill into Codex and OpenCode if present. |
| `INSTALL_CLAUDE=1 ./install.sh` | Also symlink into `~/.claude/skills/` (Claude Code personal scope). |
| `COPY=1 ./install.sh` | Copy instead of symlink (no live updates on `git pull`). |

The script never overwrites a real (non-symlink) directory — it skips and tells you.

---

## Updating

- **Symlink installs (Codex / OpenCode):** `git pull` in your clone — done.
- **Claude Code plugin:** `/plugin marketplace update solution-ladder`.

---

## Uninstall

```bash
rm ~/.codex/skills/solution-ladder
rm ~/.config/opencode/skills/solution-ladder
```

For Claude Code: `/plugin uninstall solution-ladder@solution-ladder`.

---

## Compatibility notes

- The `SKILL.md` frontmatter uses only `name` and `description`, which is valid across
  Claude Code, Codex, and OpenCode (the strictest of the three).
- The skill spawns subagents and reads its `agents/*.md` mandate files by relative path,
  so the `agents/` folder must stay next to `SKILL.md` — installing the whole folder (as
  above) keeps that intact.
- If a harness has no subagent capability, the skill falls back to running the same
  protocol sequentially (see the "Fallback" section in `SKILL.md`).

## License

MIT — see [LICENSE](LICENSE).
