#!/usr/bin/env bash
# crn.sh — code review navigator worktrees for a code review map. Run from the project root.
# <map> = .local_context/<feature>/_crm (ICM: STATE.md with the header and a Groups table, one file per group)
#      or .local_context/<feature>/CRM.md (legacy: one file, a "### " heading per group).
#
#   crn.sh list    <map>                  numbered group headings (reviewed ones end with " ✅ reviewed")
#   crn.sh reviewed <map> <group>         marks the group reviewed (ICM: its Status cell; legacy: its heading), so a
#                                         later session skips it
#   crn.sh prepare <map> <group>          per repo of the group: review worktree at the mapped merge base, the
#                                         group's files checked out (staged) from the mapped head; prints repo<TAB>worktree
#   crn.sh stage   <map> <repo> <path>... bring the mapped head version of files outside the group in, before editing them
#   crn.sh crn     <map>                  <crn> (code-review-note) comments in the review edits, file:line:text
#   crn.sh status  <map>                  per review worktree: repo<TAB>worktree, then one line per pending review edit
#   crn.sh apply   <map>                  review edits -> each repo's checkout (xplain notes stripped), then drops them
#                                         from the worktrees
#   crn.sh cleanup <map>                  removes the review worktrees, xplain notes and all
#
# Baseline = the tree written by prepare (<worktree>.tree). Review edits = worktree + untracked files vs baseline,
# staged or not. xplain notes are the agent's reading aids, never review edits, never applied: the added lines from
# one whose first non-blank text is a comment marker, a space and "<xplain>" to the first one holding "</xplain>".
# Exit 2 = refused, nothing changed; exit 3 = a patch did not apply, kept next to its worktree.
set -euo pipefail

command=${1:?command}
map=${2:?map}
map=${map%/}
dir=$(dirname "$map")
# layout: <feature>/.icm holds true (ICM) or false (legacy); without it, guessed from the map that exists
icm=$(cat "$dir/.icm" 2>/dev/null || true)
if [ ! -e "$map" ]; then
  if [ "$icm" != true ] && [ -f "$dir/CODE_REVIEW_MAPPING.md" ]; then
    echo "no map: $map, only the pre-2.0.0 $dir/CODE_REVIEW_MAPPING.md: regenerate it (local-context-code-review-mapping) or rename it to CRM.md" >&2
  elif [ "$icm" != false ] && [ -d "$dir/_crm" ]; then
    echo "no map: $map; this folder uses the ICM layout: pass $dir/_crm" >&2
  elif [ "$icm" != true ] && [ -f "$dir/CRM.md" ]; then
    echo "no map: $map; this folder uses the legacy layout: pass $dir/CRM.md" >&2
  else
    echo "no map: $map; run local-context-code-review-mapping first (usage: crn.sh $command <map> ..., the map always comes first)" >&2
  fi
  exit 1
fi
if [ -d "$map" ]; then
  case $map in _crm|*/_crm) ;; *) echo "not a map folder: $map; pass $map/_crm" >&2; exit 1 ;; esac
  header=$map/STATE.md
  [ -f "$header" ] || { echo "no $header: regenerate the map (local-context-code-review-mapping)" >&2; exit 1; }
else
  header=$map
fi
root=$(git rev-parse --show-toplevel)
root_name=$(basename "$root")
feature=$(basename "$(dirname "$map")")
worktrees_root=${LOCAL_CONTEXT_CRN_WORKTREES:-$HOME/.cache/local-context-crn}/$root_name/$feature

# the repo table has 6 columns, so 8 fields; the 4-column Groups table never matches
repo_names() { awk -F' *\\| *' 'NF > 7 && $5 ~ /^[0-9a-f]+$/ && $6 ~ /^[0-9a-f]+$/ {print $2}' "$header"; }
row_field() { awk -F' *\\| *' -v repo="$1" -v column="$2" 'NF > 7 && $2 == repo {print $column; exit}' "$header"; }
repo_dir() { if [ "$1" = "$root_name" ]; then echo "$root"; else echo "$root/$1"; fi; }

repo_of_path() {
  local first name
  case $1 in */*) first=${1%%/*} ;; *) echo "$root_name"; return ;; esac
  for name in $(repo_names); do [ "$name" = "$first" ] && [ "$name" != "$root_name" ] && { echo "$name"; return; }; done
  echo "$root_name"
}
relative_path() { if [ "$1" = "$root_name" ]; then echo "$2"; else echo "${2#"$1"/}"; fi; }

# ICM: the rows of the "## Groups" table in STATE.md, as <n><TAB><file><TAB><status>; n = row order
group_rows() { awk -F' *\\| *' '/^## /{in_groups = ($0 == "## Groups")} in_groups && $2 ~ /^[0-9]+$/ {print ++i "\t" $3 "\t" $5}' "$header"; }
group_file() { group_rows | awk -F'\t' -v n="$1" -v dir="$map" '$1 == n {print dir "/" $2}'; }

group_paths() {
  local file
  if [ -d "$map" ]; then
    file=$(group_file "$1")
    [ -n "$file" ] && [ -f "$file" ] || return 0
    awk '/^  - /{sub(/^  - /,""); print}' "$file"
  else
    awk -v n="$1" '/^### /{i++} i==n && /^  - /{sub(/^  - /,""); print}' "$map"
  fi
}

existing_worktrees() { local name; for name in $(repo_names); do [ -f "$worktrees_root/$name.tree" ] && echo "$name"; done; true; }

# Reads `git diff -U0 --no-prefix --no-renames <tree>`. Prints <line><TAB><file> per added line of an xplain note
# (line as in the worktree file), and <TAB><file> per file with any other text or mode change. A note not closed
# within its run of added lines is not a note: its lines count as review edits.
xplain_lines() {
  awk '
    function end_run() { if (open) other[file] = 1; n = 0; open = 0 }
    /^diff --git / {end_run(); header = 1; mode = 0; next}
    header && /^(old|new|deleted file|new file) mode / {mode = 1}
    # git ends a ---/+++ name holding a space with a tab
    header && /^--- / {file = substr($0, 5); sub(/\t$/, "", file); next}
    header && /^\+\+\+ / {if (substr($0, 5) != "/dev/null") { file = substr($0, 5); sub(/\t$/, "", file) }; next}
    /^@@/ {end_run(); header = 0; if (mode) other[file] = 1; split($3, start, ","); line = substr(start[1], 2); next}
    header {next}
    /^-/ {end_run(); other[file] = 1; next}
    /^\+/ {
      text = substr($0, 2)
      if (!open && text ~ /^[[:space:]]*[^[:alnum:][:space:]]+ <xplain>/) open = 1
      if (!open) other[file] = 1
      else {
        held[++n] = line
        if (index(text, "</xplain>")) { for (i = 1; i <= n; i++) print held[i] "\t" file; n = 0; open = 0 }
      }
      line++
    }
    END {end_run(); for (f in other) print "\t" f}'
}

# files with review edits: changed files, except those whose only changes are xplain notes; plus untracked files
pending_edits() {
  local tree
  tree=$(cat "$1.tree")
  git -C "$1" diff --name-only --no-renames "$tree" | grep -vxF -f <(
    git -C "$1" diff -U0 --no-prefix --no-renames "$tree" | xplain_lines |
      awk -F'\t' '$1 == "" {other[$2] = 1; next} {note[$2] = 1} END {for (f in note) if (!(f in other)) print f}'
  ) || true
  git -C "$1" ls-files -o --exclude-standard
}

case $command in
  list)
    if [ -d "$map" ]; then
      group_rows | while IFS="$(printf '\t')" read -r n file status; do
        heading=$(awk '/^### /{sub(/^### /,""); print; exit}' "$map/$file")
        case $status in *'✅ reviewed'*) heading="$heading ✅ reviewed" ;; esac
        echo "$n. $heading"
      done
    else
      awk '/^### /{i++; sub(/^### /,""); print i". "$0}' "$map"
    fi
    ;;

  reviewed)
    group=${3:?group number}
    if [ -d "$map" ]; then
      awk -F' *\\| *' -v n="$group" '/^## /{in_groups = ($0 == "## Groups")}
        in_groups && $2 ~ /^[0-9]+$/ && ++i == n {$0 = "| " $2 " | " $3 " | " $4 " | ✅ reviewed |"} {print}' "$header" > "$header.tmp"
      mv "$header.tmp" "$header"
    else
      awk -v n="$group" '/^### /{i++; if (i==n && $0 !~ / ✅ reviewed$/) $0=$0" ✅ reviewed"} {print}' "$map" > "$map.tmp"
      mv "$map.tmp" "$map"
    fi
    ;;

  prepare)
    group=${3:?group number}
    paths=$(group_paths "$group")
    [ -n "$paths" ] || { echo "group $group not found or empty" >&2; exit 1; }
    for name in $(existing_worktrees); do
      [ -z "$(pending_edits "$worktrees_root/$name")" ] || { echo "pending review edits in $worktrees_root/$name: apply or discard first" >&2; exit 2; }
    done
    repos=$(printf '%s\n' "$paths" | while IFS= read -r path; do repo_of_path "$path"; done | sort -u)
    for repo in $repos; do
      merge_base=$(row_field "$repo" 5)
      head=$(row_field "$repo" 6)
      [ -n "$merge_base" ] && [ -n "$head" ] || { echo "repo $repo not in the map header" >&2; exit 1; }
    done
    for repo in $repos; do
      merge_base=$(row_field "$repo" 5)
      head=$(row_field "$repo" 6)
      worktree=$worktrees_root/$repo
      if [ -d "$worktree" ]; then
        git -C "$worktree" checkout -q -f --detach "$merge_base"
        git -C "$worktree" clean -fdq
      else
        mkdir -p "$worktrees_root"
        git -C "$(repo_dir "$repo")" worktree add -q --detach "$worktree" "$merge_base"
      fi
      printf '%s\n' "$paths" | while IFS= read -r line; do
        [ "$(repo_of_path "$line")" = "$repo" ] || continue
        file=$(relative_path "$repo" "$line")
        case $file in
          *' (deleted)') git -C "$worktree" rm -q -- "${file% (deleted)}" ;;
          *' (renamed from '*)
            old=$(relative_path "$repo" "$(echo "$file" | sed -E 's/.* \(renamed from (.*)\)$/\1/')")
            git -C "$worktree" rm -q -- "$old"
            git -C "$worktree" checkout "$head" -- "${file%% (renamed from *}" ;;
          *) git -C "$worktree" checkout "$head" -- "$file" ;;
        esac
      done
      git -C "$worktree" write-tree > "$worktree.tree"
      printf '%s\t%s\n' "$repo" "$worktree"
    done
    ;;

  stage)
    repo=${3:?repo}; shift 3
    worktree=$worktrees_root/$repo
    [ -f "$worktree.tree" ] || { echo "no review worktree for $repo in this group" >&2; exit 2; }
    head=$(row_field "$repo" 6)
    for path in "$@"; do
      file=$(relative_path "$repo" "$path")
      [ -z "$(git -C "$worktree" diff --name-only "$(cat "$worktree.tree")" -- "$file")" ] || { echo "already edited: $file" >&2; exit 2; }
      git -C "$worktree" checkout "$head" -- "$file"
      GIT_INDEX_FILE="$worktree.index" git -C "$worktree" read-tree "$(cat "$worktree.tree")"
      git -C "$worktree" ls-tree "$head" -- "$file" | GIT_INDEX_FILE="$worktree.index" git -C "$worktree" update-index --index-info
      GIT_INDEX_FILE="$worktree.index" git -C "$worktree" write-tree > "$worktree.tree"
      rm -f "$worktree.index"
    done
    ;;

  crn)
    for name in $(existing_worktrees); do
      worktree=$worktrees_root/$name
      git -C "$worktree" add -N .
      git -C "$worktree" diff -U0 --no-prefix "$(cat "$worktree.tree")" | awk -v dir="$worktree" '
        /^\+\+\+ / {file=substr($0, 5); next}
        /^@@/ {split($3, start, ","); line=substr(start[1], 2); next}
        /^\+/ {if (index($0, "<crn>")) print dir "/" file ":" line ":" substr($0, 2); line++}'
    done
    ;;

  status)
    for name in $(existing_worktrees); do
      printf '%s\t%s\n' "$name" "$worktrees_root/$name"
      pending_edits "$worktrees_root/$name"
    done
    ;;

  apply)
    to_apply=
    for name in $(existing_worktrees); do
      worktree=$worktrees_root/$name
      [ -n "$(pending_edits "$worktree")" ] || continue
      git -C "$worktree" add -N .
      if git -C "$worktree" diff -U0 "$(cat "$worktree.tree")" | grep -q '^+.*<crn>'; then
        echo "<crn> comments left in $worktree: resolve them first" >&2; exit 2
      fi
      branch=$(row_field "$name" 3)
      [ "$(git -C "$(repo_dir "$name")" rev-parse --abbrev-ref HEAD)" = "$branch" ] || { echo "$(repo_dir "$name") is not on $branch" >&2; exit 2; }
      to_apply="$to_apply $name"
    done
    for name in $to_apply; do
      worktree=$worktrees_root/$name
      target=$(repo_dir "$name")
      # drop the xplain note lines added since the baseline, bottom up per file so line numbers hold
      git -C "$worktree" diff -U0 --no-prefix --no-renames "$(cat "$worktree.tree")" | xplain_lines |
        awk -F'\t' '$1 != ""' | sort -t"$(printf '\t')" -k2,2 -k1,1nr |
        while IFS="$(printf '\t')" read -r line file; do
          awk -v n="$line" 'NR != n' "$worktree/$file" > "$worktree.strip" && cat "$worktree.strip" > "$worktree/$file"
        done
      rm -f "$worktree.strip"
      git -C "$worktree" diff --binary "$(cat "$worktree.tree")" > "$worktree.patch"
      git -C "$target" apply "$worktree.patch" || git -C "$target" apply --3way "$worktree.patch" \
        || { echo "$name: not applied, review edits kept, patch kept: $worktree.patch" >&2; exit 3; }
      git -C "$worktree" diff --name-only "$(cat "$worktree.tree")" | sed "s|^|$name: |"
      git -C "$worktree" read-tree --reset -u "$(cat "$worktree.tree")"
      git -C "$worktree" clean -fdq
      rm "$worktree.patch"
    done
    ;;

  cleanup)
    for name in $(existing_worktrees); do
      [ -z "$(pending_edits "$worktrees_root/$name")" ] || { echo "pending review edits in $worktrees_root/$name" >&2; exit 2; }
    done
    for name in $(existing_worktrees); do
      git -C "$(repo_dir "$name")" worktree remove --force "$worktrees_root/$name"
      rm -f "$worktrees_root/$name.tree" "$worktrees_root/$name.patch"
    done
    rmdir "$worktrees_root" 2>/dev/null || true
    ;;

  *) echo "unknown command: $command" >&2; exit 1 ;;
esac
