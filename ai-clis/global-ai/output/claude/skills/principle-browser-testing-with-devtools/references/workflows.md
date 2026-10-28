# DevTools workflows by issue type

Each workflow specialises the core loop in [`../SKILL.md`](../SKILL.md): baseline, fix, re-check against the baseline.

## UI bugs

1. **Reproduce**: navigate to the page, trigger the bug, take a screenshot of the broken state.
2. **Inspect**: console, the DOM node in question, its computed styles, the accessibility tree.
3. **Diagnose**: compare actual DOM and styles against expected; check the right data reaches the component; name the root cause as HTML, CSS, JS, or data.
4. **Fix** in source.
5. **Re-check**: reload, screenshot again and compare with step 1, confirm a clean console, run the automated tests.

## Network issues

1. **Capture**: open the network monitor, trigger the action.
2. **Analyze**: URL, method, headers, payload, status code, response body, timing. A missing request means the code never sent it.
3. **Fix**, replay the action, confirm the response.

## Performance issues

1. **Baseline**: record a performance trace of the current behaviour.
2. **Identify**: LCP, CLS, INP, long tasks (> 50ms), unnecessary re-renders.
3. **Fix** the specific bottleneck.
4. **Measure**: record another trace; done when the targeted metric improves and no other metric regresses against the baseline.

## Screenshot verification

For CSS, responsive layouts (at each viewport size that matters), loading, transition, empty, and error states: screenshot before the change, reload after, screenshot again, compare the pair.

## Accessibility

Read the accessibility tree and confirm every interactive element has an accessible name, heading levels run without gaps, tab order follows the visual order, text contrast passes, and ARIA live regions announce dynamic changes.
