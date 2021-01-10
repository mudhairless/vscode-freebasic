#!/bin/bash
# Generate the multiple keyword lists: get full list from fbc sources,
# filter/split into categories based on the *.txt lists in this directory.
set -e

scriptdir="$(dirname "$0")"
fbc_srcdir="$(readlink -f "$scriptdir/../../fbc")"
tmpdir="$(mktemp -d)"

cat "$fbc_srcdir"/src/compiler/symb-keyword.bas | grep -P '\(.*@".*".*FB_TK_.*' | sed -e 's/^.*(.*@"\(.*\)".*FB_TK_.*/\1/g' | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u >"$tmpdir/generated-all-keywords-from-fbc.txt"
cat "$fbc_srcdir"/src/compiler/pp.bas           | grep -P '\(.*@".*".*FB_TK_.*' | sed -e 's/^.*(.*@"\(.*\)".*FB_TK_.*/\1/g' | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u >"$tmpdir/generated-preprocessor.txt"

for i in datatypes operators functions modifiers; do
	grep -v -e '^$' "$scriptdir/$i.txt" | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u >"$tmpdir/generated-$i.txt"
	cat "$tmpdir/generated-$i.txt" | while read ln; do echo "^$ln\$"; done >"$tmpdir/generated-$i-filter-list.txt"
done

cat "$tmpdir/generated-all-keywords-from-fbc.txt" | \
	grep -v \
		-f "$tmpdir/generated-datatypes-filter-list.txt" \
		-f "$tmpdir/generated-operators-filter-list.txt" \
		-f "$tmpdir/generated-functions-filter-list.txt" \
		-f "$tmpdir/generated-modifiers-filter-list.txt" \
		> "$tmpdir/generated-keywords.txt"

#sed -i -e 's/^/#/g' "$tmpdir/generated-preprocessor.txt"

for i in keywords preprocessor datatypes operators functions modifiers; do
	echo
	echo "$i:"
	cat "$tmpdir/generated-$i.txt" | while read i; do printf "%s|" "$i"; done | sed 's/.$//'
	echo
done

rm -rf "$tmpdir"
