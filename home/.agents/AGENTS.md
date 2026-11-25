# Global instructions

Only what every agent needs belongs here.

## Clipboard

- When producing a chunk of multiline text whose purpose is for the user to paste it somewhere else (submission/PR notes, a message, a commit description draft, etc.), automatically copy it to the system clipboard as part of delivering it — don't wait to be asked. Still show the text in the response as normal; the clipboard copy is in addition, not instead.
  - Detect the available clipboard tool: `xclip`/`xsel` on X11 (`$DISPLAY` set), `wl-copy` on Wayland (`$WAYLAND_DISPLAY` set), `pbcopy` on macOS.
  - Prefer writing the text to a file first, then piping/loading that file into the clipboard tool (e.g. `xclip -selection clipboard -in <file>`), rather than inlining multiline text into a shell `echo`/heredoc, to avoid quoting issues.
  - If no clipboard tool or display session is available, skip silently (or note it) rather than erroring out.

- When asking the user to run a command themselves (e.g. it needs `sudo`, physical interaction like a FIDO touch, or otherwise can't be run directly), copy that command to the system clipboard the same way, in addition to showing it in the response — unless the user has said otherwise for that session. This applies even to single-line commands, not just multiline text.

## How I like code written

What I'm after is code that reads simply, does no more than it needs to, and stays cheap to change. The points below
describe that taste rather than rules, and the examples illustrate it. When following one would make a piece of code
harder to read, do what reads better and say why.

- **Lean on what exists.** The platform, the libraries in use and the codebase's own idioms usually have the tool
  already, and using it leaves less code to read and trust: `mkdtempDisposable` rather than a temporary directory with
  hand-written cleanup.
- **Adapt to the defaults.** Defaults are what everyone else's setup is tested against, so start from them and override
  one only when there is a reason, rather than bending the environment to fit the code: binding `localhost` and dialing
  whatever it resolved to, rather than spelling out an address the default would have picked anyway.
- **Every abstraction pays for itself.** A helper, a wrapper or a new name is something the reader has to learn, so it
  should leave the code clearer than it would be without it. Pulling a step into a function that names it can be worth
  it even with a single caller, when it lets the caller read as a short sequence of steps: a request handler that reads
  "parse the request, decide, reply" because the parsing loop lives in its own function. A function that only forwards
  to another, or an object whose only job is carrying two values between two places, usually is not.
- **Keep only what has a reason.** Guards for states that cannot happen, resets nothing reads and options nobody sets cost
  attention and hide what matters. If the case is real, show it; otherwise leave the code out.
- **Know rather than guess.** How a library, a protocol or a sandbox behaves is worth a small experiment before code, a
  comment or a PR relies on it. Plausible guesses that turned out wrong in practice: that a client which closes its
  write side has hung up, when it is only waiting for the reply, or that a tool waits for a slow answer, when it gives up
  after half a second by default.
- **Keep cleanup next to what needs it.** When releasing a resource is tied to acquiring it, the failure paths release it
  too, and a start that fails halfway gives back what it already got.
- **Prefer values to steps.** Code that computes a value usually reads better than code that builds one up through
  reassignment: a `const` from one expression rather than a `let` set in branches.
- **Make performance the default, not the effort.** Take the cheaper way when it reads just as well, such as running
  independent work concurrently once that is shown to be safe, but do not trade clarity for a gain nobody measured.
- **Tests that prove something.** A test is only worth having if it fails when the behaviour it covers breaks, and a
  passing run cannot show that. Break the code and watch the test fail before trusting it.
- **Least privilege, scoped to its owner.** Grant the narrowest access that works, at the scope that owns it: the public
  keyring files rather than the keyring directory, a repository's rules in that repository, and no user names or machine
  paths in shared config.
- **Leave a history that explains itself.** One concern per PR, Conventional Commits, PRs linked to the issues they
  settle, and anything written earlier that turned out wrong corrected where it was written.

## sudo

- sudo has no terminal to prompt on. Run `sudo -A <command>`: `-A` makes it ask the helper in `$SUDO_ASKPASS`, so expect a key touch per command. Never `sudo -n`, which cannot prompt and always fails.
