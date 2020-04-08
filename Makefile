dist/task: src/*.inc.sh src/util/*.inc.sh src/resolver/*.inc.sh src/task.sh
	mkdir -p "$(@D)"
	printf '#!/bin/bash\n_task_require(){ :; }\n' > "$@"
	sed \
		-e '/^#!\/bin\/bash/d' \
		-e 's/_task_msg \(DEV\|TRACE\)/true \1/' \
		$(filter-out src/require.inc.sh, $^) >> "$@"
	chmod a+x "$@"

test:
	docker run --rm \
		-v "$(PWD):/t" \
		-e "TEST_FAIL_FAST=$(TEST_FAIL_FAST)" \
		-e "TEST_FILTER=$(TEST_FILTER)" \
		bash:4.2 \
		bash -c 'ln -s /usr/local/bin/bash /bin/bash; cd /t; /t/src/tests/run.sh'

clean:
	rm -rf dist/
