# local-context

A Claude Code plugin (and set of [Agent Skills](https://agentskills.io) for any agent) that gives each feature its own working memory in
`.local_context/<feature>/`, so a later session can pick up exactly where the last one stopped.

| File | Holds |
|---|---|
| `CURRENT.md` | what is true **now**: state, decisions, open questions, and a § RESUME HERE section |
| `IMPLEMENTATION_PLAN.md` | the ordered work: numbered tasks with anchors and a **Done when** line, verification commands, a "Do NOT do (YAGNI)" table |
| `ARCHIVE.md` | dated history, newest first, append-only |
| `BUSINESS.md` *(optional)* | the feature's business rules only (scope, who gets/sees what, data, timing), whoever decided them; not created for pure technical work such as a bug fix |
| `CODE_REVIEW_MAPPING.md` *(optional)* | a reading map of the feature's changed files, grouped by functionality with backend and frontend side by side; derived from the branches and regenerated, never edited by hand |

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
| `local-context-tidy [feature]` | Audits and cleans a feature folder: moves history from CURRENT into ARCHIVE word for word (checked with `cmp`), and makes the plan match git |
| `local-context-business-questions [feature \| free text]` | Checks where a feature really stands (docs vs git, code and ticket), builds with you the list of decisions only the business can take (skipping anything the code or project docs already answer), posts it bilingual on the ticket, and records the answers in `BUSINESS.md` |
| `local-context-code-review-mapping [feature \| free text]` | Writes `CODE_REVIEW_MAPPING.md`: every file the feature's branches change (across a container repo and its submodules), grouped by functionality with backend and frontend together and ordered for reading, so a merge request too large to review file by file can be read one chunk at a time. Checks that every changed file is mapped |
| `local-context-code-review-mapping-navigator <feature> [group] [ide]` (alias `local-context-crn`) | Reviews `CODE_REVIEW_MAPPING.md` one group at a time, like a small merge request: opens the IDE you name (it finds its launcher) on a throwaway worktree per repo where only that group's changes show. Answers questions, makes edits and handles `<crn> … </crn>` comments you leave in the code, then on your OK applies the edits (uncommitted) to the feature branch checkout and opens the next group |

Examples (Claude Code):

```
/local-context:local-context-new the new task is called ruby rails upgrade it is about upgrading to Rails 8
/local-context:local-context-continue ruby_rails_upgrade. Mandatory skills: caveman for exploration, ponytail for code.
/local-context:local-context-tidy ruby_rails_upgrade
/local-context:local-context-code-review-mapping ruby_rails_upgrade
/local-context:local-context-crn ruby_rails_upgrade
```

`local-context-continue` offers the optional caveman and ponytail
skills if you have them installed; it works fine without them. If a project's `CLAUDE.md` defines its own
`.local_context/` rules, those take precedence.

## Reviewing a large merge request

Two skills turn a merge request too big to read file by file into small reviews, one functionality at a time.
They work across a container repo and its submodules, e.g. a backend and a frontend changed together.

### 1. Map the changes

```
/local-context:local-context-code-review-mapping <feature>
```

Writes `.local_context/<feature>/CODE_REVIEW_MAPPING.md`: every file the feature's branches change, grouped by the
capability it implements (backend and frontend side by side, specs with the code they test), in reading order,
foundations first. Each group has a `Read for:` hint and one command per side that opens all its files. A coverage
check proves no changed file is left out. Run it again whenever the branches move; never edit the map by hand.

### 2. Review it group by group

```
/local-context:local-context-crn <feature>            # every group, starting from 1
/local-context:local-context-crn <feature> 4          # only group 4
/local-context:local-context-crn <feature> 2 zed      # name the IDE up front
```

`local-context-crn` is the short alias of `local-context-code-review-mapping-navigator`.

1. It asks once which IDE you use and finds its command-line launcher (on `PATH`, else from the web, else it asks
   you for the path). Terminal editors such as Neovim get a command to run yourself.
2. For each repo the group touches it prepares a review worktree under `~/.cache/local-context-crn/` and opens your
   IDE on it: two repos, two windows. Your own checkouts are not touched.
3. In the IDE's git view, the **staged changes** are exactly this group's part of the merge request. Read them like
   a small merge request.
4. While you read:
   - ask anything ("why is this query grouped before the join?"), or give a path;
   - ask for an edit, which is made in the review worktree;
   - or write comments for the agent in the code, in the file's comment syntax, save, and say "read the crn":

     ```ruby
     # <crn> use a better name for the const </crn>
     KEY_EXPRESSIONS = {
       'id_media' => Detection.ar[:id_media], # <crn> don't use Arel here </crn>
     ```

     Each `<crn>` is done or answered, then removed. Only comments you add during the review count.
5. Say OK: the review edits are applied to your checkout of the feature branch, uncommitted, and the next group
   opens. Nothing is ever committed or pushed for you.
6. After the last group it offers to remove the review worktrees.

## Install

No dependencies: the skills use only standard shell tools (`sed`, `grep`, `cmp`, `git`, …).

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

Leave out `-g` to install into the current project only. Install all the skills together:
`local-context-start` and `local-context-crn` read their sibling skills' files. Each skill has an `agents/openai.yaml` that keeps Codex
from invoking it on its own.

### Upgrading from 0.2.x

The skills were renamed in 0.3.0: `/local-context:new` is now `/local-context:local-context-new`, and so on.
`.local_context/` folders need no change.

## Layout

```
.claude-plugin/
  plugin.json          # plugin manifest
  marketplace.json     # makes this repo its own marketplace
skills/
  local-context-<name>/SKILL.md            # new, continue, start, tidy, business-questions, code-review-mapping,
                                           # code-review-mapping-navigator, crn (alias)
  local-context-code-review-mapping-navigator/scripts/crn.sh  # review worktrees: prepare, stage, crn, apply, cleanup
  local-context-<name>/agents/openai.yaml  # Codex: no implicit invocation
```

## License

MIT
