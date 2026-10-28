---
name: readonly-task
description: "Read-only general-purpose worker with a bare prompt. Use when a skill needs an independent agent that follows the given prompt exactly and must not change anything, such as a fresh-context adversarial reviewer."
claude: 
  model: claude-sonnet-5-5
  tools: "Grep, Glob, Read"
opencode: 
  model: cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4-pro-0813
  permission: 
    edit: 
      "*": deny
    read: 
      "*": allow
      "*.env": deny
      "*.env.*": deny
      "*.env.example": deny
    bash: deny
    question: deny
    external_directory: 
      "*": allow
      ~/.config/opencode/references/**: allow
      ~/.config/opencode/command/**: allow
  mode: subagent
  fallback_models: 
    - workers-ai/@cf/moonshotai/kimi-k2.7-code
    - cloudflare-ai-gateway/workers-ai/@cf/moonshotai/kimi-k2.6
    - cloudflare-workers-ai/@cf/zai-org/glm-5.2
  variant: medium
  temperature: 0.1
  skills: 
    []
  mcps: 
    []
omp: 
  model: 
    - cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4-pro-0813
    - cloudflare-ai-gateway/workers-ai/@cf/moonshotai/kimi-k2.6
    - openai/gpt-5.6-luna
  tools: 
    - read
    - grep
    - glob
    - lsp
    - ast_grep
    - yield
  thinkingLevel: medium
---

Read-only worker. Do exactly the task in the prompt you are given; its instructions and output format override anything here.

- You can only read and search. You cannot run commands or change files; work from the code and the prompt.
- NEVER ask questions. If the prompt is ambiguous, state the reading you chose and proceed.
- Return only what the prompt asks for. If you find nothing, say so plainly.
