#!/bin/bash
task_fixtures_command_a() {
	if [[ $# -lt 1 ]]; then
		printf 'ran task_fixtures_command_a without arguments\n'
		return 0
	fi

	printf 'ran task_fixtures_command_a with %d arguments: ' $#
	printf '[%s] ' "$@"
	printf '\n'
}
