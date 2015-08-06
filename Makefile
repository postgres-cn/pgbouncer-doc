
all: doc

clean:
	rm -rf _site

serve:
	bundle exec jekyll serve

# generate usage.md & config.md from rst files in pgbouncer repo

FIX = python _build/md-fix.py
DOC = ../pgbouncer/doc

doc:
	pandoc -f rst -t markdown < $(DOC)/config.rst | $(FIX) _build/frag-config-web > config.md
	pandoc -f rst -t markdown < $(DOC)/usage.rst | $(FIX) _build/frag-usage-web > usage.md
	pandoc -f rst -t markdown < $(DOC)/../NEWS.rst | $(FIX) _build/frag-changelog-web > changelog.md

