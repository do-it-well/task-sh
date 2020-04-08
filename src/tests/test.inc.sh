#!/bin/bash
set -euo pipefail
shopt -s extdebug
. "${BASH_SOURCE[0]%/*}"/../require.inc.sh

FUNCNEST=1000
TEST_SUCCESS_COUNT=0
TEST_FAIL_COUNT=0
TEST_RUN_COUNT=0
TEST_FAIL_FAST="${TEST_FAIL_FAST:-0}"
TEST_NOISY="${TEST_NOISY:-0}"
TEST_VERBOSE="${TEST_VERBOSE:-0}"

test_temp(){
	if [[ $# -lt 1 ]] || [[ -z "$1" ]]; then
		printf 'test_temp called without filename\n' >&2
		return 1
	fi

	local file="$1"
	local temp="${TEST_TEMP:-}"
	if [[ -z "$temp" ]] || [[ ! -d "$temp" ]] || [[ ! -w "$temp" ]]; then
		base="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
		temp="$(mktemp -d "$base/.test.XXXXXXXXXX")"
		if [[ -z "${temp}" ]]; then
			printf 'Failed to create temporary directory for testing\n' >&2
			exit 1
		fi

		export TEST_TEMP="$temp"
		_test_cleanup(){ [[ -z "$TEST_TEMP" ]] || rm -rf "$TEST_TEMP"; }
		trap _test_cleanup EXIT
	fi

	if [[ -z "$temp" ]]; then
		printf 'Sanity check failed: $temp is empty?\n' >&2
		return 1
	fi

	export TEST_FILE_TEMP="$temp/$1"
	mkdir -p "$TEST_FILE_TEMP"
}

if [[ ${#BASH_SOURCE[@]} -gt 1 ]]; then
	test_temp "${BASH_SOURCE[1]%.sh}"
fi

test_cmp(){
	if [[ "$1" = "$2" ]]; then
		return 0
	else
		printf 'FAIL: expected %q vs actual %q\n' "$1" "$2" >&2
		return 1
	fi
}

test_eval_inner(){
	eval "$*" 2>&1
}

test_eval(){
	local rc
	local code="$1";
	local lead=
	local tail=
	if [[ $(printf '%d\n' "$TEST_VERBOSE" 2>&-) -gt 0 ]]; then
		lead='
			PS4='\''+[${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]}] '\''
			set -x;
		'
		tail='
		{ local rc=$?; set +x; } 2>&-
		return $rc'
	fi

	local oldPS4="$PS4"
	test_eval_inner "$lead $code $tail"
	rc=$?
	PS4="$oldPS4"
	return $rc
}

test_check(){
	local output="$1"; shift
	local rc="$1"; shift
	eval "$*"
}

test_expect(){
	local label="$1"; shift
	local code="$1"; shift
	local check
	if [[ $# -gt 0 ]]; then
		check="$1"; shift
	else
		check='[[ $rc -eq 0 ]]'
	fi
	local output
	local check_output
	local e=0
	local rc

	if [[ "${-/e/}" != "$-" ]]; then
		e=1
		set +e
	fi

	output="$(
		{
			test_eval "$code"
		} | {
			if [[ $(printf '%d\n' "$TEST_NOISY" 2>&-) -gt 0 ]]; then
				tee -a /dev/stderr || true
			else
				cat
			fi
		}

		return ${PIPESTATUS[0]}
	)"
	rc=$?

	if [[ $e -gt 0 ]]; then
		set -e
	fi

	printf '  %s: ' "$label" >&2
	if check_output="$(test_check "$output" "$rc" "$check" 2>&1)"; then
		printf 'ok\n' >&2
		TEST_SUCCESS_COUNT=$(( TEST_SUCCESS_COUNT + 1 ))
	else
		printf 'fail\n' >&2
		[[ -z "$output" ]] || printf '%s\n' "$output" >&2
		[[ -z "$check_output" ]] || printf '%s\n' "$check_output" >&2
		TEST_FAIL_COUNT=$(( TEST_FAIL_COUNT + 1 ))
		if [[ -n "$TEST_FAIL_FAST" ]]; then
			TEST_RUN_COUNT=$(( TEST_RUN_COUNT + 1 ))
			test_done
			exit $?
		fi
	fi

	TEST_RUN_COUNT=$(( TEST_RUN_COUNT + 1 ))
}

test_expect_success(){
	test_expect "$1" "$2"
}

test_expect_failure(){
	test_expect "$1" "$2" '[[ $rc -ne 0 ]]'
}

test_done(){
	if [[ -n "${TEST_FILE_TEMP:-}" ]]; then
		rm -rf "${TEST_FILE_TEMP}"
	fi

	printf '  tests complete (%d/%d ok)\n' "$TEST_SUCCESS_COUNT" "$TEST_RUN_COUNT" >&2
	if [[ $TEST_FAIL_COUNT -eq 0 ]]; then
		return 0
	else
		return 1
	fi
}
