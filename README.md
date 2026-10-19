# local-context

A Claude Code plugin (and set of [Agent Skills](https://agentskills.io) for any agent) that gives each feature its own working memory in
`.local_context/<feature>/`, so a later session can pick up exactly where the last one stopped.

| File | Holds |
|---|---|
| `CURRENT.md` | what is true **now**: state, decisions, open questions, and a § RESUME HERE section |
| `IMPLEMENTATION_PLAN.md` | the ordered work: numbered tasks with anchors and a **Done when** line, verification commands, a "Do NOT do (YAGNI)" table |
| `ARCHIVE.md` | dated history, newest first, append-only |

`.local_context/` is git-ignored automatically and never committed.

## Skills

All skills are user-invoked only (the agent never triggers them on its own).
Every skill name starts with `local-context-`, so it stays unique in agents that have no plugin namespace.

| Agent | How to call a skill |
|---|---|
| Claude Code (plugin) | `/local-context:local-context-new …` |
| Codex | `$local-context-new …` |
| Others (OpenCode, Hermes, OpenClaw, …) | by name: `local-context-new …`, or the agent's own skill syntax |

| Skill | What it does |
|---|---|
| `local-context-new <description>` | Creates `.local_context/<feature>/` with the three files filled in from your description |
| `local-context-continue [feature \| free text]` | Resumes a feature: reads its state, checks it against `git log`, agrees session rules, then works the plan task by task, keeping the files up to date |
| `local-context-start <description>` | `local-context-new` followed by `local-context-continue`, in one step |
| `local-context-tidy [feature]` | Audits and cleans a feature folder: moves history from CURRENT into ARCHIVE word for word (checked by a script), and makes the plan match git |
| `local-context-business-questions [feature \| free text]` | Checks where a feature really stands (docs vs git, code and ticket), builds with you the list of decisions only the business can take, posts it bilingual on the ticket, and records answers and positions in `.local_context` |

Examples (Claude Code):

```
/local-context:local-context-new the new task is called ruby rails upgrade it is about upgrading to Rails 8
/local-context:local-context-continue ruby_rails_upgrade. Mandatory skills: caveman for exploration, ponytail for code.
/local-context:local-context-tidy ruby_rails_upgrade
```

`local-context-continue` offers the optional caveman and ponytail
skills if you have them installed; it works fine without them. If a project's `CLAUDE.md` defines its own
`.local_context/` rules, those take precedence.

## Install

`local-context-tidy` needs `python3`.

### Claude Code

From GitHub:

```bash
claude plugin marketplace add leonardoserra/local-context
claude plugin install local-context@local-context --scope user
```

Or inside Claude Code:

```
/plugin marketplace add leonardoserra/local-context
/plugin install local-context@local-context
```

From a local clone (for development):

```bash
git clone https://github.com/leonardoserra/local-context.git
claude plugin marketplace add ./local-context
claude plugin install local-context@local-context --scope user
```

Restart Claude Code (or run `/reload-plugins`), then type `/local-context:` to see the skills.

### Update / uninstall

```bash
claude plugin marketplace update local-context
claude plugin update local-context@local-context
claude plugin uninstall local-context@local-context
```

### Codex, OpenCode, Hermes, OpenClaw and other agents

With the [`skills` CLI](https://github.com/vercel-labs/skills), which copies the skills into each agent's skills folder:

```bash
npx skills add leonardoserra/local-context -g -a codex          # or -a opencode, -a hermes-agent, -a openclaw
npx skills update                                               # later, to update
```

Leave out `-g` to install into the current project only. Install all five skills together:
`local-context-start`, `local-context-continue` and `local-context-business-questions` read their sibling skills'
files. Each skill has an `agents/openai.yaml` that keeps Codex from invoking it on its own.

### Upgrading from 0.2.x

The skills were renamed in 0.3.0: `/local-context:new` is now `/local-context:local-context-new`, and so on.
`.local_context/` folders need no change.

## Layout

```
.claude-plugin/
  plugin.json          # plugin manifest
  marketplace.json     # makes this repo its own marketplace
skills/
  local-context-<name>/SKILL.md            # new, continue, start, tidy, business-questions
  local-context-<name>/agents/openai.yaml  # Codex: no implicit invocation
  local-context-tidy/scripts/lc_tools.py   # verifiable snapshot / prepend / heading checks
```

## License

MIT
