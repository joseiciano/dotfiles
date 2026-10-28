# Triage trees

Reached from Step 2 of `principle-debugging-and-error-recovery`. Follow the tree for the failure in front of you.

## Test failure

```
Test fails after a code change:
├── Changed code the test covers?
│   ├── Test is outdated → update the test
│   └── Code has a bug → fix the code
├── Changed unrelated code?
│   └── Likely a side effect → check shared state, imports, globals
└── Test was already flaky?
    └── Check timing, order dependence, external dependencies; fix the flakiness
```

## Build failure

```
Build fails:
├── Type error       → read the error, check the types at the cited location
├── Import error     → module exists, exports match, paths are correct
├── Config error     → build config syntax and schema
├── Dependency error → manifest and lockfile, reinstall dependencies
└── Environment error → runtime version, OS compatibility
```

## Runtime error

```
Runtime error:
├── Cannot read property 'x' of undefined
│   └── Trace the data flow back to where the value should have been set
├── Network error / CORS
│   └── URLs, headers, server CORS config
├── Render error / blank screen
│   └── Error boundary, console, component tree
└── Wrong behaviour, no error
    └── Log at key points and check the data at each step
```
