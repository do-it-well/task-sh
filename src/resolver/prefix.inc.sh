#!/bin/bash
_task_require resolve

_task_resolver_prefix() {
	local prefix=()
	local arg
	local args=( )
	local verb
	for arg in "$@"; do
		[[ "$arg" != "--" ]] || break
		prefix+=( "$arg" )
	done

	args=( "$@" )
	verb="${args[$(( ${#prefix[@]} + 1 ))]}"
	args=( "${args[@]:$(( ${#prefix[@]} + 2 ))}" )

	case "$verb" in
		resolve)
			local candidate_consumed
			local candidate_resolution
			if candidate_resolution="$( _task_resolve "${prefix[@]}" "${args[@]}" )"; then
				# prefixed resolutions must consume the entire prefix
				if [[ ${candidate_resolution%%+*} -ge ${#prefix[@]} ]]; then
					printf '%d+%s' $(( ${candidate_resolution%%+*} - ${#prefix[@]} )) "${candidate_resolution#*+}"
					return 0
				fi
			fi

			return 1
			;;
		run)
			printf '%s\n' "unexpectedly called run on a prefix" >&2
			return 1
			;;
	esac
}
