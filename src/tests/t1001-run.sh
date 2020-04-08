#!/bin/bash
. ./test.inc.sh

_task_require run

test_expect_success 'run without resolution calls resolver directly' '
	test_foo(){
		if [[ $# -ne 2 ]]; then
			printf "!=2: [%s]\n" "$*"
			return 1
		fi

		printf "1:%s;2:%s;\n" "$1" "$2"
		return 0
	}

	str="$(_task_run 0+test_foo a b)"
	test_cmp "1:a;2:b;" "$str"
'

test_expect_success 'run with resolution calls run on the resolver' '
	test_foo(){
		if [[ $# -ne 4 ]]; then
			printf "!=4: [%s]\n" "$*"
			return 1
		fi

		printf "1:%s;2:%s;3:%s;4:%s;\n" "$1" "$2" "$3" "$4"
		return 0
	}

	str="$(_task_run 0+test_foo+abc a b)"
	test_cmp "1:run;2:abc;3:a;4:b;" "$str"
'

test_done
