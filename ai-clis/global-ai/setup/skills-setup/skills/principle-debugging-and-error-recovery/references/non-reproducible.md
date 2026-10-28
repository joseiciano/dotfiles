# Non-reproducible failures

Reached from Step 1 of `principle-debugging-and-error-recovery` when the failure won't happen on demand. Identify which class it falls in, then work that branch until you have a command that fails every time.

```
Timing-dependent?
├── Add timestamps to logs around the suspected area
├── Add artificial delays (setTimeout, sleep) to widen race windows
└── Run under load or concurrency to raise collision odds
Environment-dependent?
├── Compare runtime versions, OS, environment variables
├── Compare data (empty vs populated database)
└── Reproduce in CI, where the environment is clean
State-dependent?
├── Look for state leaking between tests or requests
├── Look for globals, singletons, shared caches
└── Run the scenario in isolation vs after other operations
Truly random?
├── Add logging at the suspected location
├── Alert on the specific error signature
└── Record the observed conditions and revisit when it recurs
```

If it still won't reproduce, report the recorded conditions to the user rather than shipping a speculative fix.
