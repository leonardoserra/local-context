# Converting a flat folder to ICM

Read when a skill's layout check finds a folder `F` with flat files (`CURRENT.md`, `IMPLEMENTATION_PLAN.md`,
`ARCHIVE.md`, `BUSINESS.md`, `CRM.md`, `CODE_REVIEW_MAPPING.md`) and no `.no_icm`, or `.no_icm` beside `_`
folders. Paths: ICM.md; operations: ICM_OPS.md; formats: ICM_FORMATS.md; the last two by section (all next to
this file).

## Ask

Collect every folder the run reads or writes (sub-features, parent, same-name folders in other repos) and
ask in one `AskUserQuestion` call (a plain question without that tool), one question per folder, up to 4 per
call. Recommended option first.

- **Flat files only.** "`<F>` uses the old flat layout. The plugin now uses ICM (Interpretable Context
  Methodology): each multi-part file becomes a `_` folder with one file per piece and a STATE.md index, so
  the agent reads the index and opens only what it needs. Convert this folder?" When the project's
  `CLAUDE.md` / `CLAUDE.local.md` names a flat file
  (`grep -nE 'CURRENT\.md|BUSINESS\.md|ARCHIVE\.md|IMPLEMENTATION_PLAN\.md|CRM\.md' CLAUDE.md CLAUDE.local.md`),
  add: "`CLAUDE.md:<line>` names `<file>`: converting conflicts with it until you update that line."
  - `Convert (Recommended)` → § Convert, then ICM.
  - `Keep old layout` → `printf '\n' > F/.no_icm`, legacy. Say: delete `.no_icm` to be asked again.
  - Dismissed or cancelled → legacy for this run only; write nothing.
- **Flat files beside `_` folders** (an interrupted conversion, or an install older than 3.0.0 wrote flat
  files): list both sides; `Fold the flat files in (Recommended)` / `Stop`. Tell the user to update every
  agent install of the plugin. Fold, per flat file: cut it as § Convert does, show the pieces its `_` folder
  lacks (`grep -rlF '<the piece's first line>' F/_<x>`), add them with the ICM_OPS.md operations on OK, then delete
  the flat file. A `CRM.md` or `CODE_REVIEW_MAPPING.md` is never folded: offer to delete it, or to regenerate
  the map when unsure which is current.
- **`.no_icm` beside `_` folders, no flat file.** ICM; ask `Delete .no_icm (Recommended)` / `Keep it`.

## Convert

No script, no backup: every piece is cut with `sed -n 'A,Bp'`, never retyped, and proved with `cmp`. The flat
files stay in place until step 8.

- Scratch: `s=<scratchpad>/icm-<feature>` (`-<repo>` appended for a same-name folder in another repo), made
  with `mkdir "$s"`, not `-p`: it fails when the folder exists; then pick a new name, never reuse one. Every
  `_` folder is built in `$s/` first.
- Every proof below must print nothing. One fails → abort the conversion: install nothing, leave `F`
  untouched, report the failed proof.
- Heading lines, fence-aware: `awk '/^```/{f=!f} !f && /^###? /{print NR": "$0}' FILE`.
- A file shaped unlike the steps below (plan phases, `## Task N`, items in one paragraph) → show the proposed
  split (line ranges → file names), wait for OK, then cut and prove the same way.

1. **`ARCHIVE.md`** (newest first, entries `## YYYY-MM-DD — <title>`). Split only at dated `## ` lines outside
   ` ``` ` fences and outside `--- begin verbatim ---` / `--- end verbatim ---` (archived snapshots hold demoted
   headings that also start with `## `). Each entry → `_archive/YYYY_MM_DD/N.md`; lower in the file = older =
   smaller N.
   ```sh
   A=F/ARCHIVE.md; o=$s/_archive; mkdir $o
   awk '/^--- begin verbatim ---$/{v=1} /^--- end verbatim ---$/{v=0} !v && /^```/{f=!f}
        !f && !v && /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/{print NR}' $A > $s/heads.txt
   h=$(head -1 $s/heads.txt); : > $s/ahead.md; [ "$h" -gt 1 ] && sed -n "1,$((h - 1))p" $A > $s/ahead.md
   sort -rn $s/heads.txt | while read -r a; do            # bottom of the file (oldest) first
     b=$(awk -v a=$a '$1 > a {print $1 - 1; exit}' $s/heads.txt); b=${b:-'$'}
     d=$(sed -n "${a}p" $A | cut -c4-13 | tr - _); mkdir -p $o/$d
     n=$(( $(ls $o/$d | wc -l) + 1 ))
     sed -n "${a},${b}p" $A > $o/$d/$n.md; echo "$d/$n.md" >> $s/oldest_first.txt
   done
   { cat $s/ahead.md; awk '{l[NR]=$0} END {for (i=NR; i; i--) print l[i]}' $s/oldest_first.txt | sed "s|^|$o/|" | xargs cat; } | cmp - $A
   ```
   `_archive/STATE.md`: the ICM_FORMATS.md § F: archive header; after its paragraph the legend line "Entries up to
   `<the last migrated YYYY_MM_DD/N>.md` name the flat files: `CURRENT.md` = `_current/STATE.md` (§ Decisions = `_current/_decisions/`,
   § Open questions = `_current/_questions/`), `IMPLEMENTATION_PLAN.md` = `_implementation_plan/STATE.md`
   (§ Task N = row N), `ARCHIVE.md` = `_archive/STATE.md`, `BUSINESS.md` = `_business/`, `CRM.md` = `_crm/`."
   and `$s/ahead.md`, if not empty; then the table, one row per line of `$s/oldest_first.txt`, in order: Title
   = the heading after `## <date> — `; Commits = the heading's hex words (`grep -oE '[0-9a-f]{7,40}'`) that
   `git cat-file -t` calls a commit, joined with `, `, else `—`.
2. **`IMPLEMENTATION_PLAN.md`** with `## Tasks` and `### N — <title>` tasks under it. Status suffixes and
   `**Depends on**` lines leave the tasks first (they live in the table); then cut the stripped copy:
   `$s/pre.md` = line 1 to the line before the first task; a task = its `###` line to the line before the
   next `###` or `## `; `$s/post.md` = the first `## ` after the tasks to the end. Each task →
   `_implementation_plan/NN_<slug>.md`, NN = N.
   ```sh
   P=F/IMPLEMENTATION_PLAN.md   # T,U = first task line, last task line
   awk -v t=T -v u=U '/^```/{f=!f} NR>=t && NR<=u && !f { if (/^### [0-9]+ — /) sub(/ (✅|⛔|⏸|done-uncommitted).*$/, "")
     else if (/^- \*\*Depends on\*\*/) next } {print}' $P > $s/plan_stripped.md      # fenced lines untouched
   diff $P $s/plan_stripped.md | grep '^[<>]' | grep -vE '^[<>] ### [0-9]+ — |^< - \*\*Depends on\*\*'   # nothing else changed
   awk '/^```/{f=!f; next} f' $P | cmp - <(awk '/^```/{f=!f; next} f' $s/plan_stripped.md)          # fences identical
   cat $s/pre.md <task files, file order> $s/post.md | cmp - $s/plan_stripped.md
   cat $s/pre.md $s/table.md $s/post.md > $s/_implementation_plan/STATE.md
   ```
   `$s/table.md` = the Tasks table and an empty line, a row per task in file order: Task = the title; Depends
   on = the removed `**Depends on**:` text (`diff` `<` lines), else `—`; Status from the removed suffix: `✅ DONE …`
   and `⛔ …` as they are, `⏸ …` → `⏸ blocked`, `done-uncommitted[ <date>]` → `done-uncommitted <date>` (no
   date: today's, say so), none → `todo`.
3. **`CURRENT.md`.** Items = each top-level `- ` bullet with its continuation lines (trailing empty lines
   excluded), or each `### ` subsection, under `## Decisions` and under `## Open questions`. Pieces: `head` (to
   the line before the first decision item), decision items → `_current/_decisions/NN_<slug>.md`, `mid`,
   question items → `_current/_questions/NN_<slug>.md`, `tail`. A section with no items keeps its text; its
   pointer goes right after it.
   ```sh
   cat $s/head.md <decision files> $s/mid.md <question files> $s/tail.md | cmp - F/CURRENT.md
   cat $s/head.md $s/dptr.md $s/mid.md $s/qptr.md $s/tail.md > $s/_current/STATE.md
   ```
   `dptr.md` / `qptr.md` = the § Decisions / § Open questions pointer line of ICM_FORMATS.md
   § F: current, no empty line. Write `$s/_current/_decisions/STATE.md` and
   `$s/_current/_questions/STATE.md` from ICM_FORMATS.md § F: decisions questions, always
   (an empty table when no items), a row per item: the item in one line; Date and Who as the item states, else
   `—`; Status `open`, or `answered <date> → _current/_decisions/NN_<slug>.md` when the item says so.
4. **`BUSINESS.md`.** `$s/bhead.md` = the text before the first `## `; each `## <theme>` section →
   `_business/<theme-slug>.md`.
   ```sh
   cat $s/bhead.md <theme files, file order> | cmp - F/BUSINESS.md
   cat $s/bhead.md $s/btable.md > $s/_business/STATE.md
   ```
   Rows: Rules = `grep -c '^- '`; Last changed = the latest `YYYY-MM-DD` in the file; Summary = one line.
5. **`CRM.md`** (or `CODE_REVIEW_MAPPING.md`). `$s/chead.md` = the text before the first `### ` outside fences;
   each `### ` section → `_crm/NN_<slug>.md`, NN = its group number.
   ```sh
   sed '/^### /s/ ✅ reviewed$//' F/CRM.md > $s/crm_stripped.md
   cat $s/chead.md <group files, file order> | cmp - $s/crm_stripped.md
   cat $s/chead.md $s/groups.md > $s/_crm/STATE.md
   ```
   `$s/groups.md` = ICM_FORMATS.md § F: crm from `## Groups` on, a row per group (§ F: pieces); Status
   = `✅ reviewed` where the original heading had it, else `todo`.
6. **Install**, once every proof passed: per folder `cp -R $s/_<x> F/ && diff -r $s/_<x> F/_<x>`.
7. **Pointers**, in live files only: `_archive/` is never edited (its legend maps the old names). Folders: `F`,
   and the ICM ones among its parent, sub-features and same-name folders. Anchored forms first, then bare names;
   a name after `/` (`<path>/CURRENT.md`) is left for the prefixed pass:
   ```sh
   grep -rlE 'CURRENT\.md|BUSINESS\.md|ARCHIVE\.md|IMPLEMENTATION_PLAN\.md|CRM\.md' F <folders> --exclude-dir=_archive \
     --exclude={CURRENT,BUSINESS,ARCHIVE,IMPLEMENTATION_PLAN,CRM,CODE_REVIEW_MAPPING}.md > $s/live.txt
   B='(^|[^/A-Za-z_])'; : > $s/ptr.sed
   awk -F' *\\| *' '/^\| [0-9]+ \|/{print $2, $3}' F/_implementation_plan/STATE.md | while read -r n f; do
     echo "s#${B}IMPLEMENTATION_PLAN\\.md(\`?) § Task $n([^0-9]|\$)#\\1_implementation_plan/$f\\2\\3#g" >> $s/ptr.sed; done
   for x in 'CURRENT\.md(`?) § Decisions#_current/_decisions/STATE.md' 'CURRENT\.md(`?) § Open questions#_current/_questions/STATE.md' \
     'IMPLEMENTATION_PLAN\.md()#_implementation_plan/STATE.md' 'CURRENT\.md()#_current/STATE.md' 'BUSINESS\.md()#_business/STATE.md' \
     'ARCHIVE\.md()#_archive/STATE.md' 'CRM\.md()#_crm/STATE.md'; do echo "s#$B${x%%#*}#\\1${x#*#}\\2#g" >> $s/ptr.sed; done
   sed -i.bak -E -f $s/ptr.sed $(cat $s/live.txt)
   grep -rhoE '[^ `(]+/(CURRENT|BUSINESS|ARCHIVE|IMPLEMENTATION_PLAN|CRM)\.md' $(cat $s/live.txt) | sort -u   # prefixed
   for D in _implementation_plan _current/_decisions _current/_questions _business; do
     grep -rlF --exclude=STATE.md "$D/STATE.md" F/$D; done                     # back-pointers: must print nothing
   ```
   Prefixed paths: rewrite only those whose folder is ICM (`[ -d <path>/_current ]`), one exact `sed` each. A
   back-pointer (a piece naming its own `STATE.md`) is pointed at the piece meant, or dropped. Check each change
   with `diff <file>.bak <file>`, then delete the `.bak` files. A `_current/STATE.md:<line>` pointer whose line
   moved into a decision or question file is pointed at that file.
8. **Finish.** `rm` the flat files. `archive add` an entry "converted to ICM": per flat file the pieces it
   became and the proofs that passed, and the files whose pointers changed.
