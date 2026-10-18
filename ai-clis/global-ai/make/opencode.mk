# opencode: agents and opencode.json in output/opencode, linked into the
# retained ai-clis/clis/opencode folder, which is linked to ~/.config/opencode.
# Skills and commands come from the Claude build in ~/.claude: opencode reads
# ~/.claude/skills itself, and its command folder links to ~/.claude/commands.
OPENCODE_OUT := $(OUTPUT_DIR)/opencode
OPCODE_DIR := $(CLIS_DIR)/opencode/.config/opencode

.PHONY: agents-opencode setup-opencode link-opencode install-opencode

# render-agents.js writes each agent's model/fallback/variant/temperature/
# skills/mcps to a temp metadata dir that generate-config.sh merges into
# opencode.json.
agents-opencode:
	@set -e; meta=$$(mktemp -d); trap 'rm -rf "$$meta"' EXIT; \
	$(RENDER) opencode --out $(OPENCODE_OUT)/agents --meta-out "$$meta/agents"; \
	AGENTS_DIR="$$meta/agents" $(SETUP_DIR)/config/opencode-and-clones-only/generate-config.sh $(OPENCODE_OUT) opencode

setup-opencode: agents-opencode
	rm -rf $(OPENCODE_OUT)/command $(OPENCODE_OUT)/skills $(OPENCODE_OUT)/plugins $(OPENCODE_OUT)/config.json $(OPENCODE_OUT)/opencode-fallback.jsonc

# Link only after setup completes, even under `make -j`.
install-opencode: setup-opencode
	$(MAKE) -C $(GA_DIR) link-opencode

# Replace a generated entry by removing the old symlink only. A real file/dir
# colliding with a generated entry name is left untouched and fails the recipe.
# Before linking, remove stale symlinks in the retained folder only when their
# target lives under the matching output root and no longer exists; unrelated
# symlinks and real files/dirs are preserved.
link-opencode:
	@set -e; \
	link_entry() { \
		src=$$1; dest_dir=$$2; dest_name=$${3:-$$(basename "$$src")}; \
		[ -e "$$src" ] || return 0; \
		dest="$$dest_dir/$$dest_name"; \
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
	link_mapped_directory() { \
		mapped_src_root=$$1; mapped_dest=$$2; \
		if [ -L "$$mapped_dest" ]; then \
			rm -f "$$mapped_dest"; \
			ln -s "$$mapped_src_root" "$$mapped_dest"; \
			return 0; \
		fi; \
		if [ ! -e "$$mapped_dest" ]; then \
			ln -s "$$mapped_src_root" "$$mapped_dest"; \
			return 0; \
		fi; \
		if [ ! -d "$$mapped_dest" ]; then \
			echo "ERROR: refusing to replace existing path (move it aside first): $$mapped_dest" >&2; \
			return 1; \
		fi; \
		for mapped_src in "$$mapped_src_root"/*; do \
			[ -e "$$mapped_src" ] || continue; \
			mapped_entry="$$mapped_dest/$$(basename "$$mapped_src")"; \
			if [ -e "$$mapped_entry" ] && [ ! -L "$$mapped_entry" ]; then \
				echo "ERROR: refusing to replace existing path (move it aside first): $$mapped_entry" >&2; \
				return 1; \
			fi; \
		done; \
		for mapped_entry in "$$mapped_dest"/*; do \
			[ -L "$$mapped_entry" ] || continue; \
			mapped_target=$$(readlink "$$mapped_entry"); \
			case "$$mapped_target" in \
				"$$mapped_src_root/"*) [ -e "$$mapped_target" ] || rm -f "$$mapped_entry" ;; \
			esac; \
		done; \
		for mapped_src in "$$mapped_src_root"/*; do \
			[ -e "$$mapped_src" ] || continue; \
			mapped_entry="$$mapped_dest/$$(basename "$$mapped_src")"; \
			[ -L "$$mapped_entry" ] && rm -f "$$mapped_entry"; \
			ln -s "$$mapped_src" "$$mapped_entry"; \
		done; \
	}; \
	link_entries() { \
		src_root=$$1; dest_dir=$$2; rename_from=$${3:-}; rename_to=$${4:-}; \
		[ -d "$$src_root" ] || return 0; \
		mkdir -p "$$dest_dir"; \
		reconcile "$$src_root" "$$dest_dir"; \
		if [ -n "$$rename_from" ]; then \
			legacy="$$dest_dir/$$rename_from"; \
			if [ -L "$$legacy" ] && [ "$$(readlink "$$legacy")" = "$$src_root/$$rename_from" ]; then \
				rm -f "$$legacy"; \
			fi; \
		fi; \
		for src in "$$src_root"/*; do \
			[ -e "$$src" ] || continue; \
			base=$$(basename "$$src"); \
			dest_name="$$base"; \
			[ "$$base" = "$$rename_from" ] && dest_name="$$rename_to"; \
			if [ -d "$$src" ] || [ "$${base##*.}" = json ] || [ "$${base##*.}" = jsonc ]; then \
				if [ "$$base" = "$$rename_from" ]; then \
					link_mapped_directory "$$src" "$$dest_dir/$$dest_name"; \
				else \
					link_entry "$$src" "$$dest_dir" "$$dest_name"; \
				fi; \
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
	link_entries "$(OPENCODE_OUT)" "$(OPCODE_DIR)"; \
	link_entry "$(HOME)/.claude/commands" "$(OPCODE_DIR)" command; \
	link_home_dir "$(OPCODE_DIR)" "$(HOME)/.config/opencode"; \
	echo "Linked opencode config folder into $$HOME (commands from ~/.claude/commands)."
