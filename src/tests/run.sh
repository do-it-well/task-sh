#!/bin/bash
base="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
cd "$base"

TEST_TEMP="$(mktemp -d "$base/.run.XXXXXXXXXX")"
export TEST_TEMP
_test_cleanup(){ rm -rf "$TEST_TEMP"; }
trap _test_cleanup EXIT

failures=( )
TEST_FILE_SUCCESS_COUNT=0
TEST_FILE_FAIL_COUNT=0
TEST_FILE_RUN_COUNT=0
while read -r -d $'\0' testfile; do
	printf 'Running tests from %s...\n' "$testfile" >&2

	if ! bash "$testfile"; then
		rc=$?
		TEST_FILE_FAIL_COUNT=$(( TEST_FILE_FAIL_COUNT + 1 ))
		failures+=( "$testfile" )

		if [[ -n "$TEST_FAIL_FAST" ]]; then
			TEST_FILE_RUN_COUNT=$(( TEST_FILE_RUN_COUNT + 1 ))
			exit "$rc"
		fi
	else
		TEST_FILE_SUCCESS_COUNT=$(( TEST_FILE_SUCCESS_COUNT + 1 ))
	fi

	TEST_FILE_RUN_COUNT=$(( TEST_FILE_RUN_COUNT + 1 ))
done < <(find . '(' -name "${TEST_FILTER:-t*.sh}" -not -name '*.inc.sh' ')' -print0 | sort -z)


printf 'tests complete (%d/%d files ok)\n' "$TEST_FILE_SUCCESS_COUNT" "$TEST_FILE_RUN_COUNT" >&2
if [[ $TEST_FILE_FAIL_COUNT -eq 0 ]]; then
	exit 0
else
	printf 'failures in:\n' >&2;
	printf '  %s\n' "${failures[@]+${failures[@]}}" >&2
	exit 1
fi
