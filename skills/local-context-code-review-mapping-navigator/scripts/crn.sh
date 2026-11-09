#!/usr/bin/env bash
# crn.sh — code review navigator worktrees for a CODE_REVIEW_MAPPING.md. Run from the project root.
#
#   crn.sh list    <map>                  numbered group headings (reviewed ones end with " ✅ reviewed")
#   crn.sh reviewed <map> <group>         marks the group reviewed in the map's heading, so a later session skips it
#   crn.sh prepare <map> <group>          per repo of the group: review worktree at the mapped merge base, the
#                                         group's files checked out (staged) from the mapped head; prints repo<TAB>worktree
#   crn.sh stage   <map> <repo> <path>... bring the mapped head version of files outside the group in, before editing them
#   crn.sh crn     <map>                  <crn> comments in the review edits, file:line:text
#   crn.sh status  <map>                  per review worktree: repo<TAB>worktree, then one line per pending review edit
#   crn.sh apply   <map>                  review edits -> each repo's checkout, then drops them from the worktrees
#   crn.sh cleanup <map>                  removes the review worktrees
#
# Baseline = the tree written by prepare (<worktree>.tree). Review edits = worktree + untracked files vs baseline,
# staged or not. Exit 2 = refused, nothing changed; exit 3 = a patch did not apply, kept next to its worktree.
set -euo pipefail

command=${1:?command}
map=${2:?map}
[ -f "$map" ] || { echo "no map: $map (usage: crn.sh $command <map> ..., the map always comes first)" >&2; exit 1; }
root=$(git rev-parse --show-toplevel)
root_name=$(basename "$root")
feature=$(basename "$(dirname "$map")")
worktrees_root=${LOCAL_CONTEXT_CRN_WORKTREES:-$HOME/.cache/local-context-crn}/$root_name/$feature

repo_names() { awk -F' *\\| *' 'NF > 7 && $5 ~ /^[0-9a-f]+$/ && $6 ~ /^[0-9a-f]+$/ {print $2}' "$map"; }
row_field() { awk -F' *\\| *' -v repo="$1" -v column="$2" '$2 == repo {print $column; exit}' "$map"; }
repo_dir() { if [ "$1" = "$root_name" ]; then echo "$root"; else echo "$root/$1"; fi; }

repo_of_path() {
  local first name
  case $1 in */*) first=${1%%/*} ;; *) echo "$root_name"; return ;; esac
  for name in $(repo_names); do [ "$name" = "$first" ] && [ "$name" != "$root_name" ] && { echo "$name"; return; }; done
  echo "$root_name"
}
relative_path() { if [ "$1" = "$root_name" ]; then echo "$2"; else echo "${2#"$1"/}"; fi; }

group_paths() { awk -v n="$1" '/^### /{i++} i==n && /^  - /{sub(/^  - /,""); print}' "$map"; }

existing_worktrees() { local name; for name in $(repo_names); do [ -f "$worktrees_root/$name.tree" ] && echo "$name"; done; true; }

pending_edits() {
  git -C "$1" diff --name-only "$(cat "$1.tree")"
  git -C "$1" ls-files -o --exclude-standard
}

case $command in
  list)
    awk '/^### /{i++; sub(/^### /,""); print i". "$0}' "$map"
    ;;

  reviewed)
    group=${3:?group number}
    awk -v n="$group" '/^### /{i++; if (i==n && $0 !~ / ✅ reviewed$/) $0=$0" ✅ reviewed"} {print}' "$map" > "$map.tmp"
    mv "$map.tmp" "$map"
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
