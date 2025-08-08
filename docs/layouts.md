# Layouts

Target pair: en_US <-> ru_RU

Approach:

- Use key-to-char tables for both directions
- Word boundary: whitespace, punctuation, Enter
- Early rules: min word length = 3, ignore URLs/emails patterns
