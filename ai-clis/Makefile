.PHONY: init init-opencode-base init-opencode-slim init-omp init-oh-my-pi opencode-base opencode-slim oh-my-pi

init:
	@:

init-opencode-base:
	$(MAKE) -C global-ai init

init-opencode-slim:
	$(MAKE) -C oh-my-opencode-slim init

init-omp:
	$(MAKE) -C oh-my-pi init

init-oh-my-pi: init-omp
opencode-base: init-opencode-base
opencode-slim: init-opencode-slim
oh-my-pi: init-omp
