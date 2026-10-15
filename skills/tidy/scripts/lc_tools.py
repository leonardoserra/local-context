#!/usr/bin/env python3
"""Safe, verifiable edits for .local_context/<feature>/ markdown files.

  snapshot SRC OUT --title T --reason R [--lines A:B]
      Write an ARCHIVE entry holding SRC (or lines A..B, 1-based inclusive) verbatim, markdown
      headings outside code fences demoted one level, then prove it round-trips to the source.
  prepend ENTRY ARCHIVE
      Put ENTRY at the top of ARCHIVE (newest first) and prove the old ARCHIVE is intact below it.
  headings OLD NEW
      List section headings present in OLD and missing from NEW (status suffixes ignored).
  refs PLAN CURRENT [--repoint LABEL]
      List every "`CURRENT.md` § X" in PLAN whose X is not a heading of CURRENT; with --repoint,
      rewrite those to "`ARCHIVE.md` (LABEL) § X".

Every command exits non-zero on a failed check, so nothing silently half-works.
"""
import argparse, re, sys

def read_lines(path):
    return open(path, encoding='utf-8').read().split('\n')

def demote(lines, direction):
    out, fence = [], False
    for line in lines:
        if line.startswith('```'):
            fence = not fence
            out.append(line)
        elif not fence and line.startswith('#'):
            out.append('#' + line if direction > 0 else line[1:])
        else:
            out.append(line)
    return out

BEGIN, END = '--- begin verbatim ---', '--- end verbatim ---'

def snapshot(args):
    source = read_lines(args.src)
    if args.lines:
        first, last = (int(n) for n in args.lines.split(':'))
        source = source[first - 1:last]
    entry = [f'## {args.title}', '', args.reason, '', BEGIN, ''] + demote(source, +1) + [END, '', '']
    open(args.out, 'w', encoding='utf-8').write('\n'.join(entry))
    written = read_lines(args.out)
    block = written[written.index(BEGIN) + 2:written.index(END)]
    if demote(block, -1) != source:
        sys.exit('FAIL: snapshot does not round-trip to the source')
    print(f'OK snapshot: {len(source)} lines, round-trip exact -> {args.out}')

def prepend(args):
    entry = open(args.entry, encoding='utf-8').read()
    archive = open(args.archive, encoding='utf-8').read()
    open(args.archive, 'w', encoding='utf-8').write(entry + archive)
    if open(args.archive, encoding='utf-8').read()[len(entry):] != archive:
        sys.exit('FAIL: old ARCHIVE content changed')
    print(f'OK prepend: old ARCHIVE intact below the new entry ({args.archive})')

def heading_keys(path):
    keys, fence = [], False
    for line in read_lines(path):
        if line.startswith('```'):
            fence = not fence
        elif not fence and line.startswith('#'):
            keys.append(re.split(r' — | ✅| ⛔| ⏸', line.lstrip('#').strip())[0])
    return keys

def headings(args):
    old, new = heading_keys(args.old), set(heading_keys(args.new))
    missing = [key for key in old if key not in new]
    print(f'{len(old)} headings before, {len(new)} after, {len(missing)} missing')
    for key in missing:
        print('MISSING:', key)
    sys.exit(1 if missing else 0)

def refs(args):
    targets = heading_keys(args.current)
    text = open(args.plan, encoding='utf-8').read()
    pattern = re.compile(r'`CURRENT\.md` § ')
    pieces, position, unresolved = [], 0, []
    for match in pattern.finditer(text):
        ref = re.split(r'[|;,)]| \(|\. |\*\*|\n', text[match.end():match.end() + 120])[0].strip().rstrip('.')
        resolves = any(t.startswith(ref) or ref.startswith(t) for t in targets if t)
        pieces.append(text[position:match.start()])
        if resolves or not args.repoint:
            pieces.append(match.group(0))
        else:
            pieces.append(f'`ARCHIVE.md` ({args.repoint}) § ')
        if not resolves:
            unresolved.append(ref)
        position = match.end()
    pieces.append(text[position:])
    for ref in sorted(set(unresolved)):
        print('UNRESOLVED:', ref)
    if args.repoint:
        open(args.plan, 'w', encoding='utf-8').write(''.join(pieces))
        print(f'OK refs: {len(unresolved)} repointed to ARCHIVE ({args.repoint})')

parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
commands = parser.add_subparsers(dest='command', required=True)
p = commands.add_parser('snapshot'); p.add_argument('src'); p.add_argument('out')
p.add_argument('--title', required=True); p.add_argument('--reason', required=True); p.add_argument('--lines')
p.set_defaults(run=snapshot)
p = commands.add_parser('prepend'); p.add_argument('entry'); p.add_argument('archive'); p.set_defaults(run=prepend)
p = commands.add_parser('headings'); p.add_argument('old'); p.add_argument('new'); p.set_defaults(run=headings)
p = commands.add_parser('refs'); p.add_argument('plan'); p.add_argument('current'); p.add_argument('--repoint')
p.set_defaults(run=refs)
arguments = parser.parse_args()
arguments.run(arguments)
