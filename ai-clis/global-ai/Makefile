.PHONY: install

# --- Location (robust against `make -C` from anywhere) ---
# Resolve from this Makefile's own path, not from an assumed $HOME/dotfiles.
MAKEFILE_PATH := $(lastword $(MAKEFILE_LIST))
GA_DIR := $(abspath $(dir $(MAKEFILE_PATH)))
AI_CLIS_DIR := $(abspath $(GA_DIR)/..)
CLIS_DIR := $(AI_CLIS_DIR)/clis

# Sources live in setup/; every harness builds into output/<harness>.
SETUP_DIR := $(GA_DIR)/setup
OUTPUT_DIR := $(GA_DIR)/output
RENDER := bun $(SETUP_DIR)/agent-setup/render-agents.js
APPEND_SYSTEM := $(SETUP_DIR)/agent-setup/prompt/APPEND_SYSTEM.md
SKILLS_SETUP := $(SETUP_DIR)/skills-setup
SEEDED_COMMANDS := $(SETUP_DIR)/command-setup/command
WORKFLOWS_SETUP := $(SETUP_DIR)/workflows-setup

# Build and link every harness, one at a time even under `make -j`. Claude Code
# goes first: it builds the skills and commands in ~/.claude that opencode and
# oh-my-pi read.
install:
	$(MAKE) -C $(GA_DIR) install-claude
	$(MAKE) -C $(GA_DIR) install-opencode
	$(MAKE) -C $(GA_DIR) install-omp

include $(GA_DIR)/make/claude.mk
include $(GA_DIR)/make/opencode.mk
include $(GA_DIR)/make/omp.mk
