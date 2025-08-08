# Layouts

Target pair: en_US <-> ru_RU

Approach:

- Use key-to-char tables for both directions
- Word boundary: whitespace, punctuation, Enter
- Early rules: min word length = 3, ignore URLs/emails patterns

## Mapping rules

- Tables include letters plus punctuation keys that produce letters on the opposite layout.
- Digits and punctuation that coincide in both layouts stay unchanged.
- Transformations preserve the case of each character.
- Characters not present in the table are returned as-is.
