#!/bin/bash
_task_require run

_task_resolver_depth() {
	local verb="$1"; shift
	"_task_resolver_depth_${verb}" "$@"
}

_task_resolver_depth_resolve() {
	if [[ $# -lt 1 ]]; then
		printf 'Nothing to resolve: No path passed to _task_resolver_depth_resolve\n' >&2
		return 1
	fi

	local resolvers
	IFS=: read -a resolvers <<<"${TASK_RESOLVERS:-0+_task_resolver_command}"
	local resolver
	local candidate_consumed
	local candidate_resolution
	local consumed=0
	local resolution

	for resolver in "${resolvers[@]}"; do
		if candidate_resolution="$( _task_run "${resolver}" resolve "$@" )"; then
			candidate_consumed="${candidate_resolution%%+*}"
			if ! printf '%d' "$candidate_consumed" >/dev/null 2>&1; then
				printf 'Invalid resolution [%s] (missing "consumed" component) returned by %s resolver\n' "$candidate_resolution" "$resolver" >&2
				continue
			fi

			if [[ $candidate_consumed -gt $consumed ]]; then
				consumed="$candidate_consumed"
				resolution="$candidate_resolution"
			fi
		fi
	done

	if [[ $consumed -gt 0 ]]; then
		printf '%d+%s\n' "$consumed" "${resolution#*+}"
		return 0
	fi
	return 1
}

_task_resolver_depth_run() {
	printf '%s\n' "unexpectedly called run on a depth-first resolution" >&2
	return 1
}
