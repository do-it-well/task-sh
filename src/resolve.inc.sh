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

	if [[ "$1" = '_' ]] && [[ $# -gt 1 ]]; then
		_task_resolve_builtin "${@:2}" || return 1
		return 0
	fi

	local resolvers
	local resolvers_env
	resolvers_env="${TASK_RESOLVERS:-}"
	while [[ "${resolvers_env#:}" != "${resolvers_env}" ]]; do
		resolvers_env="${resolvers_env#:}"
	done
	while [[ "${resolvers_env%:}" != "${resolvers_env}" ]]; do
		resolvers_env="${resolvers_env%:}"
	done
	if [[ -z "$resolvers_env" ]]; then
		resolves_env='0+_task_resolver_command'
	fi

	IFS=: read -a resolvers <<<"${resolvers_env}"
	local resolver

	for resolver in "${resolvers[@]}"; do
		[[ -n "$resolver" ]] || continue
		if _task_run "${resolver}" resolve "$@"; then
			return 0
		fi
	done

	return 1
}

_task_resolve_builtin() {
	[[ $# -ge 1 ]] || return 1

	case "$1" in
		envfile)
			printf '%d+%s+%s' 2 _ envfile
			return 0
			;;
		msg)
			printf '%d+%s+%s' 2 _ msg
			return 0
			;;
		resolve)
			printf '%d+%s+%s' 2 _ resolve
			return 0
			;;
		run)
			printf '%d+%s+%s' 2 _ run
			return 0
			;;
	esac

	return 1
}
