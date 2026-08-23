---
description: Run a comprehensive AI review against current changes. 
agent: reviewer
permissions:
  bash: allow
  read: allow
  grep: allow
  glob: allow
  edit: deny
  external_directory:
    "~/dotfiles/opencode/.config/opencode/**": allow
---

Run the `review` SKILL on the work given to you, analyzing the changes we current have on this Git branch.

## Review-Result Output File

The code review should be outputted to `code_reviews/<ticket>/code_review_x.md` where `x` starts at 1 and increments up each time if the previous exists. If the ticket includes numbers (e.g. "5-7-new-api-route.md"), the numbers are the ticket number (file created should be `code_reviews/5-7/code_review_1.md` for example).

**Note**: If `<ticket>` does not exist, prior to calling the AI reviewer CLI, generate a 1-3 hyphenated summary (e.g. `test-local-dev`) to be the name. 

## Final Output

1. Output the code review to the file mentioned above. The command/orchestrator must create the parent directory and write the final Markdown review using shell redirection or `tee` — not the edit/write tools (these are denied). For example:

   ```bash
   mkdir -p "$(dirname "$output_file")"; <review-output-command> | tee "$output_file"
   ```

2. Output the review to the user as well. Do not show anything other what the review/skill mentions as the output. 

## Review Background

Analyze the `docs/` path and pass in as `--background` flag information any product and functional spec docs that are relevant to the ticket at hand. 

