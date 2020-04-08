#!/bin/bash
. ./test.inc.sh

_task_require resolver/depth
_task_require resolver/prefix
_task_require resolver/command

test_expect_success 'resolve of a depth-first resolution should return the longest per-resolver match' '
	test_a() {
		echo 1+mid+extraArgs
	}

	test_b() {
		echo 2+longest+extraArgs
	}

	test_c() {
		echo 0+shortest+extraArgs
	}

	str="$(
		TASK_RESOLVERS=0+test_a:0+test_b:0+test_c \
			_task_resolver_depth resolve a b c
	)"

	test_cmp "2+longest+extraArgs" "$str"
'

test_done
