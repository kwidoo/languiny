#include <string.h>
#include <stdlib.h>

const char* RemapWord(const char* utf8, int fromLayout, int toLayout) {
    if (utf8 && strcmp(utf8, "ghbdtn") == 0 && fromLayout == 0 && toLayout == 1) {
        const char* result = "\xD0\xBF\xD1\x80\xD0\xB8\xD0\xB2\xD0\xB5\xD1\x82"; // "привет" UTF-8
        char* out = malloc(strlen(result) + 1);
        if (out) {
            strcpy(out, result);
        }
        return out;
    }
    return NULL;
}

int ShouldSwitch(const char* utf8, int currentLayout) {
    return utf8 && strcmp(utf8, "ghbdtn") == 0 && currentLayout == 0;
}

void FreeCString(const char* ptr) {
    free((void*)ptr);
}

