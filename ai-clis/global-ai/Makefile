.PHONY: agents setup init link

# --- Location (robust against `make -C` from anywhere) ---
# Resolve from this Makefile's own path, not from an assumed $HOME/dotfiles.
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
GA_DIR := $(abspath $(dir $(MAKEFILE_PATH)))
REPO_ROOT := $(abspath $(GA_DIR)/../..)
CLIS_DIR := $(REPO_ROOT)/ai-clis/clis

# Retained per-CLI config folders under ai-clis/clis/. Generated output entries
# are symlinked into these folders; each folder is then symlinked whole into the
# real HOME config path. Non-generated files already present are kept.
OPCODE_DIR := $(CLIS_DIR)/opencode/.config/opencode
CLAUDE_DIR := $(CLIS_DIR)/claude/.claude
MIMO_DIR := $(CLIS_DIR)/mimocode/.config/mimocode

agents:
	./setup/agent-setup/generate-agents-md-claude.sh
	./setup/agent-setup/generate-agents-md-opencode.sh

setup: agents
	rm -rf output/opencode/command output/opencode/skills output/opencode/plugins output/opencode/opencode.json output/opencode/config.json output/opencode/opencode-fallback.jsonc
	rm -rf output/claude-code/command output/claude-code/skills
	rm -rf output/reasonix/command
	mkdir -p output/opencode output/claude-code output/reasonix
	cp -R setup/command-setup/command output/opencode/command
	cp -R setup/skills-setup/skills output/opencode/skills
	cp -R setup/plugins/opencode-and-clones-only output/opencode/plugins
	cp setup/config/opencode-and-clones-only/opencode-fallback.jsonc output/opencode/opencode-fallback.jsonc
	./setup/config/opencode-and-clones-only/generate-config.sh output/opencode opencode
	cp -R setup/command-setup/command output/claude-code/command
	cp -R setup/skills-setup/skills output/claude-code/skills
	cp -R setup/command-setup/command output/reasonix/command
	rm -rf output/mimocode
	cp -R output/opencode output/mimocode
	./setup/config/opencode-and-clones-only/generate-config.sh output/mimocode mimocode
	rm -f output/mimocode/opencode.json

# init must not run link before setup completes, even under `make -j`.
# Depend on setup only; the recipe recursively invokes `$(MAKE) link` after
# setup's recipe finishes, guaranteeing strict ordering.
init: setup
	$(MAKE) link

# Replace a generated entry by removing the old symlink only. A real file/dir
# colliding with a generated entry name is left untouched and fails the recipe.
# Before linking, remove stale symlinks in the retained folder only when their
# target lives under the matching output root and no longer exists; unrelated
# symlinks and real files/dirs are preserved.
link:
	@set -e; \
	link_entry() { \
		src=$$1; dest_dir=$$2; \
		[ -e "$$src" ] || return 0; \
		dest="$$dest_dir/$$(basename "$$src")"; \
		if [ -L "$$dest" ]; then \
			rm -f "$$dest"; \
		elif [ -e "$$dest" ]; then \
			echo "ERROR: refusing to replace existing path (move it aside first): $$dest" >&2; \
			return 1; \
		fi; \
		ln -s "$$src" "$$dest"; \
	}; \
	reconcile() { \
		src_root=$$1; dest_dir=$$2; \
		[ -d "$$dest_dir" ] || return 0; \
		for dest in "$$dest_dir"/*; do \
			[ -L "$$dest" ] || continue; \
			target=$$(readlink "$$dest"); \
			case "$$target" in \
				"$$src_root/"*) ;; \
				*) continue ;; \
			esac; \
			[ -e "$$target" ] || rm -f "$$dest"; \
		done; \
	}; \
	link_entries() { \
		src_root=$$1; dest_dir=$$2; \
		[ -d "$$src_root" ] || return 0; \
		mkdir -p "$$dest_dir"; \
		reconcile "$$src_root" "$$dest_dir"; \
		for src in "$$src_root"/*; do \
			[ -e "$$src" ] || continue; \
			base=$$(basename "$$src"); \
			if [ -d "$$src" ] || [ "$${base##*.}" = json ] || [ "$${base##*.}" = jsonc ]; then \
				link_entry "$$src" "$$dest_dir"; \
			fi; \
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
	link_entries "$(GA_DIR)/output/opencode" "$(OPCODE_DIR)"; \
	link_entries "$(GA_DIR)/output/claude-code" "$(CLAUDE_DIR)"; \
	link_entries "$(GA_DIR)/output/mimocode" "$(MIMO_DIR)"; \
	link_home_dir "$(OPCODE_DIR)" "$(HOME)/.config/opencode"; \
	link_home_dir "$(CLAUDE_DIR)" "$(HOME)/.claude"; \
	link_home_dir "$(MIMO_DIR)" "$(HOME)/.config/mimocode"; \
	mkdir -p "$(HOME)/.reasonix"; \
	if [ -L "$(HOME)/.reasonix/commands" ]; then rm -f "$(HOME)/.reasonix/commands"; \
	elif [ -e "$(HOME)/.reasonix/commands" ]; then \
		echo "ERROR: refusing to replace existing path (move it aside first): $(HOME)/.reasonix/commands" >&2; \
		exit 1; \
	fi; \
	ln -s "$(GA_DIR)/output/reasonix/command" "$(HOME)/.reasonix/commands"; \
	echo "Linked per-CLI config folders (opencode, claude, mimocode) and reasonix into $$HOME."
