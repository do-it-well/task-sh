#!/bin/bash
. ./test.inc.sh

_task_require resolver/command
_task_require resolver/prefix

test_expect_success 'resolve of a prefixed function should return a resolution which takes that prefix into account' '
	task_foo_bar_test() {
		echo should not run
		return 1
	}

	str="$(
		TASK_RESOLVERS=0+_task_resolver_command \
			_task_resolver_prefix foo bar -- resolve test foo
	)"

	test_cmp "1+_task_resolver_command+c+task_foo_bar_test" "$str"
'

test_expect_success 'resolve of a prefixed function should return a resolution which takes that prefix into account' '
	task_foo_bar_test_a_b() {
		echo should not run
		return 1
	}

	str="$(
		TASK_RESOLVERS=0+_task_resolver_command \
			_task_resolver_prefix foo bar -- resolve test a b foo
	)"

	test_cmp "3+_task_resolver_command+c+task_foo_bar_test_a_b" "$str"
'

test_done
