#!/bin/bash

_task_util_join(){
	local glue="$1"; shift;
	local joined="$( printf "${glue//%/%%}%s" "$@" )"
	printf '%s' "${joined#$glue}"
}
