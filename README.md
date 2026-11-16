# local-context

A Claude Code plugin (and set of [Agent Skills](https://agentskills.io) for any agent) that gives each feature its own working memory in
`.local_context/<feature>/`, so a later session can pick up exactly where the last one stopped.

| Folder | Holds |
|---|---|
| `_current/` | what is true **now**: state, goal, scope, a § RESUME HERE section; one file per decision (`_decisions/`) and per open question (`_questions/`) |
| `_implementation_plan/` | the ordered work: a Tasks table (status lives there), one file per task with anchors and a **Done when** line, verification commands, a "Do NOT do (YAGNI)" table |
| `_archive/` | dated history, one entry per file (`YYYY_MM_DD/N.md`), append-only |
| `_business/` *(optional)* | the feature's business rules only (scope, who gets/sees what, data, timing), one file per theme, whoever decided them; not created for pure technical work such as a bug fix |
| `_crm/` *(optional)* | the code review mapping: a reading map of the feature's changed files, one file per functionality group with each repo's files side by side; derived from the branches and regenerated, never edited by hand |

`.local_context/` is git-ignored automatically and never committed.

Folders are flat, one per feature. Ask for a feature inside another one (e.g. a feature split into subtasks) and it is
nested: the parent's `_current/` holds what the subtasks share. A feature spanning several repos gets a folder of the
same name in each repo, each scoped to its repo and pointing at the others by `path:line` instead of copying them.
Feature names never start with `_`.

### ICM layout

The folders follow ICM, Interpretable Context Methodology ([paper](https://arxiv.org/abs/2603.16021), reference
implementation [RinDig/Interpretable-Context-Methodology](https://github.com/RinDig/Interpretable-Context-Methodology)).
local-context takes the idea and implements it in its own workflow; it is not a copy of that repo. Each part made of
several pieces is a folder starting with `_`, one file per piece, and a short `STATE.md` index in each. An agent reads
down the layers (skill, `ICM.md`, the indexes, then only the piece files it needs) and stops when it has what it needs.
`STATE.md` holds every status (task, question, review mark); files are never renamed, order lives in the index.

Measured cost against 2.0.0 (instructions plus the record read):

- Small features (under about 10–15 tasks or 15 decisions): about even with 2.0.0, and 4–20% more than legacy mode.
- Large features: 14–38% fewer tokens on `continue`, `business-questions` and `tidy`.
- The navigator: about 4% fewer tokens on a small feature, about 20% fewer on a large one.
- Migrating a folder is a one-time cost.

```
.local_context/<feature>/
  _current/STATE.md                state as of a date, goal, scope, where it stands, RESUME HERE
  _current/_decisions/STATE.md     | # | File | Decision | Date | Who |
  _current/_decisions/01_<slug>.md
  _current/_questions/STATE.md     | # | File | Question | Status |   open | answered <date> → decision
  _current/_questions/01_<slug>.md
  _implementation_plan/STATE.md    START HERE, | # | File | Task | Depends on | Status |, Blocked, Verification, YAGNI
  _implementation_plan/01_<slug>.md
  _archive/STATE.md                | Entry | Commits | Title |   oldest first; read the tail
  _archive/2026_11_16/1.md
  _business/STATE.md               | File | Theme | Rules | Last changed | Summary |
  _business/<theme>.md
  _crm/STATE.md                    map header, | # | File | Group | Status |
  _crm/01_<slug>.md
```

The contract lives in `skills/local-context-new/`: [`ICM.md`](skills/local-context-new/ICM.md) (layers, paths, rules),
`ICM_OPS.md` (operations), `ICM_FORMATS.md` (every format), both read one section at a time. Migrating a flat folder
lives in its own skill, `local-context-icm-migrate`, read only when a folder is migrated.

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
| `local-context-new <description>` | Creates `.local_context/<feature>/` in the ICM layout, filled in from your description |
| `local-context-continue [feature \| free text]` | Resumes a feature: reads its state, checks it against `git log`, agrees session rules, then works the plan task by task, keeping the files up to date |
| `local-context-start <description>` | `local-context-new` followed by `local-context-continue`, in one step |
| `local-context-tidy [feature]` | Audits and cleans a feature folder: moves history from the current state into the archive word for word (checked with `cmp`), makes the plan match git, and checks every `STATE.md` index against its folder |
| `local-context-business-questions [feature \| free text]` | Checks where a feature really stands (docs vs git, code and ticket), builds with you the list of decisions only the business can take (skipping anything the code or project docs already answer), posts it bilingual on the ticket, and records the answers in `_business/` |
| `local-context-code-review-mapping [feature \| free text]` | Writes `_crm/`: every file the feature's branches change (across a container repo and its submodules), grouped by functionality with each repo's files together and ordered for reading, so a merge request too large to review file by file can be read one chunk at a time. Checks that every changed file is mapped |
| `local-context-icm-migrate [feature]` | Migrates a flat pre-3.0.0 feature folder to the ICM layout, with every folder the feature spans (parent, sub-features, same-name folders in other repos), without asking anything: every piece cut with `sed` and proved with `cmp`, every unusual shape decided by fixed rules, pointers rewritten, one report at the end. The other skills run it when you pick **Migrate** in their layout check |
| `local-context-code-review-navigator <feature> [group] [ide]` (alias `local-context-crn`) | Reviews `_crm/` one group at a time, like a small merge request: explains per repo what the group's changes do (files and `path:line` included) and flags wrong patterns or business-rule mismatches, adds `<xplain> … </xplain>` reading notes in the code, then opens the IDE you name (it finds its launcher) in one window on a throwaway worktree per repo where only that group's changes show, printing that command for you to copy. Answers questions, makes edits and handles `<crn> … </crn>` (code-review-note) comments you leave in the code, then on your OK applies the edits (uncommitted) to the feature branch checkout and opens the next group |

Examples (Claude Code):

```
/local-context:local-context-new the new task is called axum migration, it moves the HTTP server from actix-web to axum
/local-context:local-context-continue axum_migration. Mandatory skills: caveman for exploration, ponytail for code.
/local-context:local-context-tidy axum_migration
/local-context:local-context-code-review-mapping axum_migration
/local-context:local-context-crn axum_migration
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

Writes `.local_context/<feature>/_crm/`: every file the feature's branches change, grouped by the
capability it implements (each repo's files side by side under the repo name, specs with the code they test), in
reading order, foundations first. A group with many files (around 10 in one repo) is split into subgroups when its
files hold ideas that read separately (e.g. `Report templates / CSV export`); one idea stays one group. Lockfiles,
generated files and config are reviewed too, in a last `Other / mechanical` group, or several by domain (e.g.
`Other / mechanical — dependencies`) when one is too big to follow mixed. Each group has a `Read for:` hint and one command per repo that opens all its files. A coverage check proves no
changed file is left out. Run it again whenever the branches move; never edit the map by hand.

### 2. Review it group by group

```
/local-context:local-context-crn <feature>            # every group not yet reviewed, from the first one
/local-context:local-context-crn <feature> 4          # only group 4
/local-context:local-context-crn <feature> 2 zed      # name the IDE up front
```

`local-context-crn` is the short alias of `local-context-code-review-navigator` (crn = code-review-navigator).
The `<crn>` tag you write in the code (step 5 below) is a different thing: crn = code-review-note.

1. It asks once which IDE you use and finds its command-line launcher (on `PATH`, else from the web, else it asks
   you for the path). Terminal editors such as Neovim get a command to run yourself.
2. For each repo the group touches it prepares a review worktree under `~/.cache/local-context-crn/`, and opens all of
   them in one IDE window, e.g. `code "<worktree of repo 1>" "<worktree of repo 2>"`. It prints that command below the
   group's explanation, so you can run it again yourself. Your own checkouts are not touched.
3. Below the group's file lists it explains, per repo, what the group's changes do as the code runs (behaviour, flow,
   business rules), with the files involved and key spots as `<repo>/path:line`, as the map writes them. It writes
   this from the diff and checks it against the feature's business rules and plan, flagging wrong patterns,
   broken or missed rules and surprising behaviour. A mechanical group gets one line per change: what changed and why.
   You review from the explanation and open the code only to verify. In the worktrees, an `<xplain> … </xplain>`
   comment sits above each block of functions, classes or constants that share a domain concept, saying what it is
   for. It takes one line, or several when the code needs more, in the file's comment syntax:

   ```ruby
   # <xplain> refund rules: who gets money back,
   # and how much once the order has shipped </xplain>
   def refundable?(order)
   ```

   These notes exist only in the review worktree: they are never applied to your checkout or committed, and they go
   away with the worktree. The lines from one starting with `<xplain>` to the one holding `</xplain>` are dropped
   when the edits are applied, so an `<xplain>` you write yourself there is dropped too.
4. In the IDE's git view, the **staged changes** are exactly this group's part of the merge request. Read them like
   a small merge request.
5. While you read:
   - ask anything ("why is this query grouped before the join?"), or give a path;
   - ask for an edit, which is made in the review worktree;
   - or write `<crn>` (code-review-note) comments for the agent in the code, in the file's comment syntax, save, and
     say "read the crn":

     ```rust
     // <crn> rename to OrderStatus, "State" clashes with axum::extract::State </crn>
     pub enum State {
         Pending,
         Shipped { tracking_code: String },
     }
     ```

     ```rust
     async fn get_order(Path(order_id): Path<u64>, State(pool): State<PgPool>) -> Json<Order> {
         let order = fetch_order(&pool, order_id).await.unwrap(); // <crn> return 404 instead of panicking </crn>
         Json(order)
     }
     ```

     ```rust
     // <crn> why a Mutex and not an RwLock? reads far outnumber writes here </crn>
     let price_cache = Arc::new(Mutex::new(HashMap::<ProductId, Price>::new()));
     ```

     The first and second are instructions, so the agent makes the change; the third is a question, answered in
     chat with its `file:line`. Each `<crn>` is done or answered, then removed. Only comments you add during the
     review count.
6. Say OK: the review edits are applied to your checkout of the feature branch, uncommitted, and it asks whether to
   open the next group. Nothing is ever committed or pushed for you. The group's Status in `_crm/STATE.md` becomes
   `✅ reviewed`, so the next session (tomorrow, say) starts at the first group not yet reviewed. Regenerating
   the map clears the marks.
7. After each group it asks whether to remove the review worktrees (it names their paths), e.g. when you stop
   for the day; the next group recreates them. After the last group it asks again if they are still there.

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
the skills read `local-context-new/ICM*.md`, their layout checks run `local-context-icm-migrate`, and
`local-context-start` and `local-context-crn` read their sibling skills' files. Each skill has an `agents/openai.yaml` that keeps Codex
from invoking it on its own.

### Upgrading to 3.0.0

`.local_context/<feature>/` now uses the ICM layout (see above) instead of the flat `CURRENT.md`,
`IMPLEMENTATION_PLAN.md`, `ARCHIVE.md`, `BUSINESS.md` and `CRM.md`.

- Update **every** agent install of the plugin (Claude Code, Codex, …) before using it on a converted folder: an
  older install would write flat files next to the `_` folders. The skills spot such a mixed folder and offer to fold
  the flat files in.
- The first time a skill opens a flat folder, it asks one question: **Migrate (Recommended)** or **Keep old
  layout**. Keep writes a `.no_icm` file in the folder and the skills keep using the flat files there; delete
  `.no_icm` to be asked again. Dismissing the question keeps the flat files for that run only. Several folders
  (sub-features, other repos) are listed in the same question.
- Migrate runs `local-context-icm-migrate`, which asks nothing more: odd shapes (task ids like `P3b`, statuses in
  headings, session logs inside the plan, decision sections under other names) are decided by fixed rules and
  listed in its report.
- Migrating makes no backup: every piece is cut from the flat file with `sed` and proved with `cmp`; a failed
  proof aborts that folder and leaves it untouched. Pointers to the old files (`CURRENT.md`, …) are rewritten in
  the live files, sibling folders included. Archive entries are never edited: the archive index gets a legend
  mapping the old names to the new paths. An archive entry records the migration.
- If your project's `CLAUDE.md` names the flat files, the question and the report point it out; update those lines
  after migrating.

### Upgrading to 2.0.0

- The code review map is now `CRM.md` (it was `CODE_REVIEW_MAPPING.md`). Regenerate it with
  `local-context-code-review-mapping`, which also deletes the old file, or rename it.
- `local-context-code-review-mapping-navigator` is now `local-context-code-review-navigator`; the alias
  `local-context-crn` is unchanged.
- Review worktree reading notes are `<xplain> … </xplain>` comments (were `XPLAIN:` lines). In a review worktree left
  from 1.x, the old `XPLAIN:` lines now count as review edits: when asked about leftover edits, discard them, or
  delete those lines before applying.

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
                                           # code-review-navigator, crn (alias), icm-migrate
  local-context-new/ICM.md                 # the .local_context/<feature>/ contract: layers, paths, rules
  local-context-new/ICM_OPS.md             # operations, the layout check and the legacy layout, by section
  local-context-new/ICM_FORMATS.md         # every file and row format, read by section
  local-context-icm-migrate/STEPS.md       # migrating a flat pre-3.0.0 folder: per-file cuts and rules, read by section
  local-context-code-review-navigator/scripts/crn.sh  # review worktrees: prepare, stage, crn, apply, cleanup
  local-context-<name>/agents/openai.yaml  # Codex: no implicit invocation
```

## License

MIT
