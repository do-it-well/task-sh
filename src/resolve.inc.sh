#!/bin/bash
_task_require resolver/command
_task_require run

# resolvers return a resolution
# the resolution is in the format:
# <number of arguments consumed by the resolution>
# +
# <resolver reference understood by the builtin resolver>
# +
# <resolver reference understood by whatever internal resolver>
_task_resolve() {
	if [[ $# -lt 1 ]]; then
		printf 'Nothing to resolve: No path passed to resolve\n' >&2
		return 1
	fi

	local resolvers
	IFS=: read -a resolvers <<<"${TASK_RESOLVERS:-0+_task_resolver_command}"
	local resolver

	for resolver in "${resolvers[@]}"; do
		if _task_run "${resolver}" resolve "$@"; then
			return 0
		fi
	done

	return 1
}
