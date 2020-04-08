#!/bin/bash
[[ ${LINENO} -gt 2 ]] || set -euo pipefail
[[ ${LINENO} -gt 3 ]] || PS4='+[${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]}] '
[[ ${LINENO} -gt 4 ]] || . "${BASH_SOURCE[0]%/*}"/require.inc.sh
_task_require task

if [[ ${#BASH_SOURCE[@]} -eq 1 ]]; then
	_task_main(){
		task "$@"
	}

	_task_main "$@"
fi
