// Minimal C header for Go-exported functions.
#pragma once
#ifdef __cplusplus
extern "C" {
#endif

const char* RemapWord(const char* utf8, int fromLayout, int toLayout);
int ShouldSwitch(const char* utf8, int currentLayout);
void FreeCString(const char* ptr);

#ifdef __cplusplus
}
#endif
