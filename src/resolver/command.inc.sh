#!/bin/bash
_task_require util/join

_task_resolver_command_fn_exists(){
  [[ "$(LC_ALL=C type -t "$1")" = "function" ]]
}

_task_resolver_command() {
	local verb="$1"; shift
	"_task_resolver_command_${verb}" "$@"
}

_task_resolver_command_resolve() {
	local candidate
	local found=
	local consumed=0
	local partial=( "$@" )
	local base="${BASH_SOURCE[${#BASH_SOURCE[@]}-1]%/*}"
	local root="${TASK_COMMAND_ROOT:-$base/tasks}"
	local includes=()

	while [[ ${#partial[@]} -gt 0 ]]; do
		candidate="$( _task_util_join / "${partial[@]}" )"
		if [[ -f "${root}/inc/${candidate}.inc.sh" ]]; then
			includes+=( "${root}/inc/${candidate}.inc.sh" )
			. "${root}/inc/${candidate}.inc.sh" || return 1
		fi

		if [[ -x "${root}/${candidate}" ]]; then
			printf '%d+%s+c+%s\n' "${#partial[@]}" _task_resolver_command "${root}/${candidate}"
			return 0
		fi

		partial=( "${partial[@]:0:$(( ${#partial[@]} - 1 ))}" )
	done

	local partial=( "$@" )
	while [[ ${#partial[@]} -gt 0 ]]; do
		candidate="task_$( _task_util_join _ "${partial[@]}" )"
		if _task_resolver_command_fn_exists "$candidate"; then
			found="$candidate"
			consumed=${#partial[@]}
			break
		fi

		partial=( "${partial[@]:0:$(( ${#partial[@]} - 1 ))}" )
	done

	if [[ -n "$found" ]]; then
		if [[ ${#includes[@]} -gt 0 ]]; then
			found="i+$(_task_util_join , "${includes[@]}")+c+$found"
		else
			found="c+$found"
		fi
		printf '%d+%s+%s\n' "$consumed" _task_resolver_command "$found"
		return 0
	fi
	return 1
}

_task_resolver_command_run() {
	local resolution="$1"; shift
	local full_resolution="$resolution"
	local includes_spec
	local includes=( )
	if [[ "${resolution#i+}" != "$resolution" ]]; then
		resolution="${resolution#i+}"
		includes_spec="${resolution%%+*}"
		resolution="${resolution#*+}"

		IFS=, read -a includes <<<"$includes_spec"
	fi

	local include
	if [[ ${#includes[@]} -gt 0 ]]; then
		for include in "${includes[@]}"; do
			if [[ -n "$include" ]]; then
				. "$include" || return 255
			fi
		done
	fi

	if [[ "${resolution#c+}" = "$resolution" ]]; then
		return 255
	fi
	resolution="${resolution#c+}"

	if [[ -x "$resolution" ]]; then
		command "${resolution}" "$@"
		return $?
	elif _task_resolver_command_fn_exists "${resolution}"; then
		"${resolution}" "$@"
		return $?
	fi

	return 255
}
