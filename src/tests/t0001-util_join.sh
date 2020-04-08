#!/bin/bash
. ./test.inc.sh

_task_require util/join
test_expect_success 'join glues together arguments' '
	str="$(_task_util_join / 1 2 3)"
	test_cmp "1/2/3" "$str"
'

test_expect_success 'join glues together blank arguments' '
	str="$(_task_util_join / 1 "" 2)"
	test_cmp "1//2" "$str"
'

test_expect_success 'join does not do anything to a single argument' '
	str="$(_task_util_join / 1)"
	test_cmp "1" "$str"
'

test_expect_success 'join without arguments returns an empty string' '
	str="$(_task_util_join /)"
	test_cmp "" "$str"
'

test_done
