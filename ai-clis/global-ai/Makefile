.PHONY: agents setup init link

agents:
	./setup/agent-setup/generate-agents-md-claude.sh
	./setup/agent-setup/generate-agents-md-opencode.sh

setup: agents
	rm -rf output/opencode/command output/opencode/skills output/opencode/envs output/opencode/plugins output/opencode/opencode.json output/opencode/config.json output/opencode/opencode-fallback.jsonc
	rm -rf output/claude-code/command output/claude-code/skills output/claude-code/envs
	rm -rf output/reasonix/command
	mkdir -p output/opencode output/claude-code output/reasonix
	cp -R setup/command-setup/command output/opencode/command
	cp -R setup/skills-setup/skills output/opencode/skills
	cp -R setup/envs output/opencode/envs
	cp -R setup/plugins/opencode-and-clones-only output/opencode/plugins
	cp setup/config/opencode-and-clones-only/opencode-fallback.jsonc output/opencode/opencode-fallback.jsonc
	./setup/config/opencode-and-clones-only/generate-config.sh output/opencode opencode
	cp -R setup/command-setup/command output/claude-code/command
	cp -R setup/skills-setup/skills output/claude-code/skills
	cp -R setup/envs output/claude-code/envs
	cp -R setup/command-setup/command output/reasonix/command
	rm -rf output/mimocode
	cp -R output/opencode output/mimocode
	./setup/config/opencode-and-clones-only/generate-config.sh output/mimocode mimocode
	rm -f output/mimocode/opencode.json

init: setup link

link:
	mkdir -p $(HOME)/dotfiles/opencode/.config/opencode $(HOME)/dotfiles/claude/.claude $(HOME)/dotfiles/mimocode/.config/mimocode
	@for src in output/opencode/*; do \
		[ -d "$$src" ] || continue; \
		dest="$(HOME)/dotfiles/opencode/.config/opencode/$$(basename "$$src")"; \
		rm -rf "$$dest"; \
		ln -s "$(CURDIR)/$$src" "$$dest"; \
	done
	@for src in output/opencode/*.json; do \
		[ -f "$$src" ] || continue; \
		dest="$(HOME)/dotfiles/opencode/.config/opencode/$$(basename "$$src")"; \
		rm -f "$$dest"; \
		ln -s "$(CURDIR)/$$src" "$$dest"; \
	done
	@for src in output/opencode/*.jsonc; do \
		[ -f "$$src" ] || continue; \
		dest="$(HOME)/dotfiles/opencode/.config/opencode/$$(basename "$$src")"; \
		rm -f "$$dest"; \
		ln -s "$(CURDIR)/$$src" "$$dest"; \
	done
	@for src in output/claude-code/*; do \
		[ -d "$$src" ] || continue; \
		dest="$(HOME)/dotfiles/claude/.claude/$$(basename "$$src")"; \
		rm -rf "$$dest"; \
		ln -s "$(CURDIR)/$$src" "$$dest"; \
	done
	@for src in output/mimocode/*; do \
		[ -d "$$src" ] || continue; \
		dest="$(HOME)/dotfiles/mimocode/.config/mimocode/$$(basename "$$src")"; \
		rm -rf "$$dest"; \
		ln -s "$(CURDIR)/$$src" "$$dest"; \
	done
	@for src in output/mimocode/*.json; do \
		[ -f "$$src" ] || continue; \
		dest="$(HOME)/dotfiles/mimocode/.config/mimocode/$$(basename "$$src")"; \
		rm -f "$$dest"; \
		ln -s "$(CURDIR)/$$src" "$$dest"; \
	done
	@for src in output/mimocode/*.jsonc; do \
		[ -f "$$src" ] || continue; \
		dest="$(HOME)/dotfiles/mimocode/.config/mimocode/$$(basename "$$src")"; \
		rm -f "$$dest"; \
		ln -s "$(CURDIR)/$$src" "$$dest"; \
	done
	mkdir -p $(HOME)/.reasonix
	rm -rf $(HOME)/.reasonix/commands
	ln -s $(CURDIR)/output/reasonix/command $(HOME)/.reasonix/commands
