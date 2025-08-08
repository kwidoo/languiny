// C header for engine functions used in Swift
#pragma once
#ifdef __cplusplus
extern "C" {
#endif

const char* RemapWord(const char* utf8, int fromLayout, int toLayout);
int ShouldSwitch(const char* utf8, int currentLayout);
const char* EngineVersion();
void FreeCString(const char* ptr);

#ifdef __cplusplus
}
#endif
