.PHONY: install install-opencode install-claude install-omp init-opencode-slim opencode-slim

# Every harness is built from global-ai; see global-ai/Makefile.
install install-opencode install-claude install-omp:
	$(MAKE) -C global-ai $@

init-opencode-slim:
	$(MAKE) -C oh-my-opencode-slim init

opencode-slim: init-opencode-slim
