.PHONY: agents config setup link install-slim init clean

MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
SLIM_DIR := $(abspath $(dir $(MAKEFILE_PATH)))
CLIS_DIR := $(abspath $(SLIM_DIR)/../clis)
BASE_CONFIG_DIR := $(CLIS_DIR)/opencode/.config/opencode
OUTPUT_DIR := $(SLIM_DIR)/output/opencode

agents:
	rm -rf $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)
	bash ./setup/agent_setup/generate-slim-agents.sh

config: agents
	bash ./setup/config/generate-slim-config.sh

# Skills and commands are built once, by global-ai's Claude build, into ~/.claude.
# opencode reads ~/.claude/skills itself; the command folder links to
# ~/.claude/commands.
setup: config
	if [ -d "$(HOME)/.claude/commands" ]; then ln -s "$(HOME)/.claude/commands" $(OUTPUT_DIR)/command; fi
	cp $(BASE_CONFIG_DIR)/package.json $(OUTPUT_DIR)/
	cp ./setup/config/opencode.jsonc $(OUTPUT_DIR)/
	cp ./setup/config/oh-my-opencode-slim.jsonc $(OUTPUT_DIR)/
	[ -f $(BASE_CONFIG_DIR)/.env ] && cp $(BASE_CONFIG_DIR)/.env $(OUTPUT_DIR)/ || true
	printf 'node_modules/\n*.log\n.env\n.oh-my-opencode-slim/\n' > $(OUTPUT_DIR)/.gitignore
	cd $(OUTPUT_DIR) && bun install

link:
	@set -e; \
	if [ -L "$(HOME)/.config/opencode" ]; then rm -f "$(HOME)/.config/opencode"; \
	elif [ -e "$(HOME)/.config/opencode" ]; then \
		echo "ERROR: $(HOME)/.config/opencode is not a symlink (move it aside first)" >&2; \
		exit 1; \
	fi; \
	mkdir -p "$(HOME)/.config"; \
	ln -s "$(OUTPUT_DIR)" "$(HOME)/.config/opencode"; \
	echo "Linked ~/.config/opencode -> $(OUTPUT_DIR)"

install-slim:
	cd $(HOME)/.config/opencode && bunx oh-my-opencode-slim@latest install --no-tui --skills=yes --background-subagents=yes

init: setup
	$(MAKE) link
	$(MAKE) install-slim

clean:
	rm -rf $(SLIM_DIR)/output
	mkdir -p $(OUTPUT_DIR)
	@echo "clean complete: slim output removed"
