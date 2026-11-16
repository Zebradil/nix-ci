#!/usr/bin/env bash

# Render a Nix `json-log-path` log as a Markdown job summary: which substituter served how many
# paths and how many compressed bytes, the largest downloads, and what was built locally.
#
# The log is the `internal-json` activity stream. The parts used here:
#   start  type 108 (substitute)     fields [storePath, substituterUri]
#   start  type 100 (copy path)      child of a substitute
#   start  type 101 (file transfer)  fields [url]; a NAR download is a child of a copy path
#   start  type 105 (build)          fields [drvPath, machine, round, nrRounds]
#   result type 105 (progress)       fields [done, expected, running, failed]
#
# Both the daemon's connection workers and every client process append to the same file (Nix calls
# `applyJSONLogger` in each), so one event can appear twice, and Nix documents that concurrent
# writers may interleave records. Everything is therefore keyed by store path, bytes take the
# maximum seen, and lines that do not parse are dropped.
#
# Usage:
#   nix-log-summary.sh <log.jsonl>   print the Markdown summary
#   nix-log-summary.sh --self-test   run the assert-based self-check

set -euo pipefail

summarize() {
	# Activity ids are `pid << 32 | counter` and outgrow a double's 53-bit mantissa once pids pass
	# ~2M, which would merge neighbouring activities; quoting them keeps them exact.
	sed -E 's/"(id|parent)":([0-9]+)/"\1":"\2"/g' "$1" | jq -nrR '
		def hb:
			if . >= 1073741824 then "\(. / 1073741824 * 10 | round / 10) GiB"
			elif . >= 1048576 then "\(. / 1048576 * 10 | round / 10) MiB"
			elif . >= 1024 then "\(. / 1024 * 10 | round / 10) KiB"
			else "\(.) B" end;
		# /nix/store/<32-char hash>- is 44 characters.
		def name: .[44:];

		[inputs | fromjson? // empty | select(type == "object")] as $ev
		| ($ev | map(select(.action == "start") | {key: .id, value: .}) | from_entries) as $start
		| (reduce ($ev[] | select(.action == "result" and .type == 105)) as $r ({};
			.[$r.id] = ([.[$r.id] // 0, $r.fields[0]] | max))) as $done
		| def subst_of($id; $depth):
			$start[$id] as $a
			| if $a == null or $depth > 4 then null
			  elif $a.type == 108 then $a
			  else subst_of($a.parent; $depth + 1) end;

		($ev | map(select(.action == "start" and .type == 108)
			| {key: .fields[0], value: {source: .fields[1], bytes: 0}}) | from_entries) as $subst0
		| (reduce ($start[] | select(.type == 101 and (.fields[0] | test("/nar/")))) as $t ($subst0;
			subst_of($t.parent; 0) as $s
			| if $s == null then . else
				.[$s.fields[0]].bytes = ([.[$s.fields[0]].bytes, ($done[$t.id] // 0)] | max)
			  end)) as $subst
		| ($ev | map(select(.action == "start" and .type == 105) | .fields[0]) | unique) as $builds
		| ($subst | to_entries | map({path: .key} + .value)) as $paths

		| "### Nix downloads and builds\n",
		if ($paths | length) == 0 and ($builds | length) == 0 then
			"Nothing was downloaded or built."
		else
			"| Source | Paths | Downloaded |",
			"| --- | ---: | ---: |",
			($paths | group_by(.source)[]
				| "| `\(.[0].source)` | \(length) | \(map(.bytes) | add | hb) |"),
			"| **Built locally** | \($builds | length) | |",
			"",
			"Downloaded sizes are compressed NAR bytes.",
			if ($paths | length) > 0 then
				"",
				"<details><summary>Largest downloads</summary>\n",
				"| Path | Downloaded | Source |",
				"| --- | ---: | --- |",
				($paths | sort_by(-.bytes) | .[:20][]
					| "| `\(.path | name)` | \(.bytes | hb) | `\(.source)` |"),
				"\n</details>"
			else empty end,
			if ($builds | length) > 0 then
				"",
				"<details><summary>Built locally (\($builds | length))</summary>\n",
				($builds[] | "- `\(name)`"),
				"\n</details>"
			else empty end
		end
	'
}

self_test() {
	local dir log got
	dir=$(mktemp -d)
	trap 'rm -rf -- "$dir"' RETURN
	log="$dir/log.jsonl"
	local a=/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-foo-1.0
	local b=/nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-bar-2.0
	local d=/nix/store/dddddddddddddddddddddddddddddddd-baz-3.0.drv
	# foo comes from cache A in two NAR progress steps, and the daemon and client both logged it.
	# bar comes from cache B. Ids beyond 2^53 differ only in their low bits. The narinfo transfer
	# must not count, and neither must the interleaved garbage line.
	cat >"$log" <<-EOF
		{"action":"start","id":9007199254740993,"parent":0,"type":108,"fields":["$a","https://a.example"]}
		{"action":"start","id":9007199254740994,"parent":9007199254740993,"type":100,"fields":["$a"]}
		{"action":"start","id":9007199254740995,"parent":9007199254740994,"type":101,"fields":["https://a.example/nar/x.nar.zst"]}
		{"action":"result","id":9007199254740995,"type":105,"fields":[1000,0,0,0]}
		{"action":"result","id":9007199254740995,"type":105,"fields":[3145728,3145728,0,0]}
		{"action":"start","id":9007199254740993,"parent":0,"type":108,"fields":["$a","https://a.example"]}
		{"action":"start","id":9007199254740996,"parent":0,"type":101,"fields":["https://a.example/aaaa.narinfo"]}
		{"action":"result","id":9007199254740996,"type":105,"fields":[999999999,0,0,0]}
		{"action":"start","id":5,"parent":0,"type":108,"fields":["$b","https://b.example"]}
		{"action":"start","id":6,"parent":5,"type":100,"fields":["$b"]}
		{"action":"start","id":7,"parent":6,"type":101,"fields":["https://b.example/nar/y.nar.xz"]}
		{"action":"result","id":7,"type":105,"fields":[2048,2048,0,0]}
		{"action":"start","id":8,"parent":0,"type":105,"fields":["$d","",1,1]}
		{"action":"st{"action":"stop","id":8}
	EOF
	got=$(summarize "$log")
	local want
	# shellcheck disable=SC2016 # the backticks are Markdown, not command substitution
	for want in \
		'| `https://a.example` | 1 | 3 MiB |' \
		'| `https://b.example` | 1 | 2 KiB |' \
		'| **Built locally** | 1 | |' \
		'| `foo-1.0` | 3 MiB | `https://a.example` |' \
		'- `baz-3.0.drv`'; do
		[[ "$got" == *"$want"* ]] || { printf 'self-test FAILED, missing: %s\ngot:\n%s\n' "$want" "$got" >&2; return 1; }
	done
	# Largest download first.
	[[ "$got" == *'foo-1.0'*'bar-2.0'* ]] || { echo "self-test FAILED (download order)" >&2; return 1; }

	: >"$log"
	got=$(summarize "$log")
	[[ "$got" == *"Nothing was downloaded or built."* ]] || { echo "self-test FAILED (empty log)" >&2; return 1; }

	echo "self-test OK"
}

if [[ "${1:-}" == "--self-test" ]]; then
	self_test
	exit $?
fi

summarize "${1:?usage: nix-log-summary.sh <log.jsonl>|--self-test}"
