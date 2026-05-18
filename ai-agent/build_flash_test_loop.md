# Build Flash Test Loop

```text
requirement
  -> code change
  -> build
  -> flash
  -> serial test
  -> protocol validation
  -> evidence package
```

## Rules

- Build must pass before flash.
- Flash output must be saved.
- Serial tests must record command and response.
- Protocol parsers must record frame count and bad-frame count.
- Evidence is part of the delivery, not an optional afterthought.
