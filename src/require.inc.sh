#!/bin/bash
TASK_INCLUDED=require
_task_require(){
	local base="${BASH_SOURCE[0]%/*}"
	local check=":${TASK_INCLUDED}:"
	local component
	local rc=
	for component in "$@"; do
		if [[ "${check/:$component:/}" = "$check" ]]; then
			TASK_INCLUDED="${TASK_INCLUDED}:$component"

			. "$base/${component}.inc.sh"
			rc="$?"
			if [[ "$rc" != 0 ]]; then
				TASK_INCLUDED="${TASK_INCLUDED%:*}"
				return "$rc"
			fi
		fi
	done

	return 0
}
