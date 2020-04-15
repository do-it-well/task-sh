#!/bin/bash
_task_envfile(){
	local outer=( )
	if [[ "$1" = "--no-redeclare" ]]; then
		shift
		while read -r -d $'\0' env; do
			outer+=( "${env%%=*}" )
		done < <( env -0 )
	fi

	local file
	local env
	local ignore
	local do_ignore
	for file in "$@"; do
		file="$( _task_envfile_subst "$file" )"
		[[ -r "$file" ]] || continue

		while read -r -d $'\0' env; do
			do_ignore=0
			for ignore in "${outer[@]}"; do
				if [[ "$ignore" = "${env%%=*}" ]]; then
					do_ignore=1
					break
				fi
			done

			if [[ $do_ignore -ne 1 ]]; then
				declare -g -x "$env"
			fi
		done < <(
			env -i "${SHELL}" -c 'set -a; source "$1"; env -0' -- "$file"
		)
	done
}

_task_envfile_subst(){
	local str="$1"
	local lead
	local tail
	local minuslead
	local curlyvar
	local var

	local gaurd=
	while [[ "$str" != "${str%\{*\}*}" ]] && [[ "$gaurd" != "$str" ]]; do
		lead="${str%\{*\}*}"
		minuslead="${str#$lead}"
		tail="${minuslead#*\}}"
		curlyvar="${minuslead%$tail}"
		var="${curlyvar#\{}"; var="${var%\}}";

		gaurd="$str"
		str="${str//$curlyvar/${!var:-}}"
	done
	printf '%s' "$str"
}
