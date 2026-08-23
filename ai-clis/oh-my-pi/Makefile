.PHONY: setup clean install init link

setup:
	rm -rf output/skills
	mkdir -p output
	cp -R setup/skills-setup/skills output/skills

clean:
	rm -rf output/agents output/skills output/.agents.*
	mkdir -p output
	touch output/.gitkeep
	@echo "clean complete: generated contents removed, output preserved"

install:
	@set -e; \
	mkdir -p output; \
	tmp=$$(mktemp -d output/.agents.XXXXXXXX) || exit 1; \
	cleanup() { rm -rf "$$tmp"; }; \
	trap cleanup EXIT; \
	trap 'exit 1' HUP INT TERM; \
	process() { \
		src="$$1"; out="$$2"; \
		probe=$$(awk 'BEGIN { fm = 0; insh = 0; hs = 0 } /^---[ \t\r]*$$/ { if (fm == 0 && NR == 1) { fm = 1; next } if (fm == 1) { fm = 2; next } next } fm == 0 { fm = 2; next } fm == 1 { if (insh) { if ($$0 ~ /^[ \t]*-[ \t]+/) { t = $$0; sub(/^[ \t]*-[ \t]+/, "", t); sub(/[ \t\r]+$$/, "", t); print "S:" t; next } if ($$0 ~ /^[ \t\r]*$$/) { next } if ($$0 ~ /^[ \t]*#/) { next } insh = 0 } if ($$0 ~ /^shared:[ \t\r]*$$/) { hs = 1; insh = 1; next } } END { print (hs ? "HS" : "NH") }' "$$src"); \
		last=$$(printf '%s\n' "$$probe" | tail -n 1); \
		if [ "$$last" = "HS" ]; then \
			if [ "$$(tail -c 1 "$$src" | od -An -t u1 | tr -d ' \n')" = "10" ]; then \
				hasnl=1; \
			else \
				hasnl=0; \
			fi; \
			awk -v hasnl="$$hasnl" 'BEGIN { fm = 0; insh = 0; nk = 0 } /^---[ \t\r]*$$/ { if (fm == 0 && NR == 1) { fm = 1; keep(); next } if (fm == 1) { fm = 2; keep(); next } keep(); next } fm == 0 { fm = 2; keep(); next } fm == 1 { if (insh) { if ($$0 ~ /^[ \t]*-[ \t]+/) { next } if ($$0 ~ /^[ \t\r]*$$/) { next } if ($$0 ~ /^[ \t]*#/) { next } insh = 0 } if ($$0 ~ /^shared:[ \t\r]*$$/) { insh = 1; next } } { keep() } END { if (nk > 0) { printf "%s", buf; if (hasnl) printf "\n" } } function keep() { if (nk > 0) { printf "%s\n", buf } buf = $$0; nk++ }' "$$src" > "$$out"; \
			printf '%s\n' "$$probe" | sed -n 's/^S://p' | while IFS= read -r t; do \
				case "$$t" in \
					''|'.'|'..'|*/*|*[!A-Za-z0-9._-]*) \
						echo "error: unsafe shared tag '$$t' referenced by $$src" >&2; \
						exit 1 ;; \
				esac; \
				if [ ! -f "setup/agent-setup/agents-shared/$$t.md" ]; then \
					echo "error: shared fragment setup/agent-setup/agents-shared/$$t.md referenced by $$src is missing" >&2; \
					exit 1; \
				fi; \
				if [ -L "setup/agent-setup/agents-shared/$$t.md" ]; then \
					echo "error: shared fragment setup/agent-setup/agents-shared/$$t.md referenced by $$src is a symlink" >&2; \
					exit 1; \
				fi; \
				shared_canon="$$(cd -P -- "setup/agent-setup/agents-shared" && pwd -P)" || exit 1; \
				frag_canon="$$(cd -P -- "$$(dirname -- "setup/agent-setup/agents-shared/$$t.md")" && pwd -P)/$$t.md"; \
				case "$$frag_canon" in \
					"$$shared_canon"/*) ;; \
					*) \
						echo "error: shared fragment setup/agent-setup/agents-shared/$$t.md referenced by $$src escapes setup/agent-setup/agents-shared" >&2; \
						exit 1 ;; \
				esac; \
				cat "setup/agent-setup/agents-shared/$$t.md" >> "$$out"; \
			done || exit 1; \
		else \
			cp "$$src" "$$out"; \
		fi; \
		echo "  install $$src -> output/agents/$$(basename "$$src")"; \
	}; \
	for src in setup/agent-setup/agents/*.md; do \
		[ -e "$$src" ] || continue; \
		process "$$src" "$$tmp/$$(basename "$$src")"; \
	done; \
	if [ -f setup/agent-setup/agents-appends/APPEND_SYSTEM.md ]; then \
		process setup/agent-setup/agents-appends/APPEND_SYSTEM.md "$$tmp/APPEND_SYSTEM.md"; \
	fi; \
	chmod 755 "$$tmp"; \
	rm -rf output/agents; \
	mv "$$tmp" output/agents; \
	trap - EXIT HUP INT TERM; \
	echo "install complete: agents materialized in output/agents"

link:
	mkdir -p $(HOME)/.omp/skills
	rm -rf $(HOME)/.omp/agent/agents
	ln -s $(CURDIR)/output/agents $(HOME)/.omp/agent/agents
	cp -R output/skills/* $(HOME)/.omp/skills/
	@echo "link complete: agents symlinked, skills copied to ~/.omp/"

init: setup install link
