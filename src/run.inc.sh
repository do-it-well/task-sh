#!/bin/bash
_task_require envfile
_task_require msg
_task_run() {
	local full_resolution="$1"; shift
	local resolution="$full_resolution"
	local consumed
	local resolver

	if [[ "$resolution" = "${resolution#*+}" ]]; then
		_task_msg TRACE "invalid resolution '%s' passed to _task_run (consumed not specified)\n" "$full_resolution" >&2
		return 1
	fi
	consumed="${resolution%%+*}"
	resolution="${resolution#*+}"

	if [[ "$resolution" = "${resolution#*+}" ]]; then
		"$resolution" "${@:$(($consumed + 1))}"
		return $?
	fi

	resolver="${resolution%%+*}"
	resolution="${resolution#*+}"

	if [[ "$resolver" = "_" ]]; then
		_task_run_builtin "$resolution" "${@:$(($consumed + 1))}"
		return $?
	fi

	"$resolver" run "$resolution" "${@:$(($consumed + 1))}"
}

_task_run_builtin() {
	[[ $# -ge 1 ]] || return 1
	local resolution="$1"; shift;

	case "$resolution" in
		envfile)
			_task_envfile "$@"
			return $?
			;;
		msg)
			_task_msg "$@"
			return $?
			;;
	esac

	_task_msg TRACE "invalid resolution '$resolution' passed to _task_run_builtin"
	return 255
}
