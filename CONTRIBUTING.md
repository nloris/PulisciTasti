# Contributing

Keep PulisciTasti small, local, and predictable. The keyboard lock must never depend on network access, accounts, payments, or analytics.

Run `zsh build.sh` before proposing a change. It produces a universal app and runs the filter/session self-tests. Never run a real keyboard-interception test unattended in CI.

For changes to event handling, manually verify with Accessibility enabled:

- Ordinary keys and shortcuts cannot reach other apps while locked.
- Mouse movement, scrolling, dragging, and clicking the close button still work.
- Timer completion restores input and returning to the app does not restart the lock.
- Closing the app restores typing; reopening starts a new session.
- Permission denial/revocation and Secure Input do not show a false locked state.
- Media keys and sleep/wake behavior on the hardware you have available.

For UI changes, use `--preview` with no other instance running and inspect both light and dark appearance. Demo mode must always be visibly identified and must never install an event tap.

Report macOS version, CPU architecture, keyboard model, and reproduction steps. Do not include passwords, private documents, or recordings of sensitive input.
