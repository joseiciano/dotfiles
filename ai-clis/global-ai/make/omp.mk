# oh-my-pi: agents, APPEND_SYSTEM.md, extensions and workflows in output/omp. Skills and
# commands come from the Claude build in ~/.claude; `link-omp` turns on
# oh-my-pi's settings for reading them from there.
OMP_OUT := $(OUTPUT_DIR)/omp
# Earlier build location whose links and copies are pruned.
OMP_LEGACY_ROOT := $(AI_CLIS_DIR)/oh-my-pi/output

.PHONY: build-omp link-omp install-omp

build-omp:
	rm -rf $(OMP_OUT)
	mkdir -p $(OMP_OUT)/workflows
	$(RENDER) omp --out $(OMP_OUT)/agents
	$(RENDER) prompt $(APPEND_SYSTEM) $(OMP_OUT)/APPEND_SYSTEM.md
	cp -R $(SETUP_DIR)/omp-specific/extensions $(OMP_OUT)/extensions
	cp $(WORKFLOWS_SETUP)/*/* $(OMP_OUT)/workflows/

# Link only after the build completes, even under `make -j`.
install-omp: build-omp
	$(MAKE) -C $(GA_DIR) link-omp

link-omp:
	mkdir -p $(HOME)/.omp/agent $(HOME)/.pi/workflows/saved
	rm -rf $(HOME)/.omp/agent/agents
	ln -s $(OMP_OUT)/agents $(HOME)/.omp/agent/agents
	@if [ -e "$(HOME)/.omp/agent/APPEND_SYSTEM.md" ] && [ ! -L "$(HOME)/.omp/agent/APPEND_SYSTEM.md" ]; then \
		echo "ERROR: refusing to replace existing file: $(HOME)/.omp/agent/APPEND_SYSTEM.md" >&2; exit 1; \
	fi; \
	ln -sfn $(OMP_OUT)/APPEND_SYSTEM.md $(HOME)/.omp/agent/APPEND_SYSTEM.md
	@set -e; \
	managed() { \
		case "$$1" in "$(OMP_OUT)"/*|"$(OMP_LEGACY_ROOT)"/*) return 0 ;; esac; \
		return 1; \
	}; \
	for dest in "$(HOME)/.omp/agent/skills"/*; do \
		name=$$(basename "$$dest"); \
		if [ -L "$$dest" ]; then \
			if managed "$$(readlink "$$dest")"; then rm -f "$$dest"; fi; \
		elif [ -d "$$dest" ] && { [ -d "$(SKILLS_SETUP)/skills/$$name" ] || [ -d "$(SKILLS_SETUP)/old-skills/$$name" ] || [ -d "$(HOME)/.claude/skills/$$name" ]; }; then \
			rm -rf "$$dest"; \
		fi; \
	done; \
	for dest in "$(HOME)/.claude/commands"/*; do \
		[ -L "$$dest" ] || continue; \
		if managed "$$(readlink "$$dest")"; then rm -f "$$dest"; fi; \
	done; \
	old_command_dir="$(HOME)/.omp/agent/commands"; \
	if [ -L "$$old_command_dir" ] && managed "$$(readlink "$$old_command_dir")/"; then \
		rm -f "$$old_command_dir"; \
	fi; \
	if command -v omp >/dev/null 2>&1; then \
		omp config set skills.enableClaudeUser true; \
		omp config set commands.enableClaudeUser true; \
	else \
		echo "WARNING: omp not found; set skills.enableClaudeUser and commands.enableClaudeUser to true yourself" >&2; \
	fi; \
	extensions_dir="$(HOME)/.omp/agent/extensions"; \
	mkdir -p "$$extensions_dir"; \
	for src in "$(OMP_OUT)/extensions"/*; do \
		[ -e "$$src" ] || continue; \
		dest="$$extensions_dir/$$(basename "$$src")"; \
		if [ -e "$$dest" ] && [ ! -L "$$dest" ]; then \
			echo "ERROR: refusing to replace existing extension file: $$dest" >&2; \
			exit 1; \
		fi; \
	done; \
	for dest in "$$extensions_dir"/*; do \
		[ -L "$$dest" ] || continue; \
		target=$$(readlink "$$dest"); \
		if managed "$$target" && [ ! -e "$$target" ]; then rm -f "$$dest"; fi; \
	done; \
	for src in "$(OMP_OUT)/extensions"/*; do \
		[ -e "$$src" ] || continue; \
		ln -sfn "$$src" "$$extensions_dir/$$(basename "$$src")"; \
	done; \
	workflows_root="$(OMP_OUT)/workflows"; \
	saved_dir="$(HOME)/.pi/workflows/saved"; \
	for src in "$$workflows_root"/*; do \
		[ -e "$$src" ] || continue; \
		dest="$$saved_dir/$$(basename "$$src")"; \
		if [ -e "$$dest" ] && [ ! -L "$$dest" ]; then \
			echo "ERROR: refusing to replace existing workflow file: $$dest" >&2; \
			exit 1; \
		fi; \
	done; \
	for dest in "$$saved_dir"/*; do \
		[ -L "$$dest" ] || continue; \
		target=$$(readlink "$$dest"); \
		if managed "$$target" && [ ! -e "$$target" ]; then rm -f "$$dest"; fi; \
	done; \
	for src in "$$workflows_root"/*; do \
		[ -e "$$src" ] || continue; \
		dest="$$saved_dir/$$(basename "$$src")"; \
		[ -L "$$dest" ] && rm -f "$$dest"; \
		ln -s "$$src" "$$dest"; \
	done; \
	echo "link complete: agents, APPEND_SYSTEM.md and extensions symlinked into ~/.omp/agent, skills and commands read from ~/.claude, workflows linked into ~/.pi/workflows/saved"
