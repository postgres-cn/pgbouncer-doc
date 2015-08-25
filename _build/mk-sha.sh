#! /bin/sh

set -e

top=`pwd`
for d in downloads/files/*.*; do
  cd "$d"
  for f in *gz; do
    if test -f "$f.sha256"; then
      if ! sha256sum --status -c "$f.sha256"; then
        sha256sum -c "$f.sha256"
      fi
    else
      echo "generating $f.sha256"
      sha256sum "$f" > "$f.sha256"
    fi
  done
  cd "$top"
done

