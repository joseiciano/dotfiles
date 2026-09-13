.PHONY: init init-opencode-base init-opencode-slim init-oh-my-pi opencode-base opencode-slim oh-my-pi

init:
	@:

init-opencode-base:
	$(MAKE) -C global-ai init

init-opencode-slim:
	$(MAKE) -C oh-my-opencode-slim init

init-oh-my-pi:
	$(MAKE) -C oh-my-pi init

opencode-base: init-opencode-base
opencode-slim: init-opencode-slim
oh-my-pi: init-oh-my-pi
