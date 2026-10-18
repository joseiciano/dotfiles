---
description: Review the current changes with the ai-review skill — the OCR workflow plus a five-axis review (correctness, readability, architecture, security, performance)
---

Invoke the ai-review skill with arguments: $ARGUMENTS

With no arguments it runs the default `both` mode. Pass `ocr` for only the OCR workflow, or `quality` for only the five-axis review (no `ocr` CLI needed).

Review the current changes (staged or recent commits) and output a structured review with specific file:line references and fix recommendations.
