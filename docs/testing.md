# Integration Test Checklist

Manual QA matrix to verify Languiny across common macOS apps.

## Environment

- Apple Silicon Mac
- macOS 15.5

## Apps

- TextEdit
- Notes
- Safari
- Mail
- VS Code
- Xcode

## Scenarios

For each app, verify:

- [ ] Plain typing
- [ ] Backspace and editing
- [ ] App switching while typing
- [ ] Long words (50+ characters)
- [ ] Punctuation handling
- [ ] URLs and email addresses

## Matrix

Record pass/fail and notes for each scenario:

| App     | Plain | Edit | Switch | Long | Punct | URL/Email | Notes |
|---------|-------|------|--------|------|-------|-----------|-------|
| TextEdit| [ ]   | [ ]  | [ ]    | [ ]  | [ ]   | [ ]       |       |
| Notes   | [ ]   | [ ]  | [ ]    | [ ]  | [ ]   | [ ]       |       |
| Safari  | [ ]   | [ ]  | [ ]    | [ ]  | [ ]   | [ ]       |       |
| Mail    | [ ]   | [ ]  | [ ]    | [ ]  | [ ]   | [ ]       |       |
| VS Code | [ ]   | [ ]  | [ ]    | [ ]  | [ ]   | [ ]       |       |
| Xcode   | [ ]   | [ ]  | [ ]    | [ ]  | [ ]   | [ ]       |       |

## Logging and Timing

- Use `log stream --process Languiny` to capture engine decisions.
- Measure switching latency with `time` around the app build and run cycle.

## Known Exceptions

Document any apps that block synthetic events or require special configuration (e.g., enabling the blacklist in IDEs).

