#! /usr/bin/env python

"""Postprocess pandoc rst2md output to something sane.
"""

import sys, re

# rst: `Foo bar`_ -> md: [Foo bar](#foo-bar)
def fixlink(m):
    txt = m.group(1)
    ref = txt.lower().replace(' ', '-')
    return '[%s](#%s)' % (txt, ref)

for fn in sys.argv[1:]:
    sys.stdout.write(open(fn, 'r').read())

for ln in sys.stdin:
    ln = ln.replace('\\', '')               # pandoc is overeager with \
    ln = ln.replace('~', '-')               # '-' looks better than '~'
    ln = re.sub(r'`([^`]+)`_', fixlink, ln) # fix local links
    sys.stdout.write(ln)

