#!/bin/bash

_task_msg(){
	{
		local message_level_label="${1}"; shift
		local message_level=-1
		local message_area
		local area
		local areaok=1
		local trace=0
		local exit=0
		case "${message_level_label^^}" in
			BUG)
				message_level=-1
				trace=1
				exit=1
				;;
			ERROR)
				message_level=0
				;;
			WARN)
				message_level=1
				;;
			INFO)
				message_level=2
				;;
			DEBUG|DEBUG0|DEBUG1)
				message_level=3
				;;
			DEBUG*)
				message_level_label="${message_level_label^^}"
				message_level=$(( 3 + $(printf '%d\n' "${message_level_label#DEBUG}" 2>&-) - 1 ))
				;;
			TRACE|DEV|DEV-*)
				if [[ "$message_level_label" = "TRACE" ]]; then
					trace=1
				fi

				message_level_label="${message_level_label^^}"
				message_area=
				if [[ "$message_level_label" = "DEV" ]] || [[ "$message_level_label" = "TRACE" ]]; then
					message_area="${BASH_SOURCE[1]##*/}"
					message_area="${message_area%%.*}"
				else
					message_area="${message_level_label#DEV-}"
				fi
				message_area="${message_area^^}"

				areaok=0
				if [[ -z "${TASK_VERBOSE_AREA:-}" ]] || [[ -z "$message_area" ]]; then
					areaok=1
				else
					while read -d : -r area; do
						if [[ "${area^^}" = "$message_area" ]]; then
							areaok=1
							break
						fi
					done <<<"${TASK_VERBOSE_AREA:-}:"
				fi
				;;
		esac

		if [[ $exit -lt 1 ]]; then
			if [[ "${-/x/}" != "$-" ]] ||
			   [[ $(printf '%d' "$TASK_VERBOSE" 2>&-) -lt $message_level ]] ||
			   [[ $areaok -lt 1 ]]
			then
				return 0
			fi
		fi
	} 2>&-

	local runlvl="$(printf '%d' 2>&- "${TASK_RUN_LEVEL:-0}")"
	local indent=
	if [[ $runlvl -gt 1 ]]; then
		indent="$( eval "printf ' %.0s' {1..$runlvl}" )"
		printf '%s' "$indent" >&2
	fi

	if [[ "${message_level_label^^}" = "DEV" ]] || [[ "${message_level_label^^}" = "TRACE" ]]; then
		printf '[%s] ' "$(_task_trace -2)" >&2
	elif [[ $message_level -lt 0 ]]; then
		printf '%s ' "$message_level_label" >&2
	else
		printf '[%s] ' "${message_level_label^^}" >&2
	fi

	printf '%s\n' "$*" >&2

	if [[ $trace -gt 0 ]]; then
		printf '%sfrom: \n' "$indent" >&2
		_task_trace 3 "  $indent" >&2
	fi

	if [[ $exit -gt 0 ]]; then
		exit 255
	fi
}

_task_trace(){
	local start="$( printf '%d' "${1:-1}" 2>&- )"
	local single=0
	if [[ $start -lt 0 ]]; then
		single=1
		start=$(( $start * -1 ))
	fi

	local do_args=0
	local argo=0
	local argc=0
	local argn=0
	local argv=( )
	local frame
	if [[ $single -lt 1 ]] && shopt extdebug | grep -q on; then
		do_args=1
		local frame=0 # frame 0 is the current function call
		while [[ $frame -lt $(( start - 1 )) ]]; do
			argc=${BASH_ARGC[((frame))]}
			argo=$(( argo + argc ))
			frame=$(( frame + 1 ))
		done
		frame=$(( frame + 1 ))
	else
		local frame=0
		frame="$start"
	fi

	local indent="${2:-}"
	while [[ $frame -lt ${#FUNCNAME[@]} ]]; do
		local function
		if [[ $single -eq 1 ]]; then
			# when asking for a single line, we care about what function we are in,
			# not what we are calling (because what we are calling is trace itself)
			function="${FUNCNAME[(( frame ))]:-MAIN}"
		else
			function="${FUNCNAME[(( frame - 1 ))]:-MAIN}"
		fi
		if [[ $frame -gt 0 ]] && [[ $do_args -gt 0 ]]; then
			argc=${BASH_ARGC[((frame - 1))]}

			if [[ $argc -gt 0 ]]; then
				argn=$argc
				argv=( )
				while [[ $argn -gt 0 ]]; do
					argv+=( "${BASH_ARGV[(argo+argn-1)]}" )
					argn=$(( $argn - 1 ))
				done

				function="${function} $( printf '%q ' "${argv[@]}")"
			else
				function="${function}"
			fi
			argo=$(( argo + argc ))
		fi
		local line="${BASH_LINENO[(( frame - 1 ))]}"
		local file="${BASH_SOURCE[$frame]:-eval}"; file="${file##*/}"

		if [[ $single -ne 1 ]]; then
			printf '%s%3d: ' "$indent" $(( $frame - $start + 1 ))
		fi
		printf '%s:%d %s\n' "$file" "$line" "$function"
		frame=$(( frame + 1 ))

		if [[ $single -eq 1 ]]; then
			break
		fi
	done
}
