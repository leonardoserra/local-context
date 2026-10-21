---
name: local-context-business-questions
description: For one feature in .local_context/<feature_name>/, establish where it really stands (docs checked against git, code and the ticket), then build — iterating with the user — the list of open questions only the business can answer, hand it over bilingual on the feature's ticket, and record the answers as business rules in .local_context/<feature_name>/BUSINESS.md. Asks only what the code and the project docs cannot answer, always with a recommendation. Run by the user as local-context-business-questions [feature_name | free text], typically before a call with the boss or product owner, or when a feature is paused on a business decision.
argument-hint: "[feature_name] or free text naming the feature plus context (who decides, ticket key, language)"
disable-model-invocation: true
---

# local-context-business-questions

Turns a feature that is stuck, paused or about to be re-scoped into **a short list of decisions the
business has to take**, phrased so the decision-maker can answer each one without reading code.
Typical calls:

```
local-context-business-questions <feature_name>
local-context-business-questions <feature_name> — boss call on Thursday, ticket <TICKET-KEY>
```

`<feature_name>` and `<TICKET-KEY>` are placeholders. The folder and ticket come only from the
user's arguments (step 1); never look for anything named in these examples.

The work is a loop with the user, not a one-shot report: the first draft is always wrong in some
places — the user answers some questions themselves, rejects others, fixes the vocabulary, or
realises a question belongs to another feature. The skill's value is running that loop
efficiently and leaving a record nobody has to reconstruct later.

Outputs, in order:

1. A state report in chat: built / working / missing, each claim with its evidence.
2. The question list, iterated with the user until approved.
3. The same list translated into the business language, approved.
4. One ticket comment per affected ticket: English, then `---`, then the translation.
5. `.local_context` updated: business rules in `BUSINESS.md`, technical positions and open items
   (pointing at the comment id) in CURRENT, drift fixed, ARCHIVE.

If the project's `CLAUDE.md` / `CLAUDE.local.md` defines rules (who runs tests, approval before
changes, naming, caveman/ponytail usage, how to write `.local_context`), **those win** over this file.

## 1 — Pick the feature

Same as `local-context-continue`: exact name or path → use it; a phrase → infer, then confirm with
`AskUserQuestion` or a plain question (inferred folder first, `(Recommended)`); nothing → list folders by recency and ask.
A feature may exist at several levels (container repo + each subrepo): find all of them
(`ls */.local_context/<feature>` and the root one).

## 2 — Read narrowly

Everything read is re-sent on every later turn.

1. Each level's `CURRENT.md` for this feature (cross-repo one first). Over ~600 lines: head, status
   banner, open items, any "undecided / blocked / paused" section.
2. `IMPLEMENTATION_PLAN.md`: `grep -n '^#'`, then § Blocked / open questions only.
   `BUSINESS.md` in full, if it exists: these rules are settled and are never asked again.
3. The ticket: key from CURRENT/plan. Description **and comments** (comments hold the latest status;
   with an MCP ticket tool, comments are often a separate call from the issue). Linked tickets: summary only.
4. Cross-feature files CURRENT points to (an open-issues list, a sibling feature): only the sections
   it names. Do not sweep sibling features "just in case".
5. The project's own docs that state business rules: `BUSINESS.md`, `DOCUMENTATION.md`,
   `README.md`, `CLAUDE.md`, `AGENTS.md` at the root, and similar (`docs/`, `*.md` naming the
   domain). `grep -il` for the feature's business names first, then read only the matching sections.
   Same for the other `.local_context/*/BUSINESS.md`: a rule another feature already settled holds here too.
6. `ARCHIVE.md` only to answer a "why" — in particular "was this tried before and dropped?" when the
   user proposes a design (step 7).

## 3 — Check the docs against reality

The record drifts. Before asking anyone to decide anything, prove what is true **today**:

- Branch heads: `git ls-remote origin <branch>` vs the SHA the docs cite; ahead/behind the default
  branch (`git rev-list --left-right --count <default>...<branch>`). Do this in **every** repo of the
  feature, frontend included.
- What users get today on the default branch — the behaviour the feature would change (read the
  `file:line`). This is what "Today:" means in the questions.
- Switches that keep it dark: feature flags, commented-out crons, env gates.
- Whether the work it depends on exists yet (`git log --since=<pause date> -- <paths>`).
- Statements in the docs that are no longer true (a DB column wiped by a nightly rebuild, a
  framework limitation removed by an upgrade, a renamed branch).

List every drift with its evidence and ask **fix now / later / skip** — never fix silently, never
pick one of two disagreeing files silently.

## 4 — Report the state

A few lines, plain language, evidence attached (`file:line`, command, ticket comment id):
what is built and where, what is verified (specs, CI, manual), what is missing, what it waits on.
End with the one-line answer to "does it work?".

## 5 — Sort every open point

Collect candidates from the docs' open items, the ticket, and anything step 3 surfaced.

**Answer from the record first.** Before a candidate becomes a question — to the user or to the
business — look for its answer in the code (today's behaviour), the feature's `BUSINESS.md`, and the
project docs from step 2. Already answered → it is not asked: tell the user in one line with the
source (`file:line` or `doc § section`); a business answer found outside `BUSINESS.md` is recorded
there (step 10). Only what nothing answers stays a candidate.

Put each remaining candidate in exactly one bucket:

| Bucket | Test | Goes to |
|---|---|---|
| **Business** | Only the business can decide: scope, who gets/sees/edits what, data leaving the company, contract or privacy, what changes for users, release timing | the question list |
| **Developer's call** | Technical, invisible to users, or already settled by "keep current behaviour" | ask the user directly, with your recommended answer; record as a technical position in CURRENT |
| **Another feature** | The decision is owned by a different feature | that feature's `.local_context` + its ticket (step 7) |

Default when unsure whether something needs the business: **"where possible, no change to behaviour
or UX"**. Things that stay as today go in a closing "kept as today unless you object" list, not as
questions — the decision-maker can still object, but is not asked to think about them.

## 6 — Draft the questions

- **Group by theme**, only themes that apply: Scope · Where it lives / ownership · Who (recipients,
  permissions) · Data and security · Timing and re-runs · Release. Number them `A1, A2, B1…` so
  answers can be quoted back.
- **One decision per question**, answerable with yes/no or a pick. If it needs two answers, split it.
- **State the current answer** in italics after each: *Today: …* (default branch) and/or *Built: …*
  (the parked branch). The decision-maker confirms or overrides instead of designing from scratch.
- **Conditional questions** say so: *(Only if A1 includes …)*. A question whose answer only matters
  under another one is folded into it as sub-bullets (e.g. link expiry, licensing and privacy all
  hang off "are external addresses allowed?").
- **Business names only.** Use the names users see: grep the frontend for the labels (both
  languages). Always the full name — "automatic report", "report template", "competitor report" —
  never a bare "report" where two kinds exist. No table names, classes or `file:line` in the
  question text; evidence stays in chat and `.local_context`.
- **Scope discipline.** Only questions about this feature. Wording, UI and email copy are not asked
  unless the feature is about them.
- Close with **"Kept as today unless you object:"** — one line each.

## 7 — Iterate with the user

Show the draft and read the answer carefully; it usually mixes several moves. For each:

- **The user answers a question themselves** → it leaves the list. A business answer is a business
  rule like any other, whoever gave it (the user, a manager, a client need): it goes to
  `BUSINESS.md` (step 10). A technical answer is a position in CURRENT.
- **"What is X? Is X real or your assumption?"** → prove it from code (`file:line`, route, guard),
  answer in two lines, then rephrase the question so the doubt cannot recur.
- **"No risk? Then keep as today."** → do the risk analysis with evidence. No new risk: it moves to
  "kept as today". Risk only under another answer: fold it into that question.
- **New vocabulary** (a new verb or concept for an action) → grep the code for the word before
  adopting it. If it is already used — especially with a different or opposite meaning — say so with
  the `file:line` and offer 3-5 alternatives checked the same way, recommendation first.
- **A design idea that belongs to another feature** → analyse it there: what the code does today,
  whether it was tried before and dropped (`ARCHIVE.md` — and whether those reasons still hold),
  what it would change. Write the analysis into that feature's `CURRENT.md`, add it to its plan's
  § Blocked, put pointers in its subrepo folders, draft its own questions for its own ticket, and
  leave a one-paragraph note in this feature's `CURRENT.md` saying how it affects this one.
- **"Be clearer"** → rewrite the question around one concrete example of what changes for a user.

Re-show the full revised list each round. Stop when the user approves.

## 8 — Translate

Ask once which language the decision-maker reads (default: the project's locale). Translate the
approved text, using that language's UI labels from the frontend for every business name. Show it;
the user approves it separately — they may want to read it before the English goes anywhere.

## 9 — Post

Only after an explicit go. One comment per ticket: English block, `---`, translated block, same
structure and numbering. No AI attribution. Read the echoed body back and confirm it matches; note
the comment id. If posting is not possible (no ticket tool, no ticket), give the text ready to paste.

## 10 — Record

Read each region before writing and read it back after.

- **BUSINESS.md** (the feature's cross-repo one; create it from `local-context-new`'s template if
  absent): every business rule settled in this run — answers from the business, from the user, or
  found in the project docs (step 5) — under its theme, each with its date and ref (ticket comment
  id, doc) if any. No split by who decided. A rule that changes an existing one replaces it; the
  old wording goes to ARCHIVE verbatim. Code impact when resumed ("changes the built code: …",
  "depends on A2") goes in CURRENT, pointing at the rule.
- **CURRENT.md** (the feature's cross-repo one):
  - § *Technical positions, <date>* — the developer's-call answers, each with its evidence and any
    code impact when resumed.
  - Open items: one line pointing at the ticket comment id as the source of the pending questions.
  - Drift fixes the user approved in step 3, replacing the stale statement (never a correction
    beside it).
- **IMPLEMENTATION_PLAN.md**: § Blocked lists the pending questions by number with the ticket ref; a
  dev task a position implies is added only if it does not depend on an unanswered question —
  otherwise it waits in § Blocked with that dependency named.
- **Other features touched**: same treatment in their folders (step 7).
- **ARCHIVE.md**: one dated entry per touched folder, newest first, proving the old content
  is intact (the second command must print nothing; then `cp` the new file into place):
  `cat <entry.md> ARCHIVE.md > <scratch>/ARCHIVE.md`
  `tail -c +$(( $(wc -c < <entry.md>) + 1 )) <scratch>/ARCHIVE.md | cmp - ARCHIVE.md`

Never commit or push `.local_context/`.

## 11 — Hand-off

A few lines: where the questions were posted (ticket + comment id), what is pending on the business,
business rules added to `BUSINESS.md`, technical positions recorded, drift fixed, follow-ups filed elsewhere, and what unblocks the feature first.

## Rules for the whole run

- **No code, no DDL, no branch or MR changes.** This skill finds decisions; it does not act on them.
- **Never invent a business answer to unblock work.** A probable direction may be recorded as
  probable, never as decided.
- **Prove it.** Every claim about the code, a branch or a behaviour carries its evidence; a guess is
  labelled as a guess. An empty grep is an absence only if the search would have matched.
- **Outward-facing means confirm first.** Ticket comments, documents, messages: show the final text,
  wait for the go.
- **Ask only what the record cannot answer.** Never ask the user something the code, `BUSINESS.md`,
  the project docs or `.local_context` already answer; cite the source instead.
- **Every question carries a recommendation**, open ones too: recommended first with
  `(Recommended)` in `AskUserQuestion`, one line of why in prose. Ask in rounds, iterating on the
  answers, until nothing is open.
- **Short and clear** in chat; the decision-maker's text is plain business language.
