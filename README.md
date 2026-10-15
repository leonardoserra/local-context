# local-context

A Claude Code plugin that gives each feature its own working memory in
`.local_context/<feature>/`, so a later session can pick up exactly where the last one stopped.

| File | Holds |
|---|---|
| `CURRENT.md` | what is true **now**: state, decisions, open questions, and a § RESUME HERE section |
| `IMPLEMENTATION_PLAN.md` | the ordered work: numbered tasks with anchors and a **Done when** line, verification commands, a "Do NOT do (YAGNI)" table |
| `ARCHIVE.md` | dated history, newest first, append-only |

`.local_context/` is git-ignored automatically and never committed.

## Skills

All skills are user-invoked only (Claude never triggers them on its own).

| Command | What it does |
|---|---|
| `/local-context:new <description>` | Creates `.local_context/<feature>/` with the three files filled in from your description |
| `/local-context:continue [feature \| free text]` | Resumes a feature: reads its state, checks it against `git log`, agrees session rules, then works the plan task by task, keeping the files up to date |
| `/local-context:start <description>` | `new` followed by `continue`, in one step |
| `/local-context:tidy [feature]` | Audits and cleans a feature folder: moves history from CURRENT into ARCHIVE word for word (checked by a script), and makes the plan match git |

Examples:

```
/local-context:new the new task is called ruby rails upgrade it is about upgrading to Rails 8
/local-context:continue ruby_rails_upgrade. Mandatory skills: caveman for exploration, ponytail for code.
/local-context:tidy ruby_rails_upgrade
```

`continue` offers the optional caveman and ponytail
skills if you have them installed; it works fine without them. If a project's `CLAUDE.md` defines its own
`.local_context/` rules, those take precedence.

## Install

Requires Claude Code with plugin support. `tidy` needs `python3`.

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

## Layout

```
.claude-plugin/
  plugin.json          # plugin manifest
  marketplace.json     # makes this repo its own marketplace
skills/
  new/SKILL.md
  continue/SKILL.md
  start/SKILL.md
  tidy/SKILL.md
  tidy/scripts/lc_tools.py   # verifiable snapshot / prepend / heading checks
```

## License

MIT
