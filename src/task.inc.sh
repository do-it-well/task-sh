#!/bin/bash
_task_require resolve
_task_require run
_task_require msg

task() {
	local resolution

	if ! resolution="$( _task_resolve "$@" )"; then
		printf 'Unable to resolve %s\n' "$*" >&2
		return 1
	fi

	_task_run "$resolution" "$@"
}
