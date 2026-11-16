# Migration steps

One section per flat file, plus fold, pointers and across; read § helpers first, then only the section you run.
`F` = the folder, `$s` = its scratch dir, `<n>` = `../local-context-new` from this file. Every proof prints nothing;
one that prints → abort the folder (SKILL.md § 0). Nothing here is asked: when a shape is unclear, the rule of the
section decides and `$s/notes.md` records it.

## helpers

Used by every section below; define them in each shell that runs a section.

- Heading lines, fence-aware: `awk '/^```/{f=!f} !f && /^###? /{print NR": "$0}' FILE`.
- Slug of a title (accents transliterated, lowercased, `_`-joined, cut at a word boundary, ≤ 40 chars; a taken slug
  gets `_2`):
  ```sh
  slug() { printf '%s' "$1" | perl -CSD -MUnicode::Normalize -pe '$_ = NFD($_); s/\pM//g' | tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g' |
    awk '{ if (length($0) <= 40) { print; exit } s = substr($0, 1, 41); sub(/_[^_]*$/, "", s); print (s == "" || length(s) > 40 ? substr($0, 1, 40) : s) }'; }
  ```
- Live files of a folder: its own `*.md` files, sub-feature folders (not starting with `_`) and `_archive/` pruned,
  the flat set left out:
  ```sh
  live() { find "$1" -mindepth 1 -type d ! -name '_*' -prune -o -path "$1/_archive" -prune -o -type f -name '*.md' \
    ! -name CURRENT.md ! -name BUSINESS.md ! -name ARCHIVE.md ! -name IMPLEMENTATION_PLAN.md ! -name CRM.md \
    ! -name CODE_REVIEW_MAPPING.md -print; }
  ```
- Table cells: `|` → `/`.

## archive

Rule 7. `ARCHIVE.md`, entries `## YYYY-MM-DD… — <title>`, newest first. Split only at dated `## ` lines outside
` ``` ` fences and outside `--- begin verbatim ---` / `--- end verbatim ---` (archived snapshots hold demoted
headings that also start with `## `). Each entry → `_archive/YYYY_MM_DD/N.md`; older = smaller N.
```sh
A=F/ARCHIVE.md; o=$s/_archive; mkdir $o; : > $s/oldest_first.txt; : > $s/ahead.md
awk '/^--- begin verbatim ---$/{v=1} /^--- end verbatim ---$/{v=0} !v && /^```/{f=!f}
     !f && !v && /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/{print NR}' $A > $s/heads.txt
if [ ! -s $s/heads.txt ]; then                         # no dated entry: the whole file is the head, the table empty
  cp $A $s/ahead.md; echo 'ARCHIVE.md: no dated `## YYYY-MM-DD` heading; the whole file kept above an empty table' >> $s/notes.md
else
  h=$(head -1 $s/heads.txt); [ "$h" -gt 1 ] && sed -n "1,$((h - 1))p" $A > $s/ahead.md
  sort -rn $s/heads.txt | while read -r a; do          # bottom of the file (oldest) first
    b=$(awk -v a=$a '$1 > a {print $1 - 1; exit}' $s/heads.txt); b=${b:-'$'}
    d=$(sed -n "${a}p" $A | cut -c4-13 | tr - _); mkdir -p $o/$d
    n=$(( $(ls $o/$d | wc -l) + 1 ))
    sed -n "${a},${b}p" $A > $o/$d/$n.md; echo "$d/$n.md" >> $s/oldest_first.txt
  done
fi
{ cat $s/ahead.md; awk '{l[NR]=$0} END {for (i=NR; i; i--) print l[i]}' $s/oldest_first.txt | sed "s|^|$o/|" | xargs cat; } | cmp - $A
```
A file oldest first (its first dated heading older than its last): `sort -n` in the loop, and the proof cats
`oldest_first.txt` as it is, not reversed.

`$s/_archive/STATE.md`: the ICM_FORMATS.md § F: archive header; after its paragraph the legend line "Entries before
the `converted to ICM` entry name the flat files: `CURRENT.md` = `_current/STATE.md` (§ Decisions =
`_current/_decisions/`, § Open questions = `_current/_questions/`), `IMPLEMENTATION_PLAN.md` =
`_implementation_plan/STATE.md` (§ Task `<id>` = the row whose Task starts with `<id>`), `ARCHIVE.md` =
`_archive/STATE.md`, `BUSINESS.md` = `_business/`, `CRM.md` (`CODE_REVIEW_MAPPING.md`) = `_crm/`." and
`$s/ahead.md`, if not empty; then the table, one row per line of `$s/oldest_first.txt`, in order:

- **Title** = the heading text after its **first** ` — ` (`## <date> (afternoon) — <title>` → `<title>`); a heading
  with no ` — ` → its remainder after the date.
- **Commits** = the heading's hex words (`grep -oE '\b[0-9a-f]{7,40}\b'`) that `git -C <repo> cat-file -t <word>`
  calls `commit` in **any** repo the feature spans (the folder's own, the parent repo, sibling repos and
  submodules), joined with `, `, else `—`.

No dated entry (`heads.txt` empty): the same `STATE.md`, with the whole file as its `ahead.md` and an empty table;
no entry files. No `ARCHIVE.md`: `$s/_archive/STATE.md` is still written, header, legend and an empty table: the plan's moved
session logs and the `converted to ICM` entry go there.

## plan

Rules 1–4. `IMPLEMENTATION_PLAN.md`; `P=F/IMPLEMENTATION_PLAN.md`.

**Rule 1, tasks.** Every heading outside fences of the shape `### <id> — <title>` (or `<id>: `) is a task, in file
order, whatever its id: `<id>` = `(Task )?[A-Z]{0,3}[0-9]+([.][0-9]+)*[a-z]?` (`3`, `P3`, `P3b`, `Task 12`, `2.1`);
ids out of order (`P26` before `P24`) stay in file order. No `###` task but `##` ones (`## Task 3 — …`): the same
at `##` (`H='##'`). No task heading at all: `STATE.md` = the whole file, then an empty Tasks table under its
`## Tasks` heading (a new `## Tasks` at the end when it has none); noted. File = `NN_<slug>.md`, NN = position in
the file (`printf %02d`), never the id; the slug from the title after the id. The id stays in the title: the task
file keeps its heading, the table's Task = the kept heading without `### ` (`P3b — <title>`), so a grep for the id
still finds it.

**Rule 2, status.** Split each task heading into the kept heading and the stripped status, from the separator (or
from the status marker) to the end of the line, so no trailing ` —` is left; a done marker inside the title
without a separator (`… → ✅ DONE <date>`) counts too:
```sh
H='###'; perl -CSD -Mutf8 -ne '$f = !$f if /^```/; next if $f; chomp;
  next unless /^('"$H"' (?:Task )?[A-Z]{0,3}\d+(?:\.\d+)*[a-z]?(?: — |: ))(.*)$/; my ($p, $r) = ($1, $2); my ($t, $x) = ($r, "");
  my $w = qr/(?:done|not started|planned|open|later|next|in progress|doing|superseded|moved|replaced|blocked|waiting|closed|abandoned|todo)\b/i;
  if    ($r =~ /^(.*?)\s*(?:(?:—|→|-)\s*)?((?:✅|⛔|⏸|📝|⏳|🟡|(?i:done-uncommitted)\b).*)$/) { ($t, $x) = ($1, $2) }   # marker, any place
  elsif ($r =~ /^(.*) — ($w.*)$/)                                { ($t, $x) = ($1, $2) }   # status after its own " — "
  elsif ($r =~ /^(.*?)\s*[(\[]($w[^)\]]*)[)\]]\s*$/)              { ($t, $x) = ($1, $2) }   # "(done …)", "[blocked]" at the end
  elsif ($r =~ /^(.*) — (.*)$/)                                  { ($t, $x) = ($1, $2) }   # unknown status after the last " — "
  print "$.\t$p$t\t$x\n"' $P > $s/heads.tsv                 # line, kept heading, stripped status
# headings left without a status whose title still holds " — " or a status word
perl -CSD -Mutf8 -F'\t' -lane 'next if length($F[2] // ""); (my $t = $F[1]) =~ s/^#+ (?:Task )?\S+(?: — |: )//;
  print "check $F[0]: $F[1]" if $t =~ / — |\b(?:done|not started|planned|in progress|doing|superseded|moved|replaced|blocked|waiting|closed|abandoned|todo)\b/i' $s/heads.tsv
```
Each row the check lists is decided, never asked: the word belongs to the title (`Move the blocked jobs`) → kept,
noted; it is a status → that row's kept heading becomes the line up to the word (separator and spaces dropped) and
its status the rest, so the prefix proof below still holds; noted. Status column, from the stripped text (any case,
emoji or word):

| Found in the heading | Status column |
|---|---|
| done / ✅ … (with date, SHAs, notes) | kept verbatim |
| not started / 📝 / planned / open / ⏳ / later / next | `todo` |
| in progress / 🟡 / doing | `doing` |
| superseded / moved / replaced … by X | `⛔ MOVED <rest of the text verbatim>` |
| blocked / waiting on … / ⏸ | `⏸ blocked` |
| done-uncommitted [date] | `done-uncommitted <date>` (no date: today's, noted) |
| no status at all | `todo` |
| anything else | stripped anyway; Status = the verbatim text; noted |

Every stripped text goes verbatim, with its Status, into `$s/notes.md` (the archive entry keeps it).

**Rule 3, Depends on.** Each top-level `- **Depends on**` bullet in the task range is removed whole, with its
wrapped continuation (indented lines up to the next bullet or blank line); a nested `**Depends on**` inside another
bullet stays. Its text (after the label and an optional `:`, continuation joined with a space) goes verbatim into the
task's Depends on cell, even when it is not a task number ("the user's QA feedback first", "P6, <other repo> P5");
several bullets joined with `; `; none → `—`. A removed line belongs to the last task heading above it.
```sh
T=$(head -1 $s/heads.tsv | cut -f1); L=$(tail -1 $s/heads.tsv | cut -f1)
U=$(awk -v l=$L '/^```/{f=!f} !f && NR > l && /^## /{print NR - 1; exit}' $P); U=${U:-$(awk 'END{print NR}' $P)}   # post starts at U+1
awk -F'\t' -v t=$T -v u=$U -v dep=$s/deps.tsv 'NR == FNR {k[$1] = $2; next}
  /^```/ {f = !f; d = 0}
  !f && FNR >= t && FNR <= u {
    if (FNR in k) {print k[FNR]; next}
    if (d && /^[ \t]+[^ \t]/ && !/^[ \t]+([-*+]|[0-9]+\.) /) {print FNR "\t" $0 > dep; next}
    d = 0; if (/^- \*\*Depends on/) {d = 1; print FNR "\t" $0 > dep; next} }
  {print}' $s/heads.tsv $P > $s/plan_stripped.md
# the strip proof: kept headings are prefixes; the diff holds only changed headings and removed bullet lines; fences identical
while IFS="$(printf '\t')" read -r n k x; do case "$(sed -n "${n}p" $P)" in "$k"*) ;; *) echo "heading $n: not a prefix";; esac; done < $s/heads.tsv
diff $P $s/plan_stripped.md | grep '^[<>]' | grep -vxF -f <(cut -f2- $s/deps.tsv | sed 's/^/< /'
  cut -f1 $s/heads.tsv | while read -r n; do printf '< %s\n' "$(sed -n "${n}p" $P)"; done; cut -f2 $s/heads.tsv | sed 's/^/> /')
cut -f2- $s/deps.tsv | grep -vE '^- \*\*Depends on' | grep -E '^[^[:blank:]]|^[[:blank:]]*$|^[[:blank:]]+([-*+]|[0-9]+\.) '   # removed: bullets and continuations only
awk '/^```/{f=!f; next} f' $P | cmp - <(awk '/^```/{f=!f; next} f' $s/plan_stripped.md)
```

**Cut**, in `$s/plan_stripped.md` (`S`), at the heading lines of the task level or above (`##`/`###` for `###`
tasks, `##` only for `##` tasks), outside fences: `$s/pre.md` = line 1 to the line before the first task; one chunk
per heading from the first task to the post start, heading line to the line before the next cut point →
`$s/c/NNN.md` (`%03d`, file order); `$s/post.md` = the first `## ` after the last task, to the end.
```sh
cat $s/pre.md $s/c/* $s/post.md | cmp - $s/plan_stripped.md
```

**Rule 4, non-task chunks.** A chunk whose heading is not a task is placed by content, never asked, never a task row:

| What it is | Where it goes |
|---|---|
| A **dated session log**: "session decisions <date>", answers to a status review, a list of closures and of tasks created that day | **New archive entry** `$s/_archive/<YYYY_MM_DD>/<next N>.md`: heading `## <date> — <section title> (moved from the plan at ICM migration)`, an empty line, the body cut verbatim (`tail -n +2` of the chunk, leading empty lines dropped); a row appended to `$s/_archive/STATE.md`; one pointer line, after an empty line, at the end of the preceding task file: `<section title>: _archive/<YYYY_MM_DD>/<N>.md` |
| **The outcome, check or closure of one specific task** (its heading names that task's id, or it is that task's "Done when" result) | **Appended verbatim to that task's file**, even far from it in the source |
| A **reference table or list** about the whole plan ("commits the plan did not cite", "follow-up index") | **The plan's closing part**: first in `post`, or right before `post`'s section of the same kind when it has one, where sibling folders keep it |
| Can't be classified (a phase heading included) | **Appended to the preceding task's file**: original order kept, no task row |

Every chunk, task or not, is one line of `$s/placed.tsv` (`NNN.md\t<target>\t<why>`); each non-task placement is
also one line of `$s/notes.md`.

**Assemble**, by `cat` of the chunks only:

- task file `$s/_implementation_plan/NN_<slug>.md` = its chunk, then the chunks placed with it, in file order
  (session-log pointer lines at their place);
- `$s/table.md` = `## Tasks` and an empty line only when `pre.md` has no `## Tasks` line; then the Tasks header of
  ICM_FORMATS.md § F: plan and a row per task in file order:
  `| <N> | <NN>_<slug>.md | <kept heading without "### "> | <Depends on> | <Status> |`; then an empty line;
- `cat $s/pre.md $s/table.md <post with the reference chunks placed> > $s/_implementation_plan/STATE.md`.

```sh
ls $s/c | comm -3 - <(cut -f1 $s/placed.tsv | sort)     # every chunk placed
cut -f1 $s/placed.tsv | sort | uniq -d                     # none placed twice
```

`$s/anchors.tsv` (§ pointers): per task `IMPLEMENTATION_PLAN.md\tTask <id>\t_implementation_plan/<file>` and
`IMPLEMENTATION_PLAN.md\t<id>\t_implementation_plan/<file>`.

## current

Rule 5. `CURRENT.md`. Sections = `## ` headings outside fences. Item = a top-level `- ` or `N. ` bullet with its
continuation lines (trailing empty lines excluded), or a `### ` subsection.

- **Decision sections**: any `## ` heading meaning settled decisions, whatever the words: `## Decisions`,
  `## Decisions (<who>, <date>)`, `## Technical positions <date>`, `## Agreed`, `## Settled`. Their items →
  `_current/_decisions/NN_<slug>.md`, NN across sections in file order. The heading stays in `STATE.md`; its items
  are replaced by the § Decisions pointer line.
- **`## Open questions`**: its items → `_current/_questions/NN_<slug>.md`.
- **Open-items sections are not questions by default.** "Open items", "Open items carried", "TODO", "Notes" stay as
  text in `STATE.md`. A bullet there becomes a question item only if it is phrased as a question or explicitly waits
  for someone's answer.
- **Performance invariants, data facts, code layout** and similar reference sections stay as text.

Cut the file in order into chunks `$s/k/NNN.md` (`%03d`), each a text run or one item, kinds in `$s/kinds.tsv`
(`NNN\ttext|d|q`):
```sh
cat $s/k/* | cmp - F/CURRENT.md
```
`$s/_current/STATE.md` = the text chunks in order, where the first item of each decision section is replaced by
`$s/dptr.md` and the first item of `## Open questions` by `$s/qptr.md` (the § Decisions / § Open questions pointer
lines of ICM_FORMATS.md § F: current, no empty line); the other items leave nothing, and blank-only text chunks
between two items of one section are dropped. A section whose items all moved elsewhere keeps its text; its
pointer goes right after it. No `## Open questions` section: `## Open questions`, an empty line and the pointer at
the end of `STATE.md`, after an empty line, so it does not merge into the previous bullet; no decision section:
`## Decisions` and its pointer the same way, before it.

**Both tables are always written** from ICM_FORMATS.md § F: decisions questions, `$s/_current/_decisions/STATE.md`
and `$s/_current/_questions/STATE.md`, empty when no items; a row per item: the item in one line; Date and Who from
the item, else from its section heading, else `—`; question Status `open`, or
`answered <date> → _current/_decisions/NN_<slug>.md` when the item says so. Slug: the item's first line without
bullet, bold and number.

`$s/anchors.tsv`: `CURRENT.md\tDecisions\t_current/_decisions/STATE.md`,
`CURRENT.md\tOpen questions\t_current/_questions/STATE.md`, each other decision section's heading text →
`_current/_decisions/STATE.md`, each `### ` decision or question → its file.

## business

Rule 6. `BUSINESS.md`. `$s/bhead.md` = the text before the first `## ` outside fences; each `## <theme>` section,
its own `###` subsections included (one file), → `_business/<theme-slug>.md`.
```sh
cat $s/bhead.md <theme files, file order> | cmp - F/BUSINESS.md
cat $s/bhead.md $s/btable.md > $s/_business/STATE.md
```
`$s/btable.md` = the table of ICM_FORMATS.md § F: business, a row per theme: Rules =
`grep -cE '^(- |[0-9]+\. )'` (a numbered list counts its `N. ` lines); Last changed = the latest `YYYY-MM-DD` in
the file, else `—`; Summary = one line.

No `## ` theme (typically an index: "the rules live in `<other folder>`, never a copy"): `_business/STATE.md` =
the whole file, an empty line, and the empty table; no theme files; noted.

`$s/anchors.tsv`: per theme `BUSINESS.md\t<theme>\t_business/<theme-slug>.md`.

## crm

Rule 8, unchanged. `CRM.md` (or `CODE_REVIEW_MAPPING.md`). `$s/chead.md` = the text before the first `### ` outside
fences; each `### ` section → `_crm/NN_<slug>.md`, NN = its group number.
```sh
sed '/^### /s/ ✅ reviewed$//' F/CRM.md > $s/crm_stripped.md
cat $s/chead.md <group files, file order> | cmp - $s/crm_stripped.md
cat $s/chead.md $s/groups.md > $s/_crm/STATE.md
```
`$s/groups.md` = ICM_FORMATS.md § F: crm from `## Groups` on, a row per group (§ F: pieces); Status = `✅ reviewed`
where the original heading had it, else `todo`.

## fold

A folder with flat files beside its `_` folders (an interrupted conversion, or an install older than 3.0.0 wrote
flat files). Flat files except the map:

1. Cut and prove **every** one in `$s` by its section above before step 2 touches `F`: a failed proof leaves `F`
   untouched (nothing is installed from `$s` as a whole).
2. Then, per flat file, each piece whose first line is not in its `_` folder (`grep -rlF -- '<first line>' F/_<x>` prints nothing) is
   added with the ICM_OPS.md operations: `decision add`, `question add`, `plan add task` (NN = highest + 1, the
   row from `$s/table.md` renumbered), `archive add` (the entry's own date), a business theme as a new piece and
   row. Same first line and identical text: already in. Same first line, different text: the `_` piece stays,
   the flat text is kept by step 3; noted.
3. Text that is not a piece (plan `pre`/`post`, `CURRENT.md` text runs, `bhead.md`) is not merged. The whole flat
   file goes into the `converted to ICM` entry body as a `--- begin verbatim ---` block, built and proved as
   ICM_OPS.md § snapshot builds one. An `ARCHIVE.md` whose entries are all in `_archive/` after step 2 needs only
   its `ahead.md` there, if not empty.

The map (`CRM.md`, `CODE_REVIEW_MAPPING.md`) is never folded. No `_crm/`: § crm. `_crm/` present: the newer by
its `Generated <date>` line wins; `_crm/` newer or the same → the flat map is deleted at finish; the flat map newer
→ converted by § crm and installed in place of `_crm/`. Noted; the report recommends
`local-context-code-review-mapping` (the map is derived).

Then § pointers as for a converted folder.

## pointers

Rule 9, inside one folder, after install. Live files: § helpers `live F` (the new pieces and the files outside the
ICM set included; sub-feature folders are their own workers' job):
```sh
live F | xargs grep -lE '(CURRENT|BUSINESS|ARCHIVE|IMPLEMENTATION_PLAN|CRM|CODE_REVIEW_MAPPING)\.md' /dev/null > $s/live.txt
```
Rewrite only bare and anchored names meaning **this** folder's files (`CURRENT.md`, `X.md § Task N`,
`X.md § <Section>`). Never a name qualified as another folder's file ("<other repo> `CURRENT.md`", "root
`BUSINESS.md`", "parent `…`", "subrepo `…` files", `<path>/CURRENT.md`: rule 10 handles them), a quoted archive
title (`entry "<date> — CURRENT.md cut"`) or historical wording ("pre-tidy `CURRENT.md`"). `$s/ptr.pl`, in this
order, run with `perl -CSD -Mutf8 -i.bak -p $s/ptr.pl $(cat $s/live.txt)`:

1. Protect what is not this folder's file (`Q` = `root|parent|subrepo|pre-[\w-]+|old|flat|former|<repo names>`):
   ```perl
   s{(?:\b(?:Q)\s+`?|"\d{4}-\d\d-\d\d[^"]*?)\K(?=(?:CURRENT|BUSINESS|ARCHIVE|IMPLEMENTATION_PLAN|CRM|CODE_REVIEW_MAPPING)\.md)}{\x01}g;
   ```
2. Anchors, longest first, from `$s/anchors.tsv` (`<flat name>\t<anchor>\t<piece path>`): a business section →
   its theme file; a plan task → its task file; a decision → its decision file.
   ```sh
   awk -F'\t' '{print length($2) "\t" $0}' $s/anchors.tsv | sort -rn | cut -f2- |
     awk -F'\t' '{printf "s{(^|[^/\\w\\x01])\\Q%s\\E(`?) § \\Q%s\\E(?!\\w|\\.\\d)}{$1%s$2}g;\n", $1, $2, $3}' >> $s/ptr.pl
   ```
3. `file:line` pointers into a converted file (`grep -rnoE '(^|[^/A-Za-z_])(CURRENT|…)\.md:[0-9]+' $(cat $s/live.txt)`):
   the new line by content, never by arithmetic alone: the old line `sed -n '<n>p' F/X.md`, found with
   `grep -rnF -- '<that line>' F/_<x>` (several hits → the piece cut from that line's range); one exact line
   `s{(^|[^/\w\x01])X\.md:<n>(?!\d)}{$1_<x>/<piece>:<new n>}g;` per pointer.
4. Bare names, only for the flat files the folder had: `CURRENT.md` → `_current/STATE.md`, `BUSINESS.md` →
   `_business/STATE.md`, `ARCHIVE.md` → `_archive/STATE.md`, `IMPLEMENTATION_PLAN.md` →
   `_implementation_plan/STATE.md`, `CRM.md` / `CODE_REVIEW_MAPPING.md` → `_crm/STATE.md`, each
   `s{(^|[^/\w\x01])CURRENT\.md(?!:\d)}{$1_current/STATE.md}g;` (a `file:line` step 3 missed stays visible to
   the final check, never pointed at a stale line).
5. `s{\x01}{}g;`

Then:
```sh
for f in $(cat $s/live.txt); do diff $f.bak $f; done          # read every change; a hunk against rule 9 → reverted, one exact perl
for D in _implementation_plan _current/_decisions _current/_questions _business; do
  grep -rlF --exclude=STATE.md "$D/STATE.md" F/$D; done           # back-pointers
grep -rnoE '_[a-z_/]+/STATE\.md`? § [^`,;)]+' $(cat $s/live.txt)  # each § must be a heading of that STATE.md
rm $(sed 's/$/.bak/' $s/live.txt)
```
- **Back-pointers**: a piece naming its own `STATE.md` is pointed at the piece meant, or the reference is dropped.
- **Stale anchors** (a § that never existed in the source) are not fixed; noted for the report.
- **Left for § across**: qualified and prefixed references to another folder's flat files:
  ```sh
  grep -nE '(\b(root|parent|subrepo|<repo names>)[[:blank:]]+`?|[^ `("]*/)(CURRENT|BUSINESS|ARCHIVE|IMPLEMENTATION_PLAN|CRM)\.md' $(cat $s/live.txt)
  ```

## across

Rule 10, orchestrator only, after every folder is installed and its § pointers done; flat files still in place.
Sources: `live <folder>` (§ helpers) of every migrated folder, and of the ICM folders the feature spans (they may
name a migrated folder's flat files).

1. **Collect** the qualified and prefixed references to another folder's flat files: "root `X.md`",
   "<repo> `X.md`", `../../../<path>/X.md`, `<Repo>/<path>/X.md`, `<path>/X.md:<line>`, with ` § <anchor>` when
   present. Resolve each to its folder `T` (root = the root repo's same-name folder; `<repo>` = that repo's
   same-name folder; a path from the file's own location).
2. **`T` is ICM** (`[ -d <T>/_current ]`): rewrite each exactly, qualifier and path prefix kept:
   - `X.md` → `_x/STATE.md`;
   - `X.md § Task N` / `§ N` → `_implementation_plan/<that task's file>` (`T`'s `anchors.tsv`, else its Tasks row);
   - `X.md § <Section>` → that piece file;
   - `X.md:<line>` → `<piece file>:<new line>`, matched by content in `T`'s flat file (`grep -nF`). `T` converted
     in an earlier run (its flat file gone): the `:<line>` form is left; noted.
3. **`T` is not ICM** (another feature still flat, or kept with `.icm` = `false`): untouched.
4. **Each rewrite** is one exact `perl -CSD -Mutf8 -i.bak -pe` (or `sed`) per file, checked with
   `diff <file>.bak <file>`; then the `.bak` files are deleted.
5. **Final check**, over all migrated folders:
   ```sh
   for D in <folders>; do live "$D"; done | xargs grep -nE '(CURRENT|BUSINESS|ARCHIVE|IMPLEMENTATION_PLAN|CRM)\.md' /dev/null
   ```
   Only quoted archive titles, historical wording and references to non-ICM folders may remain; the report lists
   them.
