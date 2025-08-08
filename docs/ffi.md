# FFI (C ABI) between Swift and Go

Functions:

- const char* RemapWord(const char* utf8, int fromLayout, int toLayout);
- int ShouldSwitch(const char\* utf8, int currentLayout);
- void FreeCString(const char\* ptr);

Notes:

- Strings are UTF-8, null-terminated.
- Memory ownership: Go returns C.CString-allocated memory; Swift must call FreeCString.
- Errors: RemapWord returns NULL on error; ShouldSwitch returns negative values on error (>=0 are boolean as 0/1).
