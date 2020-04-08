#!/bin/bash
. ./test.inc.sh

_task_require resolver/command

test_expect_success 'run of an existing function should execute that function' '
	test_foo(){
		test_cmp 3 $# || return $?
		echo "[$1][$2][$3]"
	}
	local str="$( _task_resolver_command_run "c+test_foo" a b c )"
	test_cmp "[a][b][c]" "$str"
'

test_expect 'run of a nonexistant function should fail with code 255' '
	_task_resolver_command_run "test_nonexistant"
' '[[ $rc -eq 255 ]]'

test_expect_success 'match of existing function (test_foo_bar) should resolve successfully and consume 3 arguments' '
	task_test_foo_bar(){
		printf "MATCHED FUNCTION SHOULD NOT RUN" >&2
		return 1
	}
	local str="$( _task_resolver_command_resolve test foo bar )" || return $?
	test_cmp 3 "${str%%+*}" || return $?

	str="${str#3+}"
	test_cmp "_task_resolver_command" "${str%%+*}"

	str="${str#*+}"
	test_cmp "c+task_test_foo_bar" "$str"
'

test_expect 'match of nonexistant function (test_nonexistant) should fail with code 1' '
	_task_resolver_command_resolve test nonexistant
' '[[ $rc -eq 1 ]]'

test_expect_success 'match of function within include file should find that included function' '
	local str="$(
		TASK_COMMAND_ROOT="${BASH_SOURCE[0]%/*}/fixtures/command" \
		_task_resolver_command_resolve fixtures command a b c
	)" || return $?
	test_cmp 3 "${str%%+*}" || return $?

	str="${str#3+}"
	test_cmp "_task_resolver_command" "${str%%+*}" || return $?

	str="${str#*+}"
	test_cmp "i" "${str%%+*}" || return $?

	str="${str#*+}"
	test_cmp "${BASH_SOURCE[0]%/*}/fixtures/command/inc/fixtures/command.inc.sh" "${str%%+*}" || return $?

	str="${str#*+}"
	test_cmp "c" "${str%%+*}" || return $?

	str="${str#*+}"
	test_cmp "task_fixtures_command_a" "$str" || return $?
'

test_done
