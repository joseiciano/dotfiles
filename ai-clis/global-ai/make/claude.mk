# Claude Code: agents, skills, commands, hooks, workflows and APPEND_SYSTEM.md
# in output/claude, linked into the retained ai-clis/clis/claude/.claude folder,
# which is linked to ~/.claude. This is the only build of skills and commands;
# opencode and oh-my-pi read them from ~/.claude.
CLAUDE_OUT := $(OUTPUT_DIR)/claude
CLAUDE_DIR := $(CLIS_DIR)/claude/.claude
# Earlier build locations whose links in ~/.claude are replaced or pruned.
CLAUDE_LEGACY_ROOTS := $(AI_CLIS_DIR)/claude-code $(OUTPUT_DIR)/claude-code

.PHONY: build-claude link-claude install-claude

build-claude:
	rm -rf $(CLAUDE_OUT)
	mkdir -p $(CLAUDE_OUT)/commands $(CLAUDE_OUT)/workflows
	$(RENDER) claude --out $(CLAUDE_OUT)/agents
	$(RENDER) prompt $(APPEND_SYSTEM) $(CLAUDE_OUT)/APPEND_SYSTEM.md
	cp -R $(SETUP_DIR)/claude-specific/hooks $(CLAUDE_OUT)/hooks
	if [ -d $(WORKFLOWS_SETUP) ]; then find $(WORKFLOWS_SETUP) -mindepth 2 -maxdepth 2 -name '*.js' -exec cp {} $(CLAUDE_OUT)/workflows/ \;; fi
	bun $(SKILLS_SETUP)/copy-skills.js $(SKILLS_SETUP)/skills $(CLAUDE_OUT)/skills --references $(SETUP_DIR)/references
	if [ -d $(SEEDED_COMMANDS) ]; then cp -R $(SEEDED_COMMANDS)/. $(CLAUDE_OUT)/commands/; fi
	$(SKILLS_SETUP)/generate-skill-commands.sh $(CLAUDE_OUT)/skills $(CLAUDE_OUT)/commands
	$(SKILLS_SETUP)/strip-command-flags.sh $(CLAUDE_OUT)/skills

# Link only after the build completes, even under `make -j`.
install-claude: build-claude
	$(MAKE) -C $(GA_DIR) link-claude

# Link each managed directory into the retained Claude config. If a destination
# is a real directory, preserve it and reconcile only entries managed by this
# build (or one of the legacy build locations). With `per-entry`, the destination
# is always a real directory of per-entry links, so files Claude Code writes there
# itself (e.g. skills/synced/) stay out of the build output and survive rebuilds.
link-claude:
	@set -e; \
	managed() { \
		for root in "$(CLAUDE_OUT)" $(CLAUDE_LEGACY_ROOTS); do \
			case "$$1" in "$$root"/*) return 0 ;; esac; \
		done; \
		return 1; \
	}; \
	link_directory() { \
		src_root=$$1; mapped_dest=$$2; per_entry=$${3:-}; \
		[ -d "$$src_root" ] || return 0; \
		if [ -n "$$per_entry" ]; then \
			if [ -L "$$mapped_dest" ]; then \
				if ! managed "$$(readlink "$$mapped_dest")/" ; then \
					echo "ERROR: refusing to replace unrelated symlink: $$mapped_dest" >&2; \
					return 1; \
				fi; \
				rm -f "$$mapped_dest"; \
			fi; \
			mkdir -p "$$mapped_dest"; \
		elif [ -L "$$mapped_dest" ]; then \
			rm -f "$$mapped_dest"; \
			ln -s "$$src_root" "$$mapped_dest"; \
			return 0; \
		fi; \
		if [ ! -e "$$mapped_dest" ]; then \
			ln -s "$$src_root" "$$mapped_dest"; \
			return 0; \
		fi; \
		if [ ! -d "$$mapped_dest" ]; then \
			echo "ERROR: refusing to replace existing path (move it aside first): $$mapped_dest" >&2; \
			return 1; \
		fi; \
		for src in "$$src_root"/*; do \
			[ -e "$$src" ] || continue; \
			dest="$$mapped_dest/$$(basename "$$src")"; \
			if [ -e "$$dest" ] && [ ! -L "$$dest" ]; then \
				echo "ERROR: refusing to replace existing path (move it aside first): $$dest" >&2; \
				return 1; \
			fi; \
		done; \
		for dest in "$$mapped_dest"/*; do \
			[ -L "$$dest" ] || continue; \
			target=$$(readlink "$$dest"); \
			if managed "$$target" && [ ! -e "$$target" ]; then rm -f "$$dest"; fi; \
		done; \
		for src in "$$src_root"/*; do \
			[ -e "$$src" ] || continue; \
			dest="$$mapped_dest/$$(basename "$$src")"; \
			[ -L "$$dest" ] && rm -f "$$dest"; \
			ln -s "$$src" "$$dest"; \
		done; \
	}; \
	link_home_dir() { \
		src=$$1; dst=$$2; \
		mkdir -p "$$(dirname "$$dst")"; \
		if [ -L "$$dst" ]; then \
			rm -f "$$dst"; \
		elif [ -e "$$dst" ]; then \
			echo "ERROR: refusing to replace existing path (move it aside first): $$dst" >&2; \
			exit 1; \
		fi; \
		ln -s "$$src" "$$dst"; \
	}; \
	mkdir -p "$(CLAUDE_DIR)"; \
	if [ -L "$(CLAUDE_DIR)/command" ] && managed "$$(readlink "$(CLAUDE_DIR)/command")"; then \
		rm -f "$(CLAUDE_DIR)/command"; \
	fi; \
	link_directory "$(CLAUDE_OUT)/agents" "$(CLAUDE_DIR)/agents"; \
	link_directory "$(CLAUDE_OUT)/commands" "$(CLAUDE_DIR)/commands"; \
	link_directory "$(CLAUDE_OUT)/skills" "$(CLAUDE_DIR)/skills" per-entry; \
	link_directory "$(CLAUDE_OUT)/workflows" "$(CLAUDE_DIR)/workflows"; \
	link_home_dir "$(CLAUDE_DIR)" "$(HOME)/.claude"; \
	echo "Linked Claude Code agents, commands, skills, and workflows into $$HOME/.claude."
