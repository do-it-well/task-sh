#!/bin/bash
_task_require msg
_task_run() {
	local full_resolution="$1"; shift
	local resolution="$full_resolution"
	local consumed
	local resolver

	if [[ "$resolution" = "${resolution#*+}" ]]; then
		printf "invalid resolution '%s' passed to _task_run (consumed not specified)\n" "$full_resolution" >&2
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
	"$resolver" run "$resolution" "${@:$(($consumed + 1))}"
}
