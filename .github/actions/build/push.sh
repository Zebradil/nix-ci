#!/usr/bin/env bash
# Push the store paths listed in a file to the binary cache at CACHE_URL.
#
#   push.sh <paths-file>
#   push.sh --self-test
#
# Environment: CACHE_URL (s3:// or http(s)://), STORE_PARAMS, CACHE_TOKEN (http(s) only),
# NIX_CI_STORE (remote store the paths were built in), AWS_* for S3.
set -euo pipefail

with_param() {
	case "$1" in
	*\?*) printf '%s&%s' "$1" "$2" ;;
	*) printf '%s?%s' "$1" "$2" ;;
	esac
}

cache_host() {
	local host="${1#*://}"
	host="${host%%[/?]*}"
	host="${host##*@}"
	if [[ "$host" == \[* ]]; then
		host="${host#\[}"
		printf '%s' "${host%%]*}"
	else
		printf '%s' "${host%%:*}"
	fi
}

self_test() {
	[[ "$(with_param https://box a=1)" == 'https://box?a=1' ]] || { echo "self-test FAILED (first param)" >&2; return 1; }
	[[ "$(with_param 's3://b?region=x' a=1)" == 's3://b?region=x&a=1' ]] || { echo "self-test FAILED (second param)" >&2; return 1; }
	[[ "$(cache_host 'https://box.lan:5000/x?y=1')" == 'box.lan' ]] || { echo "self-test FAILED (host with port)" >&2; return 1; }
	[[ "$(cache_host 'https://box.lan?y=1')" == 'box.lan' ]] || { echo "self-test FAILED (host with query)" >&2; return 1; }
	[[ "$(cache_host 'https://u:p@box.lan/x')" == 'box.lan' ]] || { echo "self-test FAILED (host with userinfo)" >&2; return 1; }
	[[ "$(cache_host 'https://[fd00::1]:5000/x')" == 'fd00::1' ]] || { echo "self-test FAILED (IPv6 host)" >&2; return 1; }
	echo "self-test OK"
}

if [[ "${1:-}" == "--self-test" ]]; then
	self_test
	exit $?
fi

paths_file="${1:?usage: push.sh <paths-file>|--self-test}"
url="${CACHE_URL:?}"

# Store settings ride on the URL: `compression` and `secret-key` are BinaryCacheStore settings, so
# they can only be set as query parameters — `--option compression zstd` is silently ignored. A URL
# that names a compression of its own is left alone.
if [[ -n "${STORE_PARAMS:-}" && "$url" != *compression=* ]]; then
	url="$(with_param "$url" "$STORE_PARAMS")"
fi

args=(copy)
if [[ -n "${NIX_CI_STORE:-}" ]]; then
	args+=(--from "$NIX_CI_STORE")
fi

# Sign on the way out with setup-nix's key. `secret-key-files` signs only in a store whose daemon
# reads this machine's nix.conf as a trusted user; a remote store's daemon, or a local daemon the
# runner is not trusted by, signs nothing. Signing at the copy covers every setup, and substituted
# paths get the signature too.
key="$(nix config show secret-key-files | awk '{print $1}')"
if [[ -n "$key" ]]; then
	url="$(with_param "$url" "secret-key=$key")"
fi

if [[ -n "${CACHE_TOKEN:-}" ]]; then
	# A kasha box takes its write token as the netrc password, under any login. Scoped to the
	# cache's host so the token never reaches a substituter.
	netrc="${RUNNER_TEMP:?}/nix-ci-push.netrc"
	(
		umask 077
		printf 'machine %s login nix password %s\n' "$(cache_host "$CACHE_URL")" "$CACHE_TOKEN" >"$netrc"
	)
	args+=(--option netrc-file "$netrc")
fi

# xargs feeds the paths in batches: a system closure overflows the argument limit.
# `< file` rather than `-a file`: BSD xargs on the macOS runners has no -a.
xargs <"$paths_file" nix "${args[@]}" --to "$url"
