# Agent guidelines

Coding standards for this repo. They apply to code and tests alike.

## Code

- Prefer an established package to writing our own. Search for one first, and write our own only when none fits.
- When a feature copies an existing tool, copy how it is turned on and off and how it reacts to manual overrides.
- Anything that needs cleanup is `Disposable`, used with `using` (or a `DisposableStack`), not `try`/`finally` or `afterEach`.
- No options or exports that only one test needs.
- Don't accumulate state in case something needs it later. Subscribe to an event, or let an error propagate, instead.
- Name a repeated expression with a helper instead of repeating it.
- Apply a stated preference everywhere it fits, not only where it was raised.

## Comments

- One line, explaining why. Don't restate the code.
- No changelog comments: what changed and why belongs in the commit message.

## Tests

- Test against the real dependency, not a stub, wherever it can run in-process.
- Review tests to the same standard as code.
- Check that a new test fails without the change it covers.
