# ICM operations

One section per operation; read only the one you run. The rules and shapes they rely on: ICM.md.

## decision add

A piece in `F/_current/_decisions/`, one call:
```sh
D=F/_current/_decisions; cat > $D/<NN>_<slug>.md <<'EOF'
<content>
EOF
printf '%s\n' '<row>' >> $D/STATE.md && tail -n 2 $D/STATE.md
```

## question add

As decision add, in `F/_current/_questions/`, Status `open`.

## question answer

`decision add` the answer, citing the question file. Then the question's row Status →
`answered <YYYY-MM-DD> → _current/_decisions/<file>`. The question file stays. A business answer is also a
`business rule set`.

## plan add task

A piece in `F/_implementation_plan/`; its row goes after the last row of the § Tasks table, not at the end:
```sh
D=F/_implementation_plan; cat > $D/<NN>_<slug>.md <<'EOF'
<content>
EOF
awk -v r='<row>' 'NR==FNR{if(/^## Tasks/)t=1; else if(t&&/^\|/){n=FNR;g=1} else if(t&&(/^## /||(g&&/^$/)))t=0; next} {print} FNR==n{print r}' $D/STATE.md $D/STATE.md > $D/.t && mv $D/.t $D/STATE.md && grep -nF '<NN>_<slug>.md' $D/STATE.md
```

## plan mark

The task's row: its Status cell only. The task file is not touched.

## archive add

A piece in `F/_archive/<YYYY_MM_DD>/`, file `<N>.md`, N = the files there + 1. Commits = `<start>..<end>`
(`<start>` = the short HEAD noted when the session began; `<repo>@<start>..<end>` per repo when several moved),
`—` with no commit or no git.
```sh
D=F/_archive; d=<YYYY_MM_DD>; mkdir -p $D/$d; n=$(( $(ls $D/$d | wc -l) + 1 )); cp <entry> $D/$d/$n.md
printf '| %s | %s | %s |\n' "$d/$n.md" '<commits>' '<title>' >> $D/STATE.md && tail -n 2 $D/STATE.md
```

## archive find

`grep -i '<term>' F/_archive/STATE.md; grep -rlF '<term>' F/_archive/*/`; open only the matches.

## business rule set

In the theme's file (its row in `F/_business/STATE.md`): replace the changed rule in place, or add a bullet. A new
theme is a new piece and row; no `_business/` yet: ICM_FORMATS.md § F: business. Then the row's Rules
(`grep -c '^- '`), Last changed, Summary, and the "as of" date.

## legacy

A `.no_icm` folder keeps the flat files of 2.0.0; ICM paths in the skills mean them: `_current/` = `CURRENT.md`
(decisions and open questions are its § Decisions, § Open questions); `_implementation_plan/` =
`IMPLEMENTATION_PLAN.md` (`### N — <title>` tasks with Repo / Depends on / Anchors / Done when bullets, status as a
heading suffix); `_business/` = `BUSINESS.md` (a section per theme, bullets `- <rule> — <date>; <ref>`); `_crm` =
`CRM.md`; `_archive/` = `ARCHIVE.md`, newest first. Read: `CURRENT.md` and `BUSINESS.md` in full; the plan by
`grep -n '^#'`, then `sed -n 'A,Bp'` of § START HERE, the next open task(s), § Blocked on a decision, § Verification
commands, § Do NOT do (YAGNI). An archive entry `E` is prepended, proving the old content intact (the `cmp` prints
nothing):
```sh
cat E ARCHIVE.md > <s>/A && tail -c +$(( $(wc -c < E) + 1 )) <s>/A | cmp - ARCHIVE.md && cp <s>/A ARCHIVE.md
```

## state check

ICM folders only. Each index's File/Entry column against its folder, and any `STATE.md` over 80 prose lines (not
the archive's); prints nothing when clean:
```sh
for D in F/_current/_decisions F/_current/_questions F/_implementation_plan F/_business F/_archive; do
  [ -d "$D" ] || continue
  awk -F' *\\| *' '!/^\|/ {c=0; next} /\| (File|Entry) \|/ {c=0; for(i=2;i<NF;i++) if($i=="File"||$i=="Entry") c=i; next} c && $c ~ /\.md$/ {print $c}' "$D/STATE.md" | LC_ALL=C sort > <s>/rows.txt
  (cd "$D" && find . -type f -name '*.md' ! -name STATE.md | sed 's|^\./||' | LC_ALL=C sort) > <s>/files.txt
  LC_ALL=C comm -3 <s>/rows.txt <s>/files.txt | sed "s|^|$D: |"
  [ "$D" = F/_archive ] || [ "$(grep -vc '^|' "$D/STATE.md")" -le 80 ] || echo "$D/STATE.md: over 80 prose lines"
done
[ "$(grep -vc '^|' F/_current/STATE.md)" -le 80 ] || echo "F/_current/STATE.md: over 80 prose lines"
```

## snapshot

A file, or a part (`sed -n 'A,Bp' FILE > <s>/src.md`), into an archive entry verbatim. Headings are demoted one
level outside ` ``` ` fences, so they do not collide with entry headings. Both `cmp` print nothing, else stop:
```sh
cp FILE <s>/src.md; [ -z "$(tail -c1 <s>/src.md)" ] || echo >> <s>/src.md
sed '/^```/,/^```/!s/^#/##/' <s>/src.md > <s>/body.md
sed '/^```/,/^```/!s/^##/#/' <s>/body.md | cmp - <s>/src.md
{ printf '## %s\n\n%s\n\n--- begin verbatim ---\n\n' "<date> — <file> cut: the whole pre-cut file, verbatim" "<why, counts>"
  cat <s>/body.md; printf -- '--- end verbatim ---\n\n'; } > <s>/entry.md
sed -n '/^--- begin verbatim ---$/,/^--- end verbatim ---$/p' <s>/entry.md | sed '1,2d;$d' | cmp - <s>/body.md
```

## heading keys

A file's section names, status suffixes ignored, for proving no section was lost (`comm -23 <old> <new>` prints
nothing):
```sh
sed '/^```/,/^```/d' FILE | grep '^#' | sed -E 's/^#+ *//; s/ — .*| ✅.*| ⛔.*| ⏸.*//' | LC_ALL=C sort -u > KEYS
```
